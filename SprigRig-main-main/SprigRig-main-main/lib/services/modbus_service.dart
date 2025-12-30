import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'database_helper.dart';
import 'modbus_protocol.dart';

class ModbusService {
  static final ModbusService _instance = ModbusService._internal();
  factory ModbusService() => _instance;

  ModbusService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  
  // Serial ports
  SerialPort? _relayPort;
  SerialPort? _hubPort;
  
  // Configuration cache
  String? _relayPortName;
  String? _hubPortName;
  int _relayBaud = 9600;
  int _hubBaud = 9600;

  bool _isInitialized = false;
  bool _isTransactionInProgress = false;
  
  // Debug Logging
  final _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;
  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1].substring(0, 8);
    final logMsg = '[$timestamp] $message';
    debugPrint(logMsg);
    _logs.add(logMsg);
    if (_logs.length > 100) _logs.removeAt(0);
    _logController.add(logMsg);
  }
  
  // Mock state
  final List<bool> _mockRelayStates = List.filled(8, false);

  Future<void> initialize() async {
    if (_isInitialized) return;

    // RS485 CAN HAT (B) uses SC16IS752 chip via SPI
    // Creates /dev/ttySC0 (Channel 1) and /dev/ttySC1 (Channel 2)
    // Requires dtoverlay=sc16is752-spi1,int_pin=25 in /boot/config.txt
    
    // Load settings
    _relayPortName = await _db.getSetting('modbus_relay_port') ?? '/dev/ttySC0';
    _hubPortName = await _db.getSetting('modbus_hub_port') ?? '/dev/ttySC1';
    _relayBaud = await _db.getIntSetting('modbus_relay_baud', defaultValue: 9600);
    _hubBaud = await _db.getIntSetting('modbus_hub_baud', defaultValue: 9600);

    _isInitialized = true;
    _log('Initialized: Relay=$_relayPortName@$_relayBaud, Hub=$_hubPortName@$_hubBaud');
  }

  Future<void> reloadSettings() async {
    _isInitialized = false;
    _relayPort?.close();
    _hubPort?.close();
    _relayPort = null;
    _hubPort = null;
    await initialize();
    _log('Settings reloaded');
  }

  Future<void> _ensureConnection(bool isRelay) async {
    if (!_isInitialized) await initialize();

    final portName = isRelay ? _relayPortName : _hubPortName;
    final baudRate = isRelay ? _relayBaud : _hubBaud;
    
    if (portName == null) return;

    // Check if port needs to be opened
    SerialPort? port = isRelay ? _relayPort : _hubPort;
    
    if (port == null || port.name != portName || !port.isOpen) {
      // Close existing if changed
      port?.close();
      
      try {
        final newPort = SerialPort(portName);
        if (newPort.openReadWrite()) {
          final config = SerialPortConfig();
          config.baudRate = baudRate;
          config.bits = 8;
          config.stopBits = 1;
          config.parity = SerialPortParity.none;
          config.setFlowControl(SerialPortFlowControl.none);
          newPort.config = config;
          config.dispose(); // Release native resources
          
          if (isRelay) {
            _relayPort = newPort;
          } else {
            _hubPort = newPort;
          }
          _log('Opened serial port: $portName');
        } else {
          _log('Failed to open serial port: $portName');
          // On Mac/Dev, this might fail if hardware isn't present.
          // We'll proceed but commands will just log.
        }
      } catch (e) {
        _log('Error opening serial port $portName: $e');
      }
    }
  }

  /// Send command to Waveshare Relay Board
  Future<bool> setRelay(int relayIndex, bool isOn) async {
    await _ensureConnection(true);
    
    // Default address for Waveshare Relay is usually 1, but could be configured.
    const address = 1; 
    
    final command = ModbusProtocol.controlSingleRelay(address, relayIndex, isOn);
    return _sendCommand(_relayPort, command);
  }

  /// Control all relays at once
  Future<bool> controlAllRelays(bool turnOn) async {
    await _ensureConnection(true);
    const address = 1;
    final command = ModbusProtocol.controlAllRelays(address, turnOn);
    return _sendCommand(_relayPort, command);
  }

  /// Get all relay states
  Future<List<bool>> getAllRelayStates(int slaveAddress) async {
    await _ensureConnection(true);
    
    final command = ModbusProtocol.readRelayStatus(slaveAddress);
    final response = await _sendCommandWithResponse(_relayPort, command, expectedLength: 6); // 1 addr + 1 func + 1 byte count + 1 data + 2 CRC
    
    if (response != null && response.length >= 4) {
      // Byte 3 (index 3) is the data byte containing 8 coils
      final dataByte = response[3];
      final states = <bool>[];
      for (int i = 0; i < 8; i++) {
        states.add((dataByte & (1 << i)) != 0);
      }
      return states;
    }
    
    // Return empty list on failure
    return [];
  }

  /// Read holding registers (Function 0x03)
  Future<List<int>> readHoldingRegisters(int address, int startReg, int count) async {
    await _ensureConnection(false); // Use hub port
    
    // Command: 01 03 00 00 00 08 CRC CRC
    // Function 0x03 is Read Holding Registers
    final command = ModbusProtocol.withCRC([
      address,
      0x03,
      (startReg >> 8) & 0xFF, startReg & 0xFF,
      (count >> 8) & 0xFF, count & 0xFF
    ]);
    
    final response = await _sendCommandWithResponse(_hubPort, command, expectedLength: 5 + (count * 2));
    
    if (response != null && response.length > 3) {
      final byteCount = response[2];
      final values = <int>[];
      for (int i = 0; i < byteCount; i += 2) {
        if (i + 4 < response.length) {
          values.add((response[3 + i] << 8) | response[4 + i]);
        }
      }
      return values;
    }
    return [];
  }

  /// Scan for hubs on the bus
  Future<List<int>> scanForHubs() async {
    await _ensureConnection(false);
    final foundAddresses = <int>[];
    
    // Scan standard range 1-10 or configurable
    for (int addr = 1; addr <= 10; addr++) {
      // Try to read register 0 (usually ID or Version)
      final regs = await readHoldingRegisters(addr, 0, 1);
      if (regs.isNotEmpty) {
        foundAddresses.add(addr);
      }
    }
    return foundAddresses;
  }

  /// Check status of a specific hub
  Future<String> checkHubStatus(int address) async {
    await _ensureConnection(false);
    
    if (_hubPort == null || !_hubPort!.isOpen) {
      return 'Mock';
    }

    try {
      // Try to read register 0 (usually ID or Version)
      final regs = await readHoldingRegisters(address, 0, 1);
      if (regs.isNotEmpty) {
        return 'Connected';
      }
    } catch (e) {
      // Ignore error
    }
    
    return 'Disconnected';
  }

  /// Send raw command to a port
  Future<bool> _sendCommand(SerialPort? port, Uint8List command) async {
    final response = await _sendCommandWithResponse(port, command);
    return response != null;
  }

  Future<Uint8List?> _sendCommandWithResponse(SerialPort? port, Uint8List command, {int expectedLength = 8}) async {
    if (port == null || !port.isOpen) {
      _log('Warning: Port not open. Using Mock Mode.');
      _log('Mock Send: ${command.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      
      // Mock response generation
      final functionCode = command[1];
      
      if (functionCode == ModbusProtocol.MODBUS_WRITE_SINGLE_COIL) {
        // Update mock state
        final relayIndex = command[3];
        final isOn = command[4] == 0xFF;
        if (relayIndex < _mockRelayStates.length) {
          _mockRelayStates[relayIndex] = isOn;
        }
        // Echo command as response
        return command;
      } else if (functionCode == ModbusProtocol.MODBUS_WRITE_MULTIPLE_COILS) {
        // Update all mock states
        final isOn = command[7] == 0xFF; // Simplified for all on/off
        for (int i = 0; i < _mockRelayStates.length; i++) {
          _mockRelayStates[i] = isOn;
        }
        // Response: Addr, Func, Start Hi, Start Lo, Qty Hi, Qty Lo, CRC, CRC
        return ModbusProtocol.withCRC(command.sublist(0, 6));
      } else if (functionCode == ModbusProtocol.MODBUS_READ_COILS) {
        // Construct data byte from mock states
        int dataByte = 0;
        for (int i = 0; i < 8; i++) {
          if (i < _mockRelayStates.length && _mockRelayStates[i]) {
            dataByte |= (1 << i);
          }
        }
        // Mock read response: Addr, Func, Bytes, Data, CRC, CRC
        return ModbusProtocol.withCRC([command[0], functionCode, 1, dataByte]);
      }
      
      return Uint8List.fromList([command[0], command[1], 0, 0, 0, 0, 0, 0]); // Generic mock
    }

    try {
      port.flush(SerialPortBuffer.input);
      
      final written = port.write(command);
      if (written != command.length) {
        _log('Write failed: $written/${command.length}');
        return null;
      }
      
      _log('TX: ${command.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      
      // Match Python timing - just wait, then read
      await Future.delayed(const Duration(milliseconds: 100));
      
      final response = port.read(expectedLength);
      
      if (response.isEmpty) {
        _log('No response');
        return null;
      }
      
      _log('RX: ${response.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      
      if (!ModbusProtocol.verifyCRC(response)) {
        _log('CRC error');
        return null;
      }
      
      return response;
    } catch (e) {
      _log('Error: $e');
      return null;
    }
  }

  /// Close ports
  void dispose() {
    _relayPort?.close();
    _hubPort?.close();
  }
}
