class SensorHub {
  final int id;
  final int modbusAddress;
  final String name;
  final int? zoneId;
  final String status; // 'online', 'offline', 'error', 'maintenance'
  final String? lastSeen;
  final String? firmwareVersion;
  final String? hardwareRevision;
  final int totalChannels;
  final String createdAt;

  SensorHub({
    required this.id,
    required this.modbusAddress,
    required this.name,
    this.zoneId,
    this.status = 'offline',
    this.lastSeen,
    this.firmwareVersion,
    this.hardwareRevision,
    this.totalChannels = 8,
    required this.createdAt,
  });

  factory SensorHub.fromMap(Map<String, dynamic> map) {
    return SensorHub(
      id: map['id'] as int,
      modbusAddress: map['modbus_address'] as int,
      name: map['name'] as String,
      zoneId: map['zone_id'] as int?,
      status: map['status'] as String? ?? 'offline',
      lastSeen: map['last_seen'] as String?,
      firmwareVersion: map['firmware_version'] as String?,
      hardwareRevision: map['hardware_revision'] as String?,
      totalChannels: map['total_channels'] as int? ?? 8,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'modbus_address': modbusAddress,
      'name': name,
      'zone_id': zoneId,
      'status': status,
      'last_seen': lastSeen,
      'firmware_version': firmwareVersion,
      'hardware_revision': hardwareRevision,
      'total_channels': totalChannels,
      'created_at': createdAt,
    };
  }

  SensorHub copyWith({
    int? id,
    int? modbusAddress,
    String? name,
    int? zoneId,
    String? status,
    String? lastSeen,
    String? firmwareVersion,
    String? hardwareRevision,
    int? totalChannels,
    String? createdAt,
  }) {
    return SensorHub(
      id: id ?? this.id,
      modbusAddress: modbusAddress ?? this.modbusAddress,
      name: name ?? this.name,
      zoneId: zoneId ?? this.zoneId,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      hardwareRevision: hardwareRevision ?? this.hardwareRevision,
      totalChannels: totalChannels ?? this.totalChannels,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
