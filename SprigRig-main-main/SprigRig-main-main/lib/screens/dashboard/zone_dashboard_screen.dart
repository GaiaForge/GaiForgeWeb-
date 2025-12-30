import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../models/sensor.dart';
import '../../models/astral_simulation_settings.dart';
import '../../services/astral_simulation_service.dart';
import '../../services/database_helper.dart';
import '../../services/env_control_service.dart';
import '../../widgets/common/app_background.dart';
import '../setup/irrigation_screen.dart';
import '../setup/lighting_screen.dart';
import '../setup/sensing_screen.dart';
import '../setup/hvac_screen.dart';
import '../setup/aeration_screen.dart';
import '../setup/zone_configuration_screen.dart';
import '../crops/crop_management_screen.dart';
import 'analytics_screen.dart';
import '../../widgets/gaia_sensor_eye.dart';
import '../../widgets/animated_status_icons.dart';
import '../../services/camera_service.dart';
import 'camera_grid_screen.dart';
import '../../widgets/cards/camera/camera_detail_screen.dart';
import '../camera/timelapse_viewer_screen.dart';
import '../../models/camera.dart';
import '../../models/camera.dart';
import '../../models/lighting_schedule.dart';
import '../../models/irrigation_schedule.dart';
import 'package:intl/intl.dart';
import '../../widgets/dashboard/dashboard_control_tile.dart';
import '../../widgets/dashboard/animated_progress_bar.dart';
import '../../widgets/dashboard/status_toggle.dart';
import '../../widgets/dashboard/cycle_progress_dots.dart';
import '../../widgets/cards/seedling_mat/seedling_mat_tile.dart';
import '../setup/seedling_mat_screen.dart';
import '../../models/fertigation_config.dart';
import '../setup/fertigation_setup_screen.dart';
import '../../models/guardian_config.dart';
import '../setup/guardian_setup_screen.dart';
import '../../widgets/dialogs/sensor_setpoint_dialog.dart';
import '../../widgets/tiles/guardian_tile.dart';
import '../guardian/guardian_screen.dart';

class ZoneDashboardScreen extends StatefulWidget {
  final Zone zone;

  const ZoneDashboardScreen({super.key, required this.zone});

  @override
  State<ZoneDashboardScreen> createState() => _ZoneDashboardScreenState();
}

class _ZoneDashboardScreenState extends State<ZoneDashboardScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Sensor> _sensors = [];
  Map<String, dynamic> _systemStatus = {
    'lighting': {'active': false, 'mode': 'Off'},
    'irrigation': {'active': false, 'scheduleCount': 0, 'mode': 'Scheduled', 'isHydro': false},
    'hvac': {'active': false, 'mode': 'Off'},
    'aeration': {'active': false, 'mode': 'Scheduled', 'scheduleCount': 0},
  };
  
  // Astral State
  AstralSimulationSettings? _astralSettings;
  SunTimes? _todaySunTimes;
  
  // Data for rich tiles
  List<LightingSchedule> _lightingSchedules = [];
  Map<String, dynamic>? _lightingSettings;
  List<IrrigationSchedule> _irrigationSchedules = [];
  Map<String, dynamic>? _irrigationSettings;
  Map<String, dynamic>? _hvacSettings;
  List<Map<String, dynamic>> _aerationSchedules = [];
  Map<String, dynamic>? _aerationSettings;
  Map<int, Map<String, dynamic>> _sensorReadings = {};
  List<Camera> _cameras = []; // Added to track camera status
  Map<String, dynamic>? _seedlingMatSettings;
  FertigationConfig? _fertigationConfig;
  GuardianConfig? _guardianConfig;
  
  // Camera Stats
  int _totalPhotos = 0;
  String _storageUsed = '0 MB';

  bool _isReordering = false;
  bool _isLoading = true;
  bool _hasCameras = false;
  
  // Placeholder for sensor readings
  // Map<int, Map<String, dynamic>> _sensorReadings = {}; // Removed duplicate
  
  // Active Crop Info
  Map<String, dynamic>? _activeCrop;
  Map<String, dynamic>? _activeTemplate;
  Map<String, dynamic>? _currentPhase;

  // Stream subscription
  StreamSubscription? _statusSubscription;
  late Timer _clockTimer;
  String _currentTime = '';
  String _currentDate = '';
  
  late Zone _zone;

  @override
  void initState() {
    super.initState();
    _zone = widget.zone;
    _loadDashboardData();
    _setupStatusListener();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm').format(now);
        _currentDate = DateFormat('EEE, MMM d').format(now);
      });
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _clockTimer.cancel();
    super.dispose();
  }

  void _setupStatusListener() {
    // Listen to real-time control updates
    _statusSubscription = EnvironmentalControlService.instance.activeControlsStream.listen((activeControls) {
      if (!mounted) return;
      
      setState(() {
        // Update system status based on active controls
        // This is a simplified mapping - in a real app we'd map specific controls to categories
        // For now, we'll assume if any control of a type is active, the category is active
        
        // We need to know which controls belong to which category
        // This would require fetching control types or storing them locally
        // For this MVP, we'll rely on the initial load for mapping and just trigger a UI refresh
        // effectively, but ideally we'd update specific flags.
        
        // Since we don't have the control-to-type mapping readily available in the stream,
        // we'll trigger a reload of the dashboard data which fetches everything.
        // A more optimized approach would be to cache the control map.
        _loadDashboardData();
      });
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Reload zone data to get latest flags
      final updatedZone = await _db.getZone(widget.zone.id!);
      
      // Load sensors
      final sensors = await _db.getZoneSensors(widget.zone.id!);
      
      // Check for cameras
      final cameras = await _db.getZoneCameras(widget.zone.id!);
      final hasCameras = cameras.isNotEmpty;
      
      // Simulate sensor readings for display
      final Map<int, Map<String, dynamic>> simulatedReadings = {};
      for (var sensor in sensors) {
        simulatedReadings[sensor.id!] = _getSimulatedReadingsForSensor(sensor.sensorType);
      }

      // Load lighting status
      final lightingSettings = await _db.getLightingSettings(widget.zone.id);
      final lightingSchedules = await _db.getLightingSchedules(widget.zone.id);
      
      // Load irrigation status
      final irrigationSchedules = await _db.getIrrigationSchedules(widget.zone.id);
      final irrigationSettings = await _db.getIrrigationSettings(widget.zone.id);
      
      // Load HVAC status
      final hvacSettings = await _db.getHvacSettings(widget.zone.id);

      // Load aeration status
      final aerationSchedules = await _db.getAerationSchedules(widget.zone.id!);
      final aerationSettings = await _db.getAerationSettings(widget.zone.id!);
      
      // Load cameras
      final cameraAssignments = await _db.getZoneCameras(widget.zone.id!);
      final loadedCameras = <Camera>[];
      int totalPhotos = 0;
      String storageUsed = '0 MB';
      
      for (final assignment in cameraAssignments) {
        final camera = await _db.getCamera(assignment.cameraId);
        if (camera != null) {
          loadedCameras.add(camera);
          // Fetch stats
          try {
            final stats = await CameraService.instance.getCameraStats(camera.id!, widget.zone.id!);
            totalPhotos += (stats['count'] as int? ?? 0);
            // Storage is a string like "100 MB", hard to sum without parsing. 
            // For now just use the first camera's storage or "N/A" if multiple?
            // Or just show stats for the first active camera.
            if (storageUsed == '0 MB') {
               storageUsed = stats['storageUsed'] as String? ?? '0 MB';
            }
          } catch (e) {
            debugPrint('Error fetching camera stats: $e');
          }
        }
      }

      // Load seedling mat settings
      Map<String, dynamic>? seedlingMatSettings;
      try {
        seedlingMatSettings = await _db.getSeedlingMatSettings(widget.zone.id!);
      } catch (e) {
        debugPrint('Error loading seedling mat settings: $e');
      }
      
      // Load fertigation config
      final fertigationConfig = await _db.getFertigationConfig(widget.zone.id!);

      // Load guardian config
      final guardianConfig = await _db.getGuardianConfig(widget.zone.id!);

      // Load astral settings
      final astralSettings = await _db.getAstralSimulationSettings(widget.zone.id!);
      SunTimes? sunTimes;
      if (astralSettings != null && astralSettings.enabled) {
        final service = AstralSimulationService.instance;
        final simDate = service.getCurrentSimulatedDate(astralSettings);
        sunTimes = service.calculateSunTimes(astralSettings.latitude, astralSettings.longitude, simDate);
      }
      
      // Load active crop
      final crop = await _db.getZoneCrop(widget.zone.id!);
      Map<String, dynamic>? template;
      Map<String, dynamic>? phase;
      
      if (crop != null) {
        if (crop['template_id'] != null) {
          template = await _db.getRecipeTemplateById(crop['template_id']);
        }
        if (crop['current_phase_id'] != null) {
          phase = await _db.getPhaseById(crop['current_phase_id']);
        }
      }
      
      if (mounted) {
        setState(() {
          if (updatedZone != null) _zone = updatedZone;
          _sensors = sensors;
          _hasCameras = hasCameras;
          _sensorReadings = simulatedReadings;
          _activeCrop = crop;
          _activeTemplate = template;
          _currentPhase = phase;
          
          _lightingSchedules = lightingSchedules;
          _lightingSettings = lightingSettings;
          _irrigationSchedules = irrigationSchedules;
          _irrigationSettings = irrigationSettings;
          _hvacSettings = hvacSettings;
          _aerationSchedules = aerationSchedules;
          _aerationSettings = aerationSettings;
          _cameras = loadedCameras; // Corrected variable name
          _seedlingMatSettings = seedlingMatSettings;
          _fertigationConfig = fertigationConfig;
          _guardianConfig = guardianConfig;
          _totalPhotos = totalPhotos;
          _storageUsed = storageUsed;
          
          // Lighting status
          if (lightingSettings != null) {
            _systemStatus['lighting'] = {
              'active': lightingSchedules.isNotEmpty || lightingSettings['mode'] == 'Astral',
              'mode': lightingSettings['mode'] ?? 'Off',
            };
          }
          
          // Irrigation status
          bool isHydro = false;
          String irrMode = 'Scheduled';
          if (irrigationSettings != null) {
            if (irrigationSettings['mode'] == 'Reservoir' || irrigationSettings['upper_float_sensor_id'] != null) {
              isHydro = true;
              irrMode = 'Autofill';
              
              // Auto-correct grow method if needed
              if (widget.zone.growMethod == 'soil') {
                _db.updateZone(
                  widget.zone.id,
                  widget.zone.name,
                  widget.zone.enabled ? 1 : 0,
                  growMethod: 'hydroponic',
                ).then((_) {
                  debugPrint('Auto-corrected zone grow method to hydroponic');
                });
              }
            }
          }
          
          _systemStatus['irrigation'] = {
            'active': irrigationSchedules.isNotEmpty || isHydro,
            'scheduleCount': irrigationSchedules.length,
            'mode': irrMode,
            'isHydro': isHydro,
          };
          
          // HVAC status
          if (hvacSettings != null) {
            _systemStatus['hvac'] = {
              'active': true,
              'mode': hvacSettings['control_mode'] ?? 'Off',
            };
          }

          // Aeration status
          bool aerationActive = aerationSchedules.isNotEmpty;
          String aerationMode = 'Scheduled';
          if (aerationSettings != null) {
            if (aerationSettings['always_on_enabled'] == 1) {
              aerationActive = true;
              aerationMode = 'Always On';
            }
          }
          _systemStatus['aeration'] = {
            'active': aerationActive,
            'mode': aerationMode,
            'scheduleCount': aerationSchedules.length,
          };
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading dashboard data: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int? _calculateDaysRemaining(Map<String, dynamic>? settings) {
    if (settings == null) return null;
    if (settings['auto_off_enabled'] != 1) return null;
    
    final createdAt = settings['created_at'] as int?;
    final autoOffDays = settings['auto_off_days'] as int? ?? 14;
    
    if (createdAt == null) return null;
    
    final startDate = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    final endDate = startDate.add(Duration(days: autoOffDays));
    final remaining = endDate.difference(DateTime.now()).inDays;
    
    return remaining > 0 ? remaining : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.grid_view_rounded),
          tooltip: 'Back to Zones',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _currentTime,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _currentDate,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            Text(
              widget.zone.name.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Zone Management',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ZoneConfigurationScreen(zone: _zone)),
              ).then((_) => _loadDashboardData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalyticsScreen(zone: widget.zone),
                ),
              );
            },
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Environmental Sensors Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.white54),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SensingScreen(zone: widget.zone)),
                              ).then((_) => _loadDashboardData()),
                              tooltip: 'Add Sensor',
                            ),
                            IconButton(
                              icon: Icon(
                                _isReordering ? Icons.check : Icons.sort,
                                color: _isReordering ? Colors.green : Colors.white54,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isReordering = !_isReordering;
                                });
                              },
                              tooltip: _isReordering ? 'Finish Reordering' : 'Reorder Sensors',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Guardian Tile
                        if (_zone.hasGuardian) ...[
                          GuardianTile(
                            zoneId: _zone.id!,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GuardianScreen(zoneId: widget.zone.id!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        _buildSensorsGrid(),
                        
                        const SizedBox(height: 24),

                        // Active Crop Section
                        if (_activeCrop != null)
                          _buildActiveCropCard(),

                        // System Status Section (Only visible if no active crop)
                        if (_activeCrop == null) ...[

                          _buildSystemStatusGrid(),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Quick Actions
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemStatusGrid() {
    List<Widget> tiles = [];

    // --- LIGHTING TILE ---
    if (widget.zone.hasLighting) {
      final status = _systemStatus['lighting'] ?? {'active': false, 'mode': 'Off'};
      final isActive = status['active'] == true;
      final mode = status['mode'] ?? 'Off';
      
      // Calculate real-time progress and status
      double progress = 0.0;
      String timeText = '--';
      String subText = 'No Schedule';
      
      if (_lightingSchedules.isNotEmpty) {
        final now = DateTime.now();
        final nowMinutes = now.hour * 60 + now.minute;
        
        LightingSchedule? activeSchedule;
        LightingSchedule? nextSchedule;
        int minMinutesToNext = 24 * 60 * 8; // Max possible + buffer
        
        for (var schedule in _lightingSchedules) {
          if (!schedule.isEnabled) continue;
          
          final startMinutes = schedule.startTime.hour * 60 + schedule.startTime.minute;
          final endMinutes = schedule.endTime.hour * 60 + schedule.endTime.minute;
          
          bool isCurrent = false;
          
          // Check if active
          if (startMinutes < endMinutes) {
            // Normal day schedule
            if (schedule.days[now.weekday - 1] && nowMinutes >= startMinutes && nowMinutes < endMinutes) {
              isCurrent = true;
            }
          } else {
            // Overnight schedule
            if (nowMinutes >= startMinutes) {
              // Late night part (must be enabled today)
              if (schedule.days[now.weekday - 1]) isCurrent = true;
            } else if (nowMinutes < endMinutes) {
              // Early morning part (must be enabled yesterday)
              final yesterday = now.subtract(const Duration(days: 1));
              if (schedule.days[yesterday.weekday - 1]) isCurrent = true;
            }
          }
          
          if (isCurrent) {
            activeSchedule = schedule;
            break; // Found the active one
          }
          
          // Find next schedule (simplified for now, looking for next start today or tomorrow)
          // This logic can be complex, for now let's find the closest start time in the future
          // ... (Logic for next schedule could be added here if needed for inactive state)
        }
        
        if (activeSchedule != null) {
          // ACTIVE STATE
          final startMinutes = activeSchedule.startTime.hour * 60 + activeSchedule.startTime.minute;
          final endMinutes = activeSchedule.endTime.hour * 60 + activeSchedule.endTime.minute;
          
          int totalDuration;
          int elapsed;
          
          if (startMinutes < endMinutes) {
            totalDuration = endMinutes - startMinutes;
            elapsed = nowMinutes - startMinutes;
          } else {
            // Overnight
            totalDuration = (24 * 60 - startMinutes) + endMinutes;
            if (nowMinutes >= startMinutes) {
              elapsed = nowMinutes - startMinutes;
            } else {
              elapsed = (24 * 60 - startMinutes) + nowMinutes;
            }
          }
          
          progress = (elapsed / totalDuration).clamp(0.0, 1.0);
          
          final remaining = totalDuration - elapsed;
          final h = remaining ~/ 60;
          final m = remaining % 60;
          timeText = 'Ends in ${h}h ${m}m';
          subText = '${activeSchedule.startTime.format(context)} - ${activeSchedule.endTime.format(context)}';
          
        } else {
          // INACTIVE STATE - Find next event
          // We need to find the next START time
          DateTime? nextStartTime;
          LightingSchedule? upcomingSchedule;
          
          for (var schedule in _lightingSchedules) {
            if (!schedule.isEnabled) continue;
            
            // Check next occurrence
            // Logic similar to IntervalSchedulerService but simplified for UI
            // Check today
            final todayStart = DateTime(now.year, now.month, now.day, schedule.startTime.hour, schedule.startTime.minute);
            DateTime check = todayStart;
            if (check.isBefore(now)) {
              check = check.add(const Duration(days: 1));
            }
            
            // Check up to 8 days
            for (int i = 0; i < 8; i++) {
              if (schedule.days[check.weekday - 1]) {
                 if (nextStartTime == null || check.isBefore(nextStartTime)) {
                   nextStartTime = check;
                   upcomingSchedule = schedule;
                 }
                 break;
              }
              check = check.add(const Duration(days: 1));
            }
          }
          
          if (nextStartTime != null && upcomingSchedule != null) {
             final diff = nextStartTime.difference(now);
             if (diff.inHours > 0) {
               timeText = 'Starts in ${diff.inHours}h ${diff.inMinutes % 60}m';
             } else {
               timeText = 'Starts in ${diff.inMinutes}m';
             }
             subText = '${upcomingSchedule.startTime.format(context)} - ${upcomingSchedule.endTime.format(context)}';
          }
        }
      }

      String lightingStatus = 'Off';
      String lightingSubStatus = 'Schedule';
      
      if (widget.zone.lightingMode == 'Astral' && _astralSettings != null && _todaySunTimes != null) {
        lightingStatus = 'Astral';
        lightingSubStatus = '${_astralSettings!.locationName} • ${_todaySunTimes!.dayLengthFormatted}';
      } else if (widget.zone.lightingMode == 'Manual') {
        lightingStatus = 'Manual';
        lightingSubStatus = 'User Controlled';
      }

      tiles.add(_buildTileWrapper(
        DashboardControlTile(
          title: 'Lighting',
          statusIcon: LightStatusIcon(isActive: isActive, color: Colors.amber, size: 24),
          isActive: isActive,
          activeColor: Colors.amber,
          onTap: () => _navigateTo(LightingScreen(zone: widget.zone)),
          statusText: lightingStatus == 'Astral' ? lightingSubStatus : '$lightingStatus • $lightingSubStatus',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedProgressBar(
                progress: progress,
                color: Colors.amber,
                label: 'Light cycle',
                timeRemaining: timeText,
              ),
              const SizedBox(height: 12),
              _InfoRow(label: 'Interval', value: subText, valueColor: Colors.white70),
              _InfoRow(label: 'Mode', value: mode, valueColor: Colors.amber),
              _InfoRow(label: 'Outputs', value: isActive ? 'On' : 'Off'),
            ],
          ),
        ),
      ));
    }

    // --- IRRIGATION TILE ---
    if (widget.zone.hasIrrigation) {
      final status = _systemStatus['irrigation'] ?? {'active': false, 'scheduleCount': 0, 'mode': 'Scheduled', 'isHydro': false};
      final isActive = status['active'] == true;
      final isHydro = status['isHydro'] == true;
      
      tiles.add(_buildTileWrapper(
        DashboardControlTile(
          title: 'Irrigation',
          statusIcon: IrrigationStatusIcon(isActive: isActive, color: Colors.blue, size: 24),
          isActive: isActive,
          activeColor: Colors.blue,
          // onToggle removed
          onTap: () => _navigateTo(IrrigationScreen(zone: widget.zone)),
          statusText: isHydro ? 'Autofill' : '${status['scheduleCount']} Schedules',
          content: Column(
            children: [
              _InfoRow(label: 'Last Watering', value: '2h 15m ago'), // Mocked
              _InfoRow(label: 'Next', value: _getNextEventText(_irrigationSchedules), valueColor: Colors.blue),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Today', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  CycleProgressDots(
                    completed: 2, // Mocked
                    total: math.max(1, _irrigationSchedules.length),
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
          actionButton: _TileActionButton(
            label: 'Run Now',
            color: Colors.blue,
            onPressed: () {
               // In a real app, show a dialog to select duration/zone
               _navigateTo(IrrigationScreen(zone: widget.zone));
            },
          ),
        ),
      ));
    }

    // --- HVAC TILE ---
    if (widget.zone.hasHvac) {
      final status = _systemStatus['hvac'] ?? {'active': false, 'mode': 'Off'};
      final isActive = status['active'] == true;
      
      tiles.add(_buildTileWrapper(
        DashboardControlTile(
          title: 'HVAC',
          statusIcon: FanStatusIcon(isActive: isActive, color: Colors.green, size: 24),
          isActive: isActive,
          activeColor: Colors.green,
          // onToggle removed
          onTap: () => _navigateTo(HvacScreen(zone: widget.zone)),
          statusText: status['mode'],
          content: Column(
            children: [
              _FanSpeedRow(name: 'Exhaust', speed: 80, isOn: true, color: Colors.green), // Mocked
              _FanSpeedRow(name: 'Intake', speed: 45, isOn: true, color: Colors.green),
              _FanSpeedRow(name: 'Circulation', speed: 0, isOn: false, color: Colors.green),
              Divider(color: Colors.white.withOpacity(0.1), height: 16),
              Row(
                children: [
                  Text('Auto Mode', style: TextStyle(color: Colors.green.shade300, fontSize: 10)),
                  const Spacer(),
                  Text('Triggered by Temp > 78°F', style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ));
    }

    // --- AERATION TILE ---
    if (widget.zone.hasAeration) {
      final status = _systemStatus['aeration'] ?? {'active': false, 'mode': 'Scheduled'};
      final isActive = status['active'] == true;
      
      tiles.add(_buildTileWrapper(
        DashboardControlTile(
          title: 'Aeration',
          statusIcon: AerationStatusIcon(isActive: isActive, color: Colors.cyan, size: 24),
          isActive: isActive,
          activeColor: Colors.cyan,
          // onToggle removed
          onTap: () => _navigateTo(AerationScreen(zone: widget.zone)),
          statusText: status['mode'],
          content: Column(
            children: [
              _InfoRow(label: 'Mode', value: status['mode'], valueColor: Colors.cyan),
              _InfoRow(label: 'Next Cycle', value: _getNextEventText(_aerationSchedules)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cycles', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  CycleProgressDots(
                    completed: 1,
                    total: math.max(1, _aerationSchedules.length),
                    activeColor: Colors.cyan,
                  ),
                ],
              ),
            ],
          ),
        ),
      ));
    }

    // --- CAMERA TILE ---
    if (widget.zone.hasCameras) {
      // Check if any camera is enabled
      bool isCameraActive = false;
      String statusText = 'Off';
      
      // We need to check actual camera status. 
      // Since we don't have it in _systemStatus yet, we'll assume active if we have cameras and they are enabled.
      // Ideally _loadDashboardData should populate this.
      // For now, let's use a placeholder or check _cameras list if available.
      
      // If we have cameras loaded
      if (_cameras.isNotEmpty) {
         final enabledCameras = _cameras.where((c) => c.enabled).toList();
         isCameraActive = enabledCameras.isNotEmpty;
         statusText = isCameraActive ? '${enabledCameras.length} Active' : 'Off';
      }

      tiles.add(_buildTileWrapper(
        DashboardControlTile(
          title: 'Cameras',
          statusIcon: Icon(Icons.videocam, color: isCameraActive ? Colors.pink : Colors.grey, size: 24),
          isActive: isCameraActive,
          activeColor: Colors.pink,
          onTap: _navigateToCameraControl,
          statusText: statusText,
          content: Column(
            children: [
              _InfoRow(label: 'Photos', value: '$_totalPhotos', valueColor: Colors.white),
              _InfoRow(label: 'Size', value: _storageUsed, valueColor: Colors.white70),
            ],
          ),
        ),
      ));
    }

    // --- SEEDLING MAT TILE ---
    if (_seedlingMatSettings != null) {
      final settings = _seedlingMatSettings!;
      final isActive = settings['enabled'] == 1;
      final mode = settings['mode'] ?? 'manual';
      final targetTemp = (settings['target_temp'] as num?)?.toDouble() ?? 24.0;
      final autoOffEnabled = settings['auto_off_enabled'] == 1;
      final daysRemaining = _calculateDaysRemaining(settings);
      
      // Get current temp from assigned sensor
      double? currentTemp;
      bool sensorError = false;
      if (settings['sensor_id'] != null) {
        final sensorId = settings['sensor_id'] as int;
        // Find reading
        if (_sensorReadings.containsKey(sensorId)) {
           currentTemp = (_sensorReadings[sensorId]?['value'] as num?)?.toDouble();
        }
        // Check for error (mock logic or if reading is null/out of range)
        if (currentTemp == null && isActive) sensorError = true; 
      }

      tiles.add(_buildTileWrapper(
        SeedlingMatTile(
          isActive: isActive,
          currentTemp: currentTemp,
          targetTemp: targetTemp,
          mode: mode,
          autoOffEnabled: autoOffEnabled,
          daysRemaining: daysRemaining,
          sensorError: sensorError,
          onTap: () => _navigateTo(SeedlingMatScreen(zone: widget.zone)),
          onToggle: () {
             // Toggle logic would go here
             debugPrint('Toggle Seedling Mat');
          },
        ),
      ));
    }

    // --- FERTIGATION TILE ---
    if (_zone.hasFertigation) {
      final isActive = _fertigationConfig?.enabled ?? false;
      
      tiles.add(_buildTileWrapper(
        DashboardControlTile(
          title: 'Fertigation',
          statusIcon: Icon(Icons.science, color: isActive ? Colors.teal : Colors.grey, size: 24),
          isActive: isActive,
          activeColor: Colors.teal,
          onTap: () => _navigateTo(FertigationSetupScreen(zone: widget.zone)),
          statusText: isActive ? 'Active' : 'Disabled',
          content: Column(
            children: [
              _InfoRow(label: 'pH Target', value: '${_fertigationConfig?.phTargetMin ?? 5.8} - ${_fertigationConfig?.phTargetMax ?? 6.2}', valueColor: Colors.teal),
              _InfoRow(label: 'EC Target', value: '${_fertigationConfig?.ecTarget ?? 1.4} mS/cm', valueColor: Colors.teal),
              _InfoRow(label: 'Reservoir', value: 'Unknown'), // Need reading
            ],
          ),
        ),
      ));
    }

    // --- GUARDIAN TILE ---
    if (widget.zone.hasGuardian) {
      final isActive = _guardianConfig?.enabled ?? false;
      
      tiles.add(_buildTileWrapper(
        DashboardControlTile(
          title: 'Guardian AI',
          statusIcon: Icon(Icons.psychology, color: isActive ? Colors.purple : Colors.grey, size: 24),
          isActive: isActive,
          activeColor: Colors.purple,
          onTap: () => _navigateTo(GuardianSetupScreen(zone: widget.zone)),
          statusText: isActive ? 'Active' : 'Disabled',
          content: Column(
            children: [
              _InfoRow(label: 'Last Check', value: 'Never', valueColor: Colors.white70),
              _InfoRow(label: 'Vision', value: (_guardianConfig?.visionEnabled ?? false) ? 'On' : 'Off', valueColor: Colors.purple),
            ],
          ),
        ),
      ));
    }

    if (tiles.isEmpty) {
      return Center(
        child: Text(
          'No systems configured. Go to Settings to enable features.',
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      );
    }

    // Use Wrap for responsive layout
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: tiles,
    );
  }

  Widget _buildTileWrapper(Widget tile) {
    // On large screens, fixed width. On small, full width.
    // Using LayoutBuilder in parent or just MediaQuery
    final width = MediaQuery.of(context).size.width;
    // If width > 600, show 2 columns.
    // Subtract padding (20 * 2) = 40.
    double tileWidth;
    if (width > 600) {
      tileWidth = (width - 40 - 12) / 2; // 2 columns with 12 spacing
    } else {
      tileWidth = width - 40; // Full width
    }
    
    return SizedBox(
      width: tileWidth,
      height: 240, // Increased height to prevent overflow and accommodate largest tile
      child: tile,
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) => _loadDashboardData());
  }

  String _getNextEventText(List<dynamic> schedules) {
    if (schedules.isEmpty) return 'None';
    // Simplified logic: just return the first schedule's time or "Scheduled"
    // In real app, calculate next occurrence
    return 'Scheduled';
  }

  Widget _buildSensorsGrid() {
    if (_sensors.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.sensors_off, color: Colors.white.withOpacity(0.3), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No sensors configured',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isReordering) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _sensors.length,
        onReorder: _swapSensors,
        itemBuilder: (context, index) {
          final sensor = _sensors[index];
          return Card(
            key: ValueKey(sensor.id),
            color: Colors.white.withOpacity(0.1),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(_getIconForSensor(sensor.sensorType), color: Colors.white70),
              title: Text(sensor.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(sensor.sensorType, style: const TextStyle(color: Colors.white54)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteSensor(sensor),
                  ),
                  const Icon(Icons.drag_handle, color: Colors.white54),
                ],
              ),
            ),
          );
        },
      );
    }

    // Flatten sensors into a list of display widgets
    List<Widget> sensorWidgets = [];
    
    for (int i = 0; i < _sensors.length; i++) {
      final sensor = _sensors[i];
      final readings = _sensorReadings[sensor.id];
      
      if (readings == null) continue;

      // Determine which sub-sensors to show based on type
      List<String> typesToShow = [];
      final normalizedType = sensor.sensorType.toLowerCase().trim();
      
      if (['dht22', 'bme280', 'bme680'].contains(normalizedType)) {
        typesToShow.add('temperature');
        typesToShow.add('humidity');
        if (['bme280', 'bme680'].contains(normalizedType)) {
          typesToShow.add('pressure');
        }
      } else {
        typesToShow.add('default');
      }

      for (var type in typesToShow) {
        sensorWidgets.add(_buildSingleSensorWidget(sensor, type, readings));
      }
    }

    return Center(
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.center,
        children: sensorWidgets,
      ),
    );
  }

  Widget _buildSingleSensorWidget(Sensor sensor, String type, Map<String, dynamic> readings) {
    String label = sensor.name;
    String value = '--';
    String unit = '';
    IconData icon = Icons.sensors;
    Color color = Colors.grey;

    if (type == 'temperature') {
      label = 'Temp';
      value = readings['temperature'] ?? '--';
      unit = '°C';
      icon = Icons.thermostat;
      color = Colors.orange;
    } else if (type == 'humidity') {
      label = 'Humidity';
      value = readings['humidity'] ?? '--';
      unit = '%';
      icon = Icons.water_drop;
      color = Colors.blueAccent;
    } else if (type == 'pressure') {
      label = 'Pressure';
      value = readings['pressure'] ?? '--';
      unit = 'hPa';
      icon = Icons.speed;
      color = Colors.indigoAccent;
    } else {
      // Default / Single value sensors
      value = readings['value'] ?? '--';
      unit = _getUnitForSensor(sensor.sensorType);
      icon = _getIconForSensor(sensor.sensorType);
      color = _getColorForSensor(sensor.sensorType);
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => SensorSetpointDialog(
            sensor: sensor,
            onSave: (updatedSensor) async {
              await _db.updateSensor(updatedSensor);
              _loadDashboardData();
            },
          ),
        );
      },
      child: GaiaSensorEye(
        label: label,
        value: value,
        unit: unit,
        icon: icon,
        color: color,
        isActive: sensor.enabled,
        size: 200,
        setpoint: sensor.setpointValue,
        min: sensor.minValue,
        max: sensor.maxValue,
        showSetpoint: sensor.useSetpoint,
        showRange: sensor.useRange,
      ),
    );
  }

  void _swapSensors(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _sensors.removeAt(oldIndex);
      _sensors.insert(newIndex, item);
    });
    _db.updateSensorOrder(_sensors);
  }

  Future<void> _deleteSensor(Sensor sensor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Sensor', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${sensor.name}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteSensor(sensor.id);
      _loadDashboardData();
    }
  }

  Future<void> _navigateToCameraControl() async {
    setState(() => _isLoading = true);
    try {
      final cameraAssignments = await _db.getZoneCameras(widget.zone.id!);
      
      if (cameraAssignments.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras configured for this zone')),
          );
        }
        return;
      }

      // Use the first camera assignment to get the full camera details
      final assignment = cameraAssignments.first;
      final camera = await _db.getCamera(assignment.cameraId);
      
      if (camera == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera not found')),
          );
        }
        return;
      }

      if (camera.id == null) return;

      final isRunning = CameraService.instance.isTimelapseRunning(camera.id!);
      final stats = await CameraService.instance.getCameraStats(camera.id!, widget.zone.id!);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            body: CameraDetailScreen(
              zoneId: widget.zone.id!,
              cameraId: camera.id!, // Added
              cameraIndex: camera.cameraIndex,
              isCameraActive: camera.enabled,
              isTimelapseRunning: isRunning,
              timelapseInterval: '${camera.captureIntervalHours}h',
              totalPhotos: stats['count'] as int? ?? 0,
              storageUsed: stats['storageUsed'],
              nextCapture: 'Pending',
              resolution: '${camera.resolutionWidth}x${camera.resolutionHeight}',
              cameraModel: camera.model,
              initialIntervalHours: camera.captureIntervalHours.toDouble(),
              onlyWhenLightsOn: camera.onlyWhenLightsOn,
              onIntervalChanged: (hours) async {
                final updatedCamera = Camera(
                  id: camera.id,
                  name: camera.name,
                  devicePath: camera.devicePath,
                  cameraIndex: camera.cameraIndex,
                  model: camera.model,
                  resolutionWidth: camera.resolutionWidth,
                  resolutionHeight: camera.resolutionHeight,
                  captureIntervalHours: hours.toInt(),
                  enabled: camera.enabled,
                  onlyWhenLightsOn: camera.onlyWhenLightsOn,
                  createdAt: camera.createdAt,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                );
                await CameraService.instance.updateCamera(updatedCamera);
                _loadDashboardData();
              },
              onToggleCamera: () async {
              final updatedCamera = Camera(
                id: camera.id,
                name: camera.name,
                devicePath: camera.devicePath,
                cameraIndex: camera.cameraIndex,
                model: camera.model,
                resolutionWidth: camera.resolutionWidth,
                resolutionHeight: camera.resolutionHeight,
                captureIntervalHours: camera.captureIntervalHours,
                enabled: !camera.enabled,
                onlyWhenLightsOn: camera.onlyWhenLightsOn,
                createdAt: camera.createdAt,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              );
              await CameraService.instance.updateCamera(updatedCamera);
              _loadDashboardData(); 
            },
            onStartTimelapse: () async {
              if (camera.id != null) {
                await CameraService.instance.startTimelapse(camera.id!, widget.zone.id!);
                _loadDashboardData();
              }
            },
            onStopTimelapse: () {
              if (camera.id != null) {
                CameraService.instance.stopTimelapse(camera.id!);
                _loadDashboardData();
              }
            },
            onTakePhoto: () async {
              if (camera.id != null) {
                return await CameraService.instance.captureImage(camera.id!, widget.zone.id!);
              }
              return null;
            },
            onToggleOnlyWhenLightsOn: (value) async {
               final updatedCamera = Camera(
                id: camera.id,
                name: camera.name,
                devicePath: camera.devicePath,
                cameraIndex: camera.cameraIndex,
                model: camera.model,
                resolutionWidth: camera.resolutionWidth,
                resolutionHeight: camera.resolutionHeight,
                captureIntervalHours: camera.captureIntervalHours,
                enabled: camera.enabled,
                onlyWhenLightsOn: value,
                createdAt: camera.createdAt,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              );
              await CameraService.instance.updateCamera(updatedCamera);
              _loadDashboardData();
            },
            onViewTimelapse: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TimelapseViewerScreen(
                      cameraId: camera.id!,
                      growId: widget.zone.id!,
                      cameraName: camera.name,
                    ),
                  ),
                );
              },
          ),
        ),
      ),
    ).then((_) => _loadDashboardData());
    } catch (e) {
      debugPrint('Error navigating to camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening camera: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildQuickActions() {
    // Only show if we have visible actions
    if (_hasCameras) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: _buildActionCard(
            'Camera',
            Icons.camera_alt,
            Colors.indigo,
            _navigateToCameraControl,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  String _getUnitForSensor(String sensorType) {
    switch (sensorType.toLowerCase().trim()) {
      case 'dht22':
      case 'bme280':
      case 'bme680':
        return '°C';
      case 'soil_moisture':
        return '%';
      case 'ph_sensor':
        return 'pH';
      case 'ec_sensor':
        return 'EC';
      case 'light_sensor':
        return 'lux';
      case 'water_level':
        return '%';
      case 'co2_sensor':
        return 'ppm';
      case 'pressure_sensor':
        return 'hPa';
      default:
        return '';
    }
  }

  IconData _getIconForSensor(String sensorType) {
    switch (sensorType.toLowerCase().trim()) {
      case 'dht22':
      case 'bme280':
      case 'bme680':
        return Icons.thermostat;
      case 'soil_moisture':
        return Icons.water_drop;
      case 'ph_sensor':
        return Icons.science;
      case 'ec_sensor':
        return Icons.electric_bolt;
      case 'light_sensor':
        return Icons.light_mode;
      case 'water_level':
        return Icons.water;
      case 'co2_sensor':
        return Icons.air;
      case 'pressure_sensor':
        return Icons.speed;
      default:
        return Icons.sensors;
    }
  }

  Color _getColorForSensor(String sensorType) {
    switch (sensorType.toLowerCase().trim()) {
      case 'dht22':
      case 'bme280':
      case 'bme680':
        return Colors.orange;
      case 'soil_moisture':
        return Colors.brown;
      case 'ph_sensor':
        return Colors.purple;
      case 'ec_sensor':
        return Colors.yellow;
      case 'light_sensor':
        return Colors.amber;
      case 'water_level':
        return Colors.blue;
      case 'co2_sensor':
        return Colors.grey;
      case 'pressure_sensor':
        return Colors.indigo;
      default:
        return Colors.green;
    }
  }

  Map<String, dynamic> _getSimulatedReadingsForSensor(String sensorType) {
    // In real app, fetch from sensor_readings table
    final normalizedType = sensorType.toLowerCase().trim();
    
    if (['dht22', 'bme280', 'bme680'].contains(normalizedType)) {
      return {
        'temperature': '23',
        'humidity': '45',
        'pressure': '1013',
        'status': 'optimal'
      };
    }

    switch (normalizedType) {
      case 'soil_moisture':
        return {'value': '65', 'status': 'optimal'};
      case 'ph_sensor':
        return {'value': '6.5', 'status': 'optimal'};
      case 'ec_sensor':
        return {'value': '1.8', 'status': 'optimal'};
      case 'light_sensor':
        return {'value': '450', 'status': 'optimal'};
      case 'water_level':
        return {'value': '12', 'status': 'optimal'};
      case 'co2_sensor':
        return {'value': '420', 'status': 'optimal'};
      case 'pressure_sensor':
        return {'value': '1013', 'status': 'optimal'};
      default:
        return {'value': '--', 'status': 'unknown'};
    }
  }

  Widget _buildActiveCropCard() {
    final cropName = _activeCrop?['crop_name'] ?? _activeCrop?['custom_name'] ?? 'Unknown Crop';
    final recipeName = _activeTemplate?['name'] ?? 'Custom Recipe';
    final phaseName = _currentPhase?['phase_name'] ?? 'Unknown Phase';
    final startDateEpoch = _activeCrop?['start_date'] as int?;
    final startDate = startDateEpoch != null 
        ? DateTime.fromMillisecondsSinceEpoch(startDateEpoch * 1000)
        : DateTime.now();
    final daysElapsed = DateTime.now().difference(startDate).inDays + 1;
    final progress = ((daysElapsed / (_currentPhase?['duration_days'] ?? 30)) * 100).clamp(0, 100).toDouble();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CropManagementScreen(zone: widget.zone),
          ),
        ).then((_) => _loadDashboardData());
      },
      child: _AnimatedCropCard(
        cropName: cropName,
        recipeName: recipeName,
        phaseName: phaseName,
        daysElapsed: daysElapsed,
        progress: progress,
        onCameraTap: widget.zone.hasCameras ? _navigateToCameraControl : null,
      ),
    );
  }

  Widget _buildCropStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FanSpeedRow extends StatelessWidget {
  final String name;
  final int speed;
  final bool isOn;
  final Color color;

  const _FanSpeedRow({
    required this.name,
    required this.speed,
    required this.isOn,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              name,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
          ),
          Expanded(
            child: isOn
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: speed / 100,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
                    ),
                  )
                : Text(
                    'OFF',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
                  ),
          ),
          if (isOn) ...[
            const SizedBox(width: 8),
            Text(
              '$speed%',
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}

class _TileActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _TileActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withOpacity(0.5)),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Irrigation Card Background (Caustic Water Effect)
// -----------------------------------------------------------------------------
class _IrrigationCardBackground extends StatefulWidget {
  const _IrrigationCardBackground();

  @override
  State<_IrrigationCardBackground> createState() => _IrrigationCardBackgroundState();
}

class _IrrigationCardBackgroundState extends State<_IrrigationCardBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Subtle Gradient Shift
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.blue.withOpacity(0.05),
                    Colors.blue.withOpacity(0.15),
                  ],
                  stops: [
                    0.0,
                    0.5 + (math.sin(_controller.value * math.pi * 2) * 0.2),
                    1.0,
                  ],
                ),
              ),
            );
          },
        ),
        
        // 2. Caustic Light Pattern
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _CausticPainter(animation: _controller),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }
}

class _CausticPainter extends CustomPainter {
  final Animation<double> animation;

  _CausticPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    final t = animation.value;
    final path = Path();

    // Create moving organic lines
    for (int i = 0; i < 3; i++) {
      final offset = i * (math.pi * 2 / 3);
      final x1 = size.width * (0.5 + 0.4 * math.sin(t * math.pi * 2 + offset));
      final y1 = size.height * (0.5 + 0.4 * math.cos(t * math.pi * 2 + offset));
      
      final x2 = size.width * (0.5 + 0.4 * math.sin(t * math.pi * 2 + offset + math.pi));
      final y2 = size.height * (0.5 + 0.4 * math.cos(t * math.pi * 2 + offset + math.pi));

      path.moveTo(x1, y1);
      path.quadraticBezierTo(size.width / 2, size.height / 2, x2, y2);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CausticPainter oldDelegate) => true;
}


// -----------------------------------------------------------------------------
// Animated Crop Card (Organic Leaf Sway & Growth Glow)
// -----------------------------------------------------------------------------
class _AnimatedCropCard extends StatefulWidget {
  final String cropName;
  final String recipeName;
  final String phaseName;
  final int daysElapsed;
  final double progress;
  final VoidCallback? onCameraTap;

  const _AnimatedCropCard({
    required this.cropName,
    required this.recipeName,
    required this.phaseName,
    required this.daysElapsed,
    required this.progress,
    this.onCameraTap,
  });

  @override
  State<_AnimatedCropCard> createState() => _AnimatedCropCardState();
}

class _AnimatedCropCardState extends State<_AnimatedCropCard> with TickerProviderStateMixin {
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    // Background: Sunbeams & Undulation
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark grey background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5), // Dark shadow
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. Parallax Background Layers
            
            // Layer 1: Back (Soft Bokeh) - Slowest
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) {
                  final t = _backgroundController.value;
                  final scale = 1.1 + (math.sin(t * math.pi * 2) * 0.005); // Base scale 1.1 to hide edges
                  final dx = math.sin(t * math.pi * 2) * 3; // +/- 3px drift
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: Transform.scale(
                      scale: scale,
                      child: Image.asset(
                        'assets/images/soft_bokeh_bg.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Layer 2: Mid (Macro Leaf) - Medium
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) {
                  final t = _backgroundController.value;
                  final scale = 1.1 + (math.sin((t + 0.3) * math.pi * 2) * 0.01); // Base scale 1.1
                  final dx = math.sin((t + 0.3) * math.pi * 2) * 6; // +/- 6px drift
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: Transform.scale(
                      scale: scale,
                      child: Image.asset(
                        'assets/images/macro_leaf_texture.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Layer 3: Front (Droplets) - Fastest
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) {
                  final t = _backgroundController.value;
                  final scale = 1.1 + (math.sin((t + 0.6) * math.pi * 2) * 0.015); // Base scale 1.1
                  final dx = math.sin((t + 0.6) * math.pi * 2) * 9; // +/- 9px drift
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: Transform.scale(
                      scale: scale,
                      child: Image.asset(
                        'assets/images/droplets_overlay.png',
                        fit: BoxFit.cover,
                        color: Colors.white.withOpacity(0.8), // Adjust opacity if needed
                        colorBlendMode: BlendMode.modulate,
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2. Dynamic Overlays (Sunbeams, Blobs, Droplets)
            CustomPaint(
              size: Size.infinite,
              painter: _OrganicBackgroundPainter(
                animation: _backgroundController,
              ),
            ),

            // 3. Progress Glow Indicator (Bottom)
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) {
                  return Container(
                    height: 4,
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1), // Track background
                    ),
                    child: FractionallySizedBox(
                      widthFactor: widget.progress / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.lightGreenAccent.withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                          color: Colors.lightGreenAccent,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(2),
                            bottomRight: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Crop Name (Top Center)
                  // Crop Name (Top Center)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      widget.cropName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      widget.recipeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Phase', widget.phaseName),
                        _buildStat('Day', '${widget.daysElapsed}'),
                        _buildStat('Progress', '${widget.progress.toStringAsFixed(0)}%'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            
            // 5. Camera Button (if available)
            if (widget.onCameraTap != null)
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: widget.onCameraTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.videocam, color: Colors.white, size: 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9), // Increased contrast
            fontSize: 12,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1))],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2))],
          ),
        ),
      ],
    );
  }
}

class _OrganicBackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  _OrganicBackgroundPainter({
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;

    // 1. Undulating Light Blobs (Subtle overlay on image)
    final blobPaint = Paint()..blendMode = BlendMode.overlay; // Overlay blend mode

    void drawBlob(double phaseX, double phaseY, Color color, double radius) {
      final x = size.width * (0.5 + 0.3 * math.sin(t * math.pi * 2 + phaseX));
      final y = size.height * (0.5 + 0.3 * math.cos(t * math.pi * 1.5 + phaseY));
      
      final shader = RadialGradient(
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)], // Reduced opacity
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));
      
      blobPaint.shader = shader;
      canvas.drawCircle(Offset(x, y), radius, blobPaint);
    }

    drawBlob(0, 0, Colors.yellow.shade700, size.width * 0.6);
    drawBlob(2, 1, Colors.teal.shade400, size.width * 0.5);
    drawBlob(4, 3, Colors.lightGreenAccent.shade400, size.width * 0.4);

    // 2. Sunbeams
    final rayPaint = Paint()
      ..color = Colors.white.withOpacity(0.05) // Reduced opacity as requested
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.overlay;

    final origin = const Offset(-50, -50);
    for (int i = 0; i < 5; i++) {
      final rayPath = Path();
      final rayAngle = (i * 0.3) + (math.sin(t * math.pi) * 0.1);
      
      rayPath.moveTo(origin.dx, origin.dy);
      rayPath.lineTo(size.width * 1.5 * math.cos(rayAngle), size.height * 1.5 * math.sin(rayAngle));
      rayPath.lineTo(size.width * 1.5 * math.cos(rayAngle + 0.15), size.height * 1.5 * math.sin(rayAngle + 0.15));
      rayPath.close();
      
      canvas.drawPath(rayPath, rayPaint);
    }

    // 3. Water Droplets (Extra shimmer)
    final dropletPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.3);
      
    final random = math.Random(42);
    for (int i = 0; i < 8; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final r = random.nextDouble() * 3 + 1;
      final shimmer = 0.5 + 0.5 * math.sin(t * math.pi * 4 + i);
      dropletPaint.color = Colors.white.withOpacity(0.1 + (0.4 * shimmer));
      canvas.drawCircle(Offset(dx, dy), r, dropletPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrganicBackgroundPainter oldDelegate) => true;
}
