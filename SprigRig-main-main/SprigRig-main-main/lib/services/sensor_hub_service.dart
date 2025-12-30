import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sensor_hub.dart';
import '../models/hub_diagnostic.dart';
import 'database_helper.dart';
import 'modbus_service.dart';

class SensorHubService {
  final DatabaseHelper _db = DatabaseHelper();
  final ModbusService _modbus = ModbusService();

  // Register Map Constants
  static const int REG_ADC_1 = 0; // 4-20mA #1
  static const int REG_ADC_2 = 1; // 4-20mA #2
  static const int REG_ADC_3 = 2; // 0-10V In #1
  static const int REG_ADC_4 = 3; // 0-10V In #2
  static const int REG_BME1_TEMP = 4;
  static const int REG_BME1_HUM = 5;
  static const int REG_BME2_TEMP = 6;
  static const int REG_BME2_HUM = 7;
  static const int REG_DIGITAL_IN = 8;
  static const int REG_HUB_ID = 9;
  static const int REG_FW_VER = 10;
  static const int REG_DAC_1 = 11; // 0-10V Out #1
  static const int REG_DAC_2 = 12; // 0-10V Out #2
  // Extended Sensors
  static const int REG_BH1750_LUX_HI = 13;
  static const int REG_BH1750_LUX_LO = 14;
  static const int REG_SCD40_CO2 = 15;
  static const int REG_SCD40_TEMP = 16;
  static const int REG_SCD40_HUM = 17;
  static const int REG_ATLAS_PH = 18;
  static const int REG_ATLAS_EC_HI = 19;
  static const int REG_ATLAS_EC_LO = 20;

  static const int TOTAL_REGISTERS = 21;

  // Conversion Constants
  static const double ADC_MAX = 4095.0;
  static const double DAC_MAX = 4095.0;

  // Cache
  List<SensorHub> _hubs = [];
  bool _isPolling = false;
  Timer? _pollingTimer;

  // Singleton pattern
  static final SensorHubService _instance = SensorHubService._internal();
  factory SensorHubService() => _instance;
  SensorHubService._internal();

  Future<void> init() async {
    await _loadHubs();
    startPolling();
  }

  Future<void> _loadHubs() async {
    _hubs = await _db.getSensorHubs();
  }

  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    // Poll every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _pollHubs();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _isPolling = false;
  }

  Future<void> _pollHubs() async {
    for (final hub in _hubs) {
      if (hub.status == 'maintenance') continue;

      try {
        // Read registers 0-20 (21 registers)
        final readings = await _modbus.readHoldingRegisters(hub.modbusAddress, 0, TOTAL_REGISTERS);
        
        if (readings.isEmpty || readings.length < TOTAL_REGISTERS) {
          throw Exception('Incomplete read from hub ${hub.modbusAddress}');
        }

        // Update hub status
        await _updateHubStatus(hub, 'online');
        
        // Process readings
        await _processReadings(hub, readings);

        // Log success
        await _logDiagnostic(hub.id, success: true);

      } catch (e) {
        debugPrint('Error polling hub ${hub.name}: $e');
        await _updateHubStatus(hub, 'error');
        await _logDiagnostic(hub.id, success: false, error: e.toString());
      }
    }
  }

  Future<void> _updateHubStatus(SensorHub hub, String status) async {
    if (hub.status != status) {
      final updatedHub = hub.copyWith(
        status: status,
        lastSeen: DateTime.now().toIso8601String(),
      );
      await _db.updateSensorHub(updatedHub);
      // Update local cache
      final index = _hubs.indexWhere((h) => h.id == hub.id);
      if (index != -1) _hubs[index] = updatedHub;
    }
  }

  Future<void> _processReadings(SensorHub hub, List<int> readings) async {
    // 32-bit value reconstruction
    int luxRaw = (readings[REG_BH1750_LUX_HI] << 16) | readings[REG_BH1750_LUX_LO];
    int ecRaw = (readings[REG_ATLAS_EC_HI] << 16) | readings[REG_ATLAS_EC_LO];

    // Convert raw readings to meaningful values
    final data = {
      'adc1_raw': readings[REG_ADC_1],
      'adc2_raw': readings[REG_ADC_2],
      'adc3_raw': readings[REG_ADC_3],
      'adc4_raw': readings[REG_ADC_4],
      'bme1_temp': readings[REG_BME1_TEMP] / 100.0,
      'bme1_hum': readings[REG_BME1_HUM] / 100.0,
      'bme2_temp': readings[REG_BME2_TEMP] / 100.0,
      'bme2_hum': readings[REG_BME2_HUM] / 100.0,
      'digital_inputs': readings[REG_DIGITAL_IN],
      'hub_id': readings[REG_HUB_ID],
      'fw_version': readings[REG_FW_VER],
      'dac1_val': readings[REG_DAC_1],
      'dac2_val': readings[REG_DAC_2],
      // Extended
      'lux': luxRaw / 100.0,
      'co2_ppm': readings[REG_SCD40_CO2],
      'scd_temp': readings[REG_SCD40_TEMP] / 100.0,
      'scd_hum': readings[REG_SCD40_HUM] / 100.0,
      'ph': readings[REG_ATLAS_PH] / 100.0, // Atlas pH is usually x100 or x1000. Header said x1000 but reg map comment said x100. Firmware used x100.
      'ec_us': ecRaw,
      // Calculated values
      'current_1_ma': _adcToCurrent(readings[REG_ADC_1]),
      'current_2_ma': _adcToCurrent(readings[REG_ADC_2]),
      'voltage_1_v': _adcToVoltage(readings[REG_ADC_3]),
      'voltage_2_v': _adcToVoltage(readings[REG_ADC_4]),
    };

    // TODO: Map these values to specific sensors in DB
    // For now, we just log them
    // debugPrint('Hub ${hub.name} Data: $data');
  }

  /// Convert ADC value to Current (4-20mA)
  double _adcToCurrent(int adc) {
    if (adc < 745) return 4.0; 
    return (adc - 745) * 16 / 2978 + 4;
  }

  /// Convert ADC value to Voltage (0-10V)
  double _adcToVoltage(int adc) {
    return adc * 10.0 / 3878.0;
  }

  Future<void> _logDiagnostic(int hubId, {required bool success, String? error}) async {
    final diag = HubDiagnostic(
      id: 0, 
      hubId: hubId,
      timestamp: DateTime.now().toIso8601String(),
      successfulReads: success ? 1 : 0,
      communicationErrors: success ? 0 : 1,
      lastErrorMessage: error,
    );
    await _db.insertHubDiagnostic(diag);
  }

  Future<void> calibrateSensor(int sensorId, double referenceValue, double currentValue) async {
    // TODO: Implement actual calibration logic (e.g. sending Modbus commands or updating DB offset)
    debugPrint('Calibrating sensor $sensorId: Ref=$referenceValue, Curr=$currentValue');
    // For now, just simulate a delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // --- Discovery ---

  Future<List<SensorHub>> discoverHubs() async {
    final addresses = await _modbus.scanForHubs();
    final newHubs = <SensorHub>[];

    for (final addr in addresses) {
      final exists = _hubs.any((h) => h.modbusAddress == addr);
      if (!exists) {
        final newHub = SensorHub(
          id: 0,
          modbusAddress: addr,
          name: 'Hub #$addr',
          status: 'online',
          createdAt: DateTime.now().toIso8601String(),
        );
        final id = await _db.insertSensorHub(newHub);
        
        // Generate IO channels for this hub
        await _db.generateHubChannels(addr);
        
        final savedHub = newHub.copyWith(id: id);
        _hubs.add(savedHub);
        newHubs.add(savedHub);
      }
    }
    return newHubs;
  }
}
