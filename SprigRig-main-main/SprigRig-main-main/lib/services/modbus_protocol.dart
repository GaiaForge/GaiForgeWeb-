import 'dart:typed_data';

class ModbusProtocol {
  // Constants
  static const int WAVESHARE_MODULE_BASE = 100;
  static const int MODBUS_READ_COILS = 0x01;
  static const int MODBUS_WRITE_SINGLE_COIL = 0x05;
  static const int MODBUS_WRITE_MULTIPLE_COILS = 0x0F;

  /// Calculate CRC16 for Modbus
  static int calculateCRC(List<int> data) {
    int crc = 0xFFFF;
    for (int byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc >>= 1;
          crc ^= 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc;
  }

  /// Append CRC to data
  static Uint8List withCRC(List<int> data) {
    int crc = calculateCRC(data);
    return Uint8List.fromList([...data, crc & 0xFF, (crc >> 8) & 0xFF]);
  }

  /// Verify CRC of a response
  static bool verifyCRC(Uint8List data) {
    if (data.length < 2) return false;
    int receivedCRC = data[data.length - 2] | (data[data.length - 1] << 8);
    int calculatedCRC = calculateCRC(data.sublist(0, data.length - 2));
    return receivedCRC == calculatedCRC;
  }

  /// Generate command to control a single relay (Function 0x05)
  /// [address]: Device address (1-255)
  /// [relayIndex]: Relay index (0-7)
  /// [isOn]: True for ON, False for OFF
  static Uint8List controlSingleRelay(int address, int relayIndex, bool isOn) {
    // Function 0x05 - Write Single Coil
    // Command: ADDR 05 00 XX FF 00 CRC CRC (ON)
    // Command: ADDR 05 00 XX 00 00 CRC CRC (OFF)
    return withCRC([
      address,
      MODBUS_WRITE_SINGLE_COIL,
      0x00, relayIndex,
      isOn ? 0xFF : 0x00, 0x00
    ]);
  }

  /// Generate command to control all relays (Function 0x0F)
  /// [address]: Device address (1-255)
  /// [isOn]: True for ON, False for OFF
  static Uint8List controlAllRelays(int address, bool isOn) {
    // Function 0x0F - Write Multiple Coils
    // Writing to 8 coils starting at 0
    return withCRC([
      address,
      MODBUS_WRITE_MULTIPLE_COILS,
      0x00, 0x00,           // Start Address 0
      0x00, 0x08,           // Quantity 8
      0x01,                 // Byte Count 1
      isOn ? 0xFF : 0x00    // Data byte
    ]);
  }

  /// Generate command to read relay status (Function 0x01)
  /// [address]: Device address (1-255)
  /// [startRelay]: Start relay index (usually 0)
  /// [count]: Number of relays to read (usually 8)
  static Uint8List readRelayStatus(int address, {int startRelay = 0, int count = 8}) {
    // Function 0x01 - Read Coils
    // Command: ADDR 01 00 00 00 08 CRC CRC
    return withCRC([
      address,
      MODBUS_READ_COILS,
      (startRelay >> 8) & 0xFF, startRelay & 0xFF,
      (count >> 8) & 0xFF, count & 0xFF
    ]);
  }

  /// Generate command to set relay flash/delay
  /// [address]: Device address
  /// [relayIndex]: Relay index (0-7)
  /// [isOn]: True for Flash ON, False for Flash OFF
  /// [delayMs]: Delay in milliseconds (multiples of 100ms)
  static Uint8List setRelayFlash(int address, int relayIndex, bool isOn, int delayMs) {
    int delayUnits = (delayMs / 100).round();
    return withCRC([
      address,
      MODBUS_WRITE_SINGLE_COIL,
      isOn ? 0x02 : 0x04,
      0x00, relayIndex,
      (delayUnits >> 8) & 0xFF, delayUnits & 0xFF
    ]);
  }
}