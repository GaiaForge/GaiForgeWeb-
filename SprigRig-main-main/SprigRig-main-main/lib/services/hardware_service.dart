import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../models/io_channel.dart';
import '../models/camera.dart';
import '../services/database_helper.dart';
import '../services/modbus_service.dart';

/// HardwareService handles interactions with the physical hardware
/// including GPIO control, sensor reading, camera operations, and Waveshare relay control.
class HardwareService {
  static HardwareService? _instance;
  static HardwareService get instance =>
      _instance ??= HardwareService._internal();

  HardwareService._internal();

  // Services
  final DatabaseHelper _db = DatabaseHelper();

  // Python script paths
  final String _scriptsDir = '/opt/sprigrig/python';

  // Cache for IO assignments
  final Map<int, List<IoAssignment>> _zoneIOCache = {};

  // Active zones tracking
  final Set<int> _activeZones = {};



  // Platform detection
  bool get isRaspberryPi {
    if (kIsWeb) return false;
    if (!Platform.isLinux) return false;

    // Check for Raspberry Pi specific files
    return Directory('/sys/firmware/devicetree/base').existsSync() ||
        File('/proc/device-tree/model').existsSync();
  }

  bool get isDevelopmentMode {
    return Platform.environment['SPRIGRIG_DEV'] == 'true' || !isRaspberryPi;
  }

  /// Initialize the hardware service
  Future<void> initialize() async {
    if (isDevelopmentMode) {
      debugPrint(
        '🔧 Running in DEVELOPMENT MODE - Hardware calls will be mocked',
      );
      return;
    }

    // Ensure scripts directory exists and is accessible
    final scriptsDir = Directory(_scriptsDir);
    if (!await scriptsDir.exists()) {
      throw Exception('Scripts directory not found: $_scriptsDir');
    }

    // Initialize GPIO pins
    await _runPythonScript('hardware/init_gpio.py');

    // Test Waveshare relay connection
    await _testWaveshareRelay();
  }

  /// Test Waveshare relay connection
  Future<bool> _testWaveshareRelay() async {
    try {
      // Try to read states from address 1
      final states = await ModbusService().getAllRelayStates(1);
      if (states.isNotEmpty) {
        debugPrint('Waveshare relay connected successfully. States: $states');
        return true;
      } else {
        debugPrint('Waveshare relay connection failed: No response');
        return false;
      }
    } catch (e) {
      debugPrint('Error testing Waveshare relay: $e');
      return false;
    }
  }

  /// Activate a zone
  Future<void> activateZone(int zoneId) async {
    // Check if zone is already active
    if (_activeZones.contains(zoneId)) {
      return;
    }

    try {
      // Get IO assignments for the zone
      final assignments = await _getZoneIOAssignments(zoneId);

      // Find the main control output
      final mainControl = assignments.firstWhere(
        (a) => a.function == 'main',
        orElse: () =>
            throw Exception('No main control output found for zone $zoneId'),
      );

      // Determine if this is a Waveshare relay channel (module >= 100)
      if (mainControl.moduleNumber != null &&
          mainControl.moduleNumber! >= 100) {
        // Use Waveshare relay
        final relayIndex = mainControl.channelNumber!; // Use 0-7 index directly
        final state = mainControl.invertLogic ? false : true;

        final success = await _setWaveshareRelay(relayIndex, state);
        if (!success) {
          // Don't throw exception, just log warning. 
          // This allows the UI to update even if readback fails.
          debugPrint('Warning: No response from Waveshare relay $relayIndex, assuming success');
        }
      } else {
        // Use traditional GPIO/ModBus control
        final value = mainControl.invertLogic ? 0 : 1;

        final result = await _runPythonScript('hardware/gpio_control.py', [
          '--channel',
          mainControl.channelNumber.toString(),
          '--module',
          mainControl.moduleNumber.toString(),
          '--value',
          value.toString(),
        ]);

        if (result.exitCode != 0) {
          throw Exception('Failed to activate zone $zoneId: ${result.stderr}');
        }
      }

      // Mark zone as active
      _activeZones.add(zoneId);
    } catch (e) {
      throw Exception('Error activating zone $zoneId: $e');
    }
  }

  /// Deactivate a zone
  Future<void> deactivateZone(int zoneId) async {
    // Check if zone is active
    if (!_activeZones.contains(zoneId)) {
      return;
    }

    try {
      // Get IO assignments for the zone
      final assignments = await _getZoneIOAssignments(zoneId);

      // Find the main control output
      final mainControl = assignments.firstWhere(
        (a) => a.function == 'main',
        orElse: () =>
            throw Exception('No main control output found for zone $zoneId'),
      );

      // Determine if this is a Waveshare relay channel (module >= 100)
      if (mainControl.moduleNumber != null &&
          mainControl.moduleNumber! >= 100) {
        // Use Waveshare relay
        final relayIndex = mainControl.channelNumber!; // Use 0-7 index directly
        final state = mainControl.invertLogic ? true : false;

        final success = await _setWaveshareRelay(relayIndex, state);
        if (!success) {
          debugPrint('Warning: No response from Waveshare relay $relayIndex (deactivate), assuming success');
        }
      } else {
        // Use traditional GPIO/ModBus control
        final value = mainControl.invertLogic ? 1 : 0;

        final result = await _runPythonScript('hardware/gpio_control.py', [
          '--channel',
          mainControl.channelNumber.toString(),
          '--module',
          mainControl.moduleNumber.toString(),
          '--value',
          value.toString(),
        ]);

        if (result.exitCode != 0) {
          throw Exception(
            'Failed to deactivate zone $zoneId: ${result.stderr}',
          );
        }
      }

      // Mark zone as inactive
      _activeZones.remove(zoneId);
    } catch (e) {
      // Try to force the zone inactive even if there's an error
      _activeZones.remove(zoneId);
      throw Exception('Error deactivating zone $zoneId: $e');
    }
  }

  /// Set Waveshare relay state
  Future<bool> _setWaveshareRelay(int relayIndex, bool state) async {
    // Relay index is 0-7
    
    try {
      return await ModbusService().setRelay(relayIndex, state);
    } catch (e) {
      debugPrint('Error controlling Waveshare relay: $e');
      return false;
    }
  }

  /// Get all Waveshare relay states
  Future<Map<String, bool>?> getAllWaveshareRelayStates() async {
    try {
      // Assuming slave ID 1 for now, similar to setRelay
      const slaveId = 1;
      final states = await ModbusService().getAllRelayStates(slaveId);
      
      if (states.isEmpty) return null;
      
      final result = <String, bool>{};
      for (int i = 0; i < states.length; i++) {
        // Map 0-7 index to relay_1 to relay_8 keys
        result['relay_${i + 1}'] = states[i];
      }
      return result;
    } catch (e) {
      debugPrint('Error getting all Waveshare relay states: $e');
      return null;
    }
  }

  /// Emergency shutdown - turn off all Waveshare relays
  Future<bool> emergencyShutdown() async {
    try {
      final success = await ModbusService().controlAllRelays(false);
      
      if (success) {
        // Clear all active zones
        _activeZones.clear();
        debugPrint('Emergency shutdown executed successfully');
      } else {
        debugPrint('Emergency shutdown failed to send command');
      }
      
      return success;
    } catch (e) {
      debugPrint('Error during emergency shutdown: $e');
      return false;
    }
  }

  /// Test all Waveshare relay channels
  Future<Map<String, dynamic>?> testWaveshareRelays() async {
    final results = <String, dynamic>{};
    final modbus = ModbusService();
    
    try {
      // Ensure all off to start
      await modbus.controlAllRelays(false);
      await Future.delayed(const Duration(milliseconds: 200));

      for (int i = 0; i < 8; i++) {
        final relayKey = 'relay_${i + 1}';
        bool working = true;
        bool onSuccess = false;
        bool offSuccess = false;

        // Test ON
        await modbus.setRelay(i, true);
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Verify ON
        var states = await modbus.getAllRelayStates(1);
        if (states.isNotEmpty && states.length > i && states[i]) {
          onSuccess = true;
        } else {
          working = false;
        }

        // Test OFF
        await modbus.setRelay(i, false);
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Verify OFF
        states = await modbus.getAllRelayStates(1);
        if (states.isNotEmpty && states.length > i && !states[i]) {
          offSuccess = true;
        } else {
          working = false;
        }

        results[relayKey] = {
          'working': working,
          'on_success': onSuccess,
          'off_success': offSuccess,
        };
      }
      
      return results;
    } catch (e) {
      debugPrint('Error testing Waveshare relays: $e');
      return null;
    }
  }

  /// Read a sensor value
  Future<double> readSensor(int sensorId, String readingType) async {
    try {
      // Get sensor details from database
      final sensor = await _db.getSensorById(sensorId);
      if (sensor == null) {
        throw Exception('Sensor not found: $sensorId');
      }

      // Check if the sensor supports this reading type
      if (!sensor.getSupportedReadingTypes().contains(readingType)) {
        throw Exception(
          'Sensor $sensorId does not support reading type: $readingType',
        );
      }

      // Run the sensor reading script
      final result = await _runPythonScript('hardware/sensor_reader.py', [
        '--type',
        sensor.sensorType,
        '--address',
        sensor.address ?? '',
        '--reading',
        readingType,
      ]);

      // Check result
      if (result.exitCode != 0) {
        throw Exception('Failed to read sensor $sensorId: ${result.stderr}');
      }

      // Parse the result
      final value = double.tryParse(result.stdout.trim());
      if (value == null) {
        throw Exception('Invalid sensor reading: ${result.stdout}');
      }

      // Log the reading in the database
      await _db.logSensorReading(sensorId, readingType, value);

      return value;
    } catch (e) {
      throw Exception('Error reading sensor $sensorId: $e');
    }
  }

  /// Capture an image from a camera
  Future<String> captureImage(int cameraId, int cameraIndex, int growId, int width, int height) async {
    // Fallback to default resolution if not set
    final effectiveWidth = width > 0 ? width : 1920;
    final effectiveHeight = height > 0 ? height : 1080;

    try {
      // Create the images directory if it doesn't exist
      final imagesDir = Directory('/home/sprigrig/SprigRig-main/media/images/grow_$growId');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Generate a filename
      final timestamp = DateTime.now();
      final filename =
          'cam${cameraId}_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}.jpg';
      final filePath = path.join(imagesDir.path, filename);

      // Run the camera capture script
      final result = await _runPythonScript('hardware/camera_capture.py', [
        '--camera',
        cameraIndex.toString(),
        '--width',
        effectiveWidth.toString(),
        '--height',
        effectiveHeight.toString(),
        '--output',
        filePath,
      ]);

      // Check result
      if (result.exitCode != 0) {
        throw Exception(
          'Failed to capture image from camera $cameraId: ${result.stderr}',
        );
      }

      // Create thumbnail
      final thumbnailFilename = 'thumb_$filename';
      final thumbnailPath = path.join(imagesDir.path, thumbnailFilename);

      await _runPythonScript('hardware/create_thumbnail.py', [
        '--input',
        filePath,
        '--output',
        thumbnailPath,
        '--size',
        '320',
      ]);

      // Get grow details for metadata
      final grow = await _db.getGrow(growId);
      if (grow == null) {
        throw Exception('Grow not found: $growId');
      }

      // Calculate grow day and hour
      final growStartTime = DateTime.fromMillisecondsSinceEpoch(
        grow.startTime * 1000,
      );
      final elapsedDuration = timestamp.difference(growStartTime);
      final growDay = elapsedDuration.inDays;
      final growHour = (elapsedDuration.inHours % 24);

      // Save the image metadata in the database
      await _db.saveImage(
        cameraId,
        growId,
        filePath,
        thumbnailPath: thumbnailPath,
        timestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
        growDay: growDay,
        growHour: growHour,
      );

      return filePath;
    } catch (e) {
      throw Exception('Error capturing image from camera $cameraId: $e');
    }
  }

  /// Control an environmental control (like lighting, ventilation, etc.)
  Future<void> setEnvironmentalControl(int controlId, bool state) async {
    try {
      // Get the control details
      final control = await _db.getZoneControl(controlId);
      if (control == null) {
        throw Exception('Control not found: $controlId');
      }

      // Get IO assignments for this control
      final assignments = await _db.getControlIoAssignments(controlId);

      // Find the main control output
      final mainControl = assignments.firstWhere(
        (a) => a.function == 'main',
        orElse: () => throw Exception(
          'No main control output found for control $controlId',
        ),
      );

      // Determine if this is a Waveshare relay channel (module >= 100)
      if (mainControl.moduleNumber != null &&
          mainControl.moduleNumber! >= 100) {
        // Use Waveshare relay
        final relayIndex = mainControl.channelNumber!; // Use 0-7 index directly
        final actualState = mainControl.invertLogic ? !state : state;

        final success = await _setWaveshareRelay(relayIndex, actualState);
        if (!success) {
           debugPrint('Warning: No response from Waveshare relay $relayIndex (setControl), assuming success');
        }
      } else {
        // Use traditional GPIO/ModBus control
        final value = mainControl.invertLogic
            ? (state ? 0 : 1)
            : (state ? 1 : 0);

        final result = await _runPythonScript('hardware/gpio_control.py', [
          '--channel',
          mainControl.channelNumber?.toString() ?? '0',
          '--module',
          mainControl.moduleNumber?.toString() ?? '1',
          '--value',
          value.toString(),
        ]);

        if (result.exitCode != 0) {
          throw Exception('Failed to set control $controlId: ${result.stderr}');
        }
      }

      // Log the state change
      await _db.toggleZoneControl(controlId, state);
    } catch (e) {
      throw Exception('Error setting control $controlId: $e');
    }
  }

  /// Set PWM value for a control (like dimming, speed control, etc.)
  Future<void> setPwmValue(int controlId, String function, int value) async {
    try {
      // Value should be between 0 and 100
      final pwmValue = value.clamp(0, 100);

      // Get IO assignments for this control
      final assignments = await _db.getControlIoAssignments(controlId);

      // Find the PWM output for this function
      final pwmOutput = assignments.firstWhere(
        (a) => a.function == function,
        orElse: () =>
            throw Exception('No $function output found for control $controlId'),
      );

      // Run the PWM control script
      final result = await _runPythonScript('hardware/pwm_control.py', [
        '--channel',
        pwmOutput.channelNumber?.toString() ?? '0',
        '--module',
        pwmOutput.moduleNumber?.toString() ?? '1',
        '--value',
        pwmValue.toString(),
      ]);

      // Check result
      if (result.exitCode != 0) {
        throw Exception(
          'Failed to set PWM value for control $controlId: ${result.stderr}',
        );
      }

      // Update the setting in the database
      await _db.updateControlSetting(
        controlId,
        function == 'dimming' ? 'brightness' : 'speed',
        pwmValue.toString(),
        unit: '%',
      );
    } catch (e) {
      throw Exception('Error setting PWM value for control $controlId: $e');
    }
  }

  /// Detect available cameras
  Future<List<Map<String, dynamic>>> detectCameras() async {
    try {
      // Run the camera detection script
      final result = await _runPythonScript('hardware/detect_cameras.py');

      // Check result
      if (result.exitCode != 0) {
        throw Exception('Failed to detect cameras: ${result.stderr}');
      }

      // Parse the result
      final List<dynamic> camerasJson = jsonDecode(result.stdout);
      return List<Map<String, dynamic>>.from(camerasJson);
    } catch (e) {
      throw Exception('Error detecting cameras: $e');
    }
  }

  /// Detect available I2C devices
  Future<List<Map<String, dynamic>>> detectI2CDevices() async {
    try {
      // Run the I2C detection script
      final result = await _runPythonScript('hardware/detect_i2c.py');

      // Check result
      if (result.exitCode != 0) {
        throw Exception('Failed to detect I2C devices: ${result.stderr}');
      }

      // Parse the result
      final List<dynamic> devicesJson = jsonDecode(result.stdout);
      return List<Map<String, dynamic>>.from(devicesJson);
    } catch (e) {
      throw Exception('Error detecting I2C devices: $e');
    }
  }

  /// Set module configuration
  Future<void> configureModule(
    int moduleNumber,
    List<Map<String, dynamic>> channelConfig,
  ) async {
    try {
      // Prepare the configuration JSON
      final configJson = jsonEncode(channelConfig);

      // Create a temporary file for the configuration
      final tempDir = await Directory.systemTemp.createTemp('sprigrig_');
      final tempFile = File(path.join(tempDir.path, 'module_config.json'));
      await tempFile.writeAsString(configJson);

      // Run the module configuration script
      final result = await _runPythonScript('hardware/configure_module.py', [
        '--module',
        moduleNumber.toString(),
        '--config',
        tempFile.path,
      ]);

      // Check result
      if (result.exitCode != 0) {
        throw Exception(
          'Failed to configure module $moduleNumber: ${result.stderr}',
        );
      }

      // Clean up the temporary file
      await tempFile.delete();
      await tempDir.delete();
    } catch (e) {
      throw Exception('Error configuring module $moduleNumber: $e');
    }
  }

  /// Get IO assignments for a zone
  Future<List<IoAssignment>> _getZoneIOAssignments(int zoneId) async {
    // Check cache first
    if (_zoneIOCache.containsKey(zoneId)) {
      return _zoneIOCache[zoneId]!;
    }

    // Get zone controls
    final controls = await _db.getZoneControls(zoneId);

    // Collect all IO assignments
    final List<IoAssignment> assignments = [];
    for (final control in controls) {
      assignments.addAll(await _db.getControlIoAssignments(control.id));
    }

    // Cache the result
    _zoneIOCache[zoneId] = assignments;

    return assignments;
  }

  /// Clear the IO assignment cache for a zone
  void clearZoneIOCache(int zoneId) {
    _zoneIOCache.remove(zoneId);
  }

  /// Clear the entire IO assignment cache
  void clearAllIOCache() {
    _zoneIOCache.clear();
  }

  /// Run a Python script
  Future<ProcessResult> _runPythonScript(
    String scriptPath, [
    List<String>? args,
  ]) async {
    final fullPath = path.join(_scriptsDir, scriptPath);

    // Check if the script exists
    final scriptFile = File(fullPath);
    if (!await scriptFile.exists()) {
      throw Exception('Script not found: $fullPath');
    }

    // Build the command
    final command = 'python3';
    final commandArgs = [fullPath, ...?args];

    // Run the process
    return Process.run(command, commandArgs);
  }

  /// Check if a zone is active
  bool isZoneActive(int zoneId) {
    return _activeZones.contains(zoneId);
  }

  /// Get all active zones
  List<int> getActiveZones() {
    return List<int>.from(_activeZones);
  }
}
