// lib/models/io_channel.dart
class IoChannel {
  final int id;
  final int channelNumber;
  final int moduleNumber;
  final bool isInput;
  final String? type; // 'di', 'do', 'ai', 'ao', 'i2c', 'spi'
  final String? name;
  final bool isAssigned;
  final String? assignedTo; // New field
  final int createdAt;
  final int updatedAt;

  IoChannel({
    required this.id,
    required this.channelNumber,
    required this.moduleNumber,
    required this.isInput,
    this.type,
    this.name,
    required this.isAssigned,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IoChannel.fromMap(Map<String, dynamic> map) {
    return IoChannel(
      id: map['id'] as int,
      channelNumber: map['channel_number'] as int,
      moduleNumber: map['module_number'] as int,
      isInput: (map['is_input'] as int) == 1,
      type: map['type'] as String?,
      name: map['name'] as String?,
      isAssigned: (map['is_assigned'] as int) == 1,
      assignedTo: map['assigned_to_name'] as String?, // Populated from join
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'channel_number': channelNumber,
      'module_number': moduleNumber,
      'is_input': isInput ? 1 : 0,
      'type': type,
      'name': name,
      'is_assigned': isAssigned ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class IoAssignment {
  final int id;
  final int zoneControlId;
  final int ioChannelId;
  final String function;
  final bool invertLogic;
  final int? channelNumber;
  final int? moduleNumber;
  final bool? isInput;
  final String? channelName;

  IoAssignment({
    required this.id,
    required this.zoneControlId,
    required this.ioChannelId,
    required this.function,
    required this.invertLogic,
    this.channelNumber,
    this.moduleNumber,
    this.isInput,
    this.channelName,
  });

  factory IoAssignment.fromMap(Map<String, dynamic> map) {
    return IoAssignment(
      id: map['id'] as int,
      zoneControlId: map['zone_control_id'] as int,
      ioChannelId: map['io_channel_id'] as int,
      function: map['function'] as String,
      invertLogic: (map['invert_logic'] as int) == 1,
      channelNumber: map['channel_number'] as int?,
      moduleNumber: map['module_number'] as int?,
      isInput: map['is_input'] != null ? (map['is_input'] as int) == 1 : null,
      channelName: map['channel_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_control_id': zoneControlId,
      'io_channel_id': ioChannelId,
      'function': function,
      'invert_logic': invertLogic ? 1 : 0,
      'channel_number': channelNumber,
      'module_number': moduleNumber,
      'is_input': isInput != null ? (isInput! ? 1 : 0) : null,
      'channel_name': channelName,
    };
  }
}
