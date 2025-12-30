import 'dart:async';
import 'dart:isolate';
import '../models/timer.dart';
import '../services/database_helper.dart';
import '../services/hardware_service.dart';
import '../services/astral_service.dart';

/// TimerManager handles all timer-related operations in a separate isolate.
/// This ensures timers continue to function properly even when the UI is busy.
class TimerManager {
  static TimerManager? _instance;
  static TimerManager get instance => _instance ??= TimerManager._internal();

  TimerManager._internal();

  // Isolate communication
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  final StreamController<TimerEvent> _eventStreamController =
      StreamController<TimerEvent>.broadcast();

  // Services
  final DatabaseHelper _db = DatabaseHelper();

  // State
  bool _isRunning = false;

  // Public event stream
  Stream<TimerEvent> get eventStream => _eventStreamController.stream;

  /// Initialize the timer manager
  Future<void> initialize() async {
    if (_isRunning) return;

    _receivePort = ReceivePort();

    // Start the isolate
    _isolate = await Isolate.spawn(_isolateEntry, _receivePort!.sendPort);

    // Listen for messages from the isolate
    _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        _sendMessage(TimerCommand.initialize());
      } else if (message is TimerEvent) {
        _handleEvent(message);
      }
    });

    _isRunning = true;
  }

  /// Dispose the timer manager
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;
    _eventStreamController.close();
    _isRunning = false;
  }

  /// Add a new timer
  Future<int> addTimer(WateringTimer timer) async {
    final id = await _db.createWateringTimer(timer);

    // Notify isolate of the new timer
    _sendMessage(TimerCommand.refresh());

    return id;
  }

  /// Update an existing timer
  Future<void> updateTimer(WateringTimer timer) async {
    await _db.updateWateringTimer(timer);

    // Notify isolate of the updated timer
    _sendMessage(TimerCommand.refresh());
  }

  /// Delete a timer
  Future<void> deleteTimer(int timerId) async {
    await _db.deleteWateringTimer(timerId);

    // Notify isolate of the deleted timer
    _sendMessage(TimerCommand.refresh());
  }

  /// Manually activate a zone
  Future<void> manualActivate(int zoneId, int durationSeconds) async {
    _sendMessage(TimerCommand.manualActivate(zoneId, durationSeconds));
  }

  /// Manually deactivate a zone
  Future<void> manualDeactivate(int zoneId) async {
    _sendMessage(TimerCommand.manualDeactivate(zoneId));
  }

  /// Get active zones
  Future<List<int>> getActiveZones() async {
    final completer = Completer<List<int>>();

    // Create a temporary subscription to get the response
    late StreamSubscription subscription;
    subscription = eventStream.listen((event) {
      if (event.type == TimerEventType.activeZones) {
        completer.complete(event.data as List<int>);
        subscription.cancel();
      }
    });

    // Send the request
    _sendMessage(TimerCommand.getActiveZones());

    // Wait for the response with a timeout
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => [],
    );
  }

  /// Send a message to the isolate
  void _sendMessage(TimerCommand command) {
    _sendPort?.send(command);
  }

  /// Handle an event from the isolate
  void _handleEvent(TimerEvent event) {
    // Forward the event to the stream
    _eventStreamController.add(event);

    // Handle specific events
    switch (event.type) {
      case TimerEventType.timerActivated:
        final data = event.data as Map<String, dynamic>;
        final timerId = data['timer_id'] as int;
        final startTime = data['start_time'] as int;

        // Log the timer execution in the database
        _db.logTimerExecution(timerId, startTime);
        break;

      case TimerEventType.timerCompleted:
        final data = event.data as Map<String, dynamic>;
        final timerId = data['timer_id'] as int;
        final success = data['success'] as bool;
        final endTime = data['end_time'] as int;

        // Update the timer execution in the database
        _db.logTimerExecution(
          timerId,
          data['start_time'] as int,
          endTime: endTime,
          success: success,
        );
        break;

      default:
        // No special handling for other event types
        break;
    }
  }

  /// Static entry point for the isolate
  static void _isolateEntry(SendPort sendPort) {
    // Set up communication
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    // Create the timer manager instance for the isolate
    final manager = _IsolateTimerManager(sendPort);

    // Listen for commands
    receivePort.listen((message) {
      if (message is TimerCommand) {
        manager.handleCommand(message);
      }
    });
  }
}

/// Timer manager implementation that runs in the isolate
class _IsolateTimerManager {
  final SendPort _sendPort;

  // Services
  final DatabaseHelper _db = DatabaseHelper();
  final HardwareService _hardware = HardwareService.instance;
  final AstralService _astral = AstralService.instance;

  // State
  // State
  final List<_ActiveTimer> _activeTimers = [];
  final List<int> _activeZones = [];
  Timer? _checkTimer;

  // Create a new isolate timer manager
  _IsolateTimerManager(this._sendPort);

  /// Handle a command from the main isolate
  void handleCommand(TimerCommand command) {
    switch (command.type) {
      case TimerCommandType.initialize:
        _initialize();
        break;

      case TimerCommandType.refresh:
        _refreshTimers();
        break;

      case TimerCommandType.manualActivate:
        _manualActivate(
          command.data['zone_id'] as int,
          command.data['duration'] as int,
        );
        break;

      case TimerCommandType.manualDeactivate:
        _manualDeactivate(command.data['zone_id'] as int);
        break;

      case TimerCommandType.getActiveZones:
        _sendActiveZones();
        break;
    }
  }

  /// Initialize the timer manager
  Future<void> _initialize() async {
    // Set up the periodic timer to check for due timers
    _checkTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) => _checkTimers(),
    );

    // Load active timers
    await _refreshTimers();

    // Send an initialization event
    _sendEvent(TimerEvent.initialized());
  }

  void dispose() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Refresh timers from the database
  Future<void> _refreshTimers() async {
    try {
      // Load all active timers
      final timers = await _db.getAllActiveTimers();

      // Calculate next execution for each timer
      for (var timer in timers) {
        final nextRun = _calculateNextExecution(timer);
        if (nextRun != timer.nextRun) {
          await _db.updateTimerNextRun(timer.id, nextRun);
          timer = timer.copyWith(nextRun: nextRun);
        }
      }

      // Update the active timers list
      _activeTimers.clear();
      for (var timer in timers) {
        _activeTimers.add(_ActiveTimer(timer: timer));
      }

      // Send a refresh event
      _sendEvent(TimerEvent.timersRefreshed(timers.length));
    } catch (e) {
      _sendEvent(TimerEvent.error('Failed to refresh timers: $e'));
    }
  }

  /// Calculate the next execution time for a timer
  int _calculateNextExecution(WateringTimer timer) {
    final now = DateTime.now();
    late DateTime nextRun;

    switch (timer.type) {
      case 'interval':
        // If there's a last run, calculate from that
        if (timer.lastRun != null) {
          final lastRunTime = DateTime.fromMillisecondsSinceEpoch(
            timer.lastRun! * 1000,
          );
          nextRun = lastRunTime.add(Duration(hours: timer.intervalHours ?? 24));

          // If the calculated time is in the past, calculate from now
          if (nextRun.isBefore(now)) {
            nextRun = now.add(Duration(hours: timer.intervalHours ?? 24));
          }
        } else {
          // No last run, calculate from now
          nextRun = now.add(Duration(hours: timer.intervalHours ?? 24));
        }
        break;

      case 'sunrise':
      case 'sunset':
        try {
          // Get today's astral event
          final today = DateTime(now.year, now.month, now.day);
          final astralEventFuture = timer.type == 'sunrise'
              ? _astral.getSunriseForDate(today)
              : _astral.getSunsetForDate(today);

          // Wait for the future to complete
          astralEventFuture.then((astralEvent) {
            // Apply offset
            nextRun = astralEvent.add(
              Duration(minutes: timer.offsetMinutes ?? 0),
            );

            // If the time is in the past, get tomorrow's event
            if (nextRun.isBefore(now)) {
              final tomorrow = today.add(const Duration(days: 1));
              final tomorrowEventFuture = timer.type == 'sunrise'
                  ? _astral.getSunriseForDate(tomorrow)
                  : _astral.getSunsetForDate(tomorrow);

              tomorrowEventFuture.then((tomorrowEvent) {
                nextRun = tomorrowEvent.add(
                  Duration(minutes: timer.offsetMinutes ?? 0),
                );
              });
            }
          });
        } catch (e) {
          // If astral calculation fails, fall back to interval
          _sendEvent(TimerEvent.error('Failed to calculate astral time: $e'));
          nextRun = now.add(const Duration(hours: 24));
        }
        break;

      case 'time':
        if (timer.startTime != null) {
          // Parse the time
          final timeParts = timer.startTime!.split(':');
          if (timeParts.length == 2) {
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final minute = int.tryParse(timeParts[1]) ?? 0;

            // Create the next run time for today
            nextRun = DateTime(now.year, now.month, now.day, hour, minute);

            // If the time is in the past, use tomorrow
            if (nextRun.isBefore(now)) {
              nextRun = nextRun.add(const Duration(days: 1));
            }

            // Check if the day of week is allowed
            if (timer.daysOfWeek != null && timer.daysOfWeek!.isNotEmpty) {
              final allowedDays = timer.daysOfWeek!
                  .split(',')
                  .map((day) => int.tryParse(day))
                  .where((day) => day != null)
                  .map((day) => day!)
                  .toList();

              // Find the next allowed day
              while (!allowedDays.contains(nextRun.weekday)) {
                nextRun = nextRun.add(const Duration(days: 1));
              }
            }
          } else {
            // Invalid time format, fall back to interval
            _sendEvent(
              TimerEvent.error('Invalid time format: ${timer.startTime}'),
            );
            nextRun = now.add(const Duration(hours: 24));
          }
        } else {
          // No start time, fall back to interval
          _sendEvent(TimerEvent.error('No start time for timer ${timer.id}'));
          nextRun = now.add(const Duration(hours: 24));
        }
        break;

      default:
        // Unknown timer type, fall back to interval
        _sendEvent(TimerEvent.error('Unknown timer type: ${timer.type}'));
        nextRun = now.add(const Duration(hours: 24));
        break;
    }

    return nextRun.millisecondsSinceEpoch ~/ 1000;
  }

  /// Check for due timers and execute them
  Future<void> _checkTimers() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Find timers that are due
    final dueTimers = _activeTimers
        .where(
          (activeTimer) =>
              !activeTimer.isRunning &&
              activeTimer.timer.nextRun != null &&
              activeTimer.timer.nextRun! <= now,
        )
        .toList();

    // Execute each due timer
    for (var activeTimer in dueTimers) {
      await _executeTimer(activeTimer);
    }
  }

  /// Execute a timer
  Future<void> _executeTimer(_ActiveTimer activeTimer) async {
    final timer = activeTimer.timer;
    final startTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Check if the zone is already active
    if (_activeZones.contains(timer.zoneId)) {
      _sendEvent(TimerEvent.error('Zone ${timer.zoneId} is already active'));
      return;
    }

    try {
      // Mark the timer as running
      activeTimer.isRunning = true;
      _activeZones.add(timer.zoneId);

      // Send activation event
      _sendEvent(
        TimerEvent.timerActivated(
          timer.id,
          timer.zoneId,
          startTime,
          timer.durationSeconds,
        ),
      );

      // Activate the zone
      await _hardware.activateZone(timer.zoneId);

      // Wait for the duration
      await Future.delayed(Duration(seconds: timer.durationSeconds));

      // Deactivate the zone
      await _hardware.deactivateZone(timer.zoneId);

      // Calculate next execution time
      final nextRun = _calculateNextExecution(timer);
      await _db.updateTimerNextRun(timer.id, nextRun);

      // Update the timer in the active timers list
      activeTimer.timer = timer.copyWith(lastRun: startTime, nextRun: nextRun);

      // Send completion event
      _sendEvent(
        TimerEvent.timerCompleted(
          timer.id,
          startTime,
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          true,
        ),
      );
    } catch (e) {
      // Handle errors
      _sendEvent(TimerEvent.error('Failed to execute timer ${timer.id}: $e'));

      // Try to deactivate the zone
      try {
        await _hardware.deactivateZone(timer.zoneId);
      } catch (e2) {
        _sendEvent(
          TimerEvent.error('Failed to deactivate zone ${timer.zoneId}: $e2'),
        );
      }

      // Send completion event with failure
      _sendEvent(
        TimerEvent.timerCompleted(
          timer.id,
          startTime,
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          false,
          'Error: $e',
        ),
      );
    } finally {
      // Mark the timer as not running
      activeTimer.isRunning = false;
      _activeZones.remove(timer.zoneId);
    }
  }

  /// Manually activate a zone
  Future<void> _manualActivate(int zoneId, int durationSeconds) async {
    // Check if the zone is already active
    if (_activeZones.contains(zoneId)) {
      _sendEvent(TimerEvent.error('Zone $zoneId is already active'));
      return;
    }

    try {
      // Mark the zone as active
      _activeZones.add(zoneId);

      // Send activation event
      _sendEvent(TimerEvent.manualActivated(zoneId, durationSeconds));

      // Activate the zone
      await _hardware.activateZone(zoneId);

      // If duration is > 0, schedule deactivation
      if (durationSeconds > 0) {
        // Wait for the duration
        await Future.delayed(Duration(seconds: durationSeconds));

        // Deactivate the zone if it's still active
        if (_activeZones.contains(zoneId)) {
          await _hardware.deactivateZone(zoneId);
          _activeZones.remove(zoneId);

          // Send deactivation event
          _sendEvent(TimerEvent.manualDeactivated(zoneId));
        }
      }
    } catch (e) {
      // Handle errors
      _sendEvent(
        TimerEvent.error('Failed to manually activate zone $zoneId: $e'),
      );

      // Try to deactivate the zone
      try {
        if (_activeZones.contains(zoneId)) {
          await _hardware.deactivateZone(zoneId);
          _activeZones.remove(zoneId);
        }
      } catch (e2) {
        _sendEvent(TimerEvent.error('Failed to deactivate zone $zoneId: $e2'));
      }
    }
  }

  /// Manually deactivate a zone
  Future<void> _manualDeactivate(int zoneId) async {
    // Check if the zone is active
    if (!_activeZones.contains(zoneId)) {
      _sendEvent(TimerEvent.error('Zone $zoneId is not active'));
      return;
    }

    try {
      // Deactivate the zone
      await _hardware.deactivateZone(zoneId);
      _activeZones.remove(zoneId);

      // Send deactivation event
      _sendEvent(TimerEvent.manualDeactivated(zoneId));
    } catch (e) {
      _sendEvent(
        TimerEvent.error('Failed to manually deactivate zone $zoneId: $e'),
      );
    }
  }

  /// Send the list of active zones
  void _sendActiveZones() {
    _sendEvent(TimerEvent.activeZones(List<int>.from(_activeZones)));
  }

  /// Send an event to the main isolate
  void _sendEvent(TimerEvent event) {
    _sendPort.send(event);
  }
}

/// Active timer class for tracking running timers
class _ActiveTimer {
  WateringTimer timer;
  bool isRunning;

  _ActiveTimer({required this.timer})
    : isRunning = false; // Move the default value to initializer list
}

/// Timer command types
enum TimerCommandType {
  initialize,
  refresh,
  manualActivate,
  manualDeactivate,
  getActiveZones,
}

/// Timer event types
enum TimerEventType {
  initialized,
  timersRefreshed,
  timerActivated,
  timerCompleted,
  manualActivated,
  manualDeactivated,
  activeZones,
  error,
}

/// Timer command class for sending commands to the isolate
class TimerCommand {
  final TimerCommandType type;
  final Map<String, dynamic> data;

  TimerCommand({required this.type, this.data = const {}});

  factory TimerCommand.initialize() {
    return TimerCommand(type: TimerCommandType.initialize);
  }

  factory TimerCommand.refresh() {
    return TimerCommand(type: TimerCommandType.refresh);
  }

  factory TimerCommand.manualActivate(int zoneId, int duration) {
    return TimerCommand(
      type: TimerCommandType.manualActivate,
      data: {'zone_id': zoneId, 'duration': duration},
    );
  }

  factory TimerCommand.manualDeactivate(int zoneId) {
    return TimerCommand(
      type: TimerCommandType.manualDeactivate,
      data: {'zone_id': zoneId},
    );
  }

  factory TimerCommand.getActiveZones() {
    return TimerCommand(type: TimerCommandType.getActiveZones);
  }
}

/// Timer event class for sending events from the isolate
class TimerEvent {
  final TimerEventType type;
  final dynamic data;

  TimerEvent({required this.type, this.data});

  factory TimerEvent.initialized() {
    return TimerEvent(type: TimerEventType.initialized);
  }

  factory TimerEvent.timersRefreshed(int count) {
    return TimerEvent(type: TimerEventType.timersRefreshed, data: count);
  }

  factory TimerEvent.timerActivated(
    int timerId,
    int zoneId,
    int startTime,
    int duration,
  ) {
    return TimerEvent(
      type: TimerEventType.timerActivated,
      data: {
        'timer_id': timerId,
        'zone_id': zoneId,
        'start_time': startTime,
        'duration': duration,
      },
    );
  }

  factory TimerEvent.timerCompleted(
    int timerId,
    int startTime,
    int endTime,
    bool success, [
    String? notes,
  ]) {
    return TimerEvent(
      type: TimerEventType.timerCompleted,
      data: {
        'timer_id': timerId,
        'start_time': startTime,
        'end_time': endTime,
        'success': success,
        'notes': notes,
      },
    );
  }

  factory TimerEvent.manualActivated(int zoneId, int duration) {
    return TimerEvent(
      type: TimerEventType.manualActivated,
      data: {'zone_id': zoneId, 'duration': duration},
    );
  }

  factory TimerEvent.manualDeactivated(int zoneId) {
    return TimerEvent(type: TimerEventType.manualDeactivated, data: zoneId);
  }

  factory TimerEvent.activeZones(List<int> zoneIds) {
    return TimerEvent(type: TimerEventType.activeZones, data: zoneIds);
  }

  factory TimerEvent.error(String message) {
    return TimerEvent(type: TimerEventType.error, data: message);
  }
}
