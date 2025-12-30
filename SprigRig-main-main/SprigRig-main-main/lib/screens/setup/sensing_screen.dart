import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../models/sensor.dart';
import '../../models/sensor_hub.dart';
import '../../models/io_channel.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';

class SensingScreen extends StatefulWidget {
  final Zone zone;
  const SensingScreen({super.key, required this.zone});

  @override
  State<SensingScreen> createState() => _SensingScreenState();
}

class _SensingScreenState extends State<SensingScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Sensor> _sensors = [];
  bool _isLoading = true;

  final List<String> _sensorTypes = [
    'dht22',
    'soil_moisture',
    'ph_sensor',
    'ec_sensor',
    'light_sensor',
    'water_level',
    'co2_sensor',
    'pressure_sensor',
    'flow_rate',
    'bme280',
    'bme680',
  ];

  @override
  void initState() {
    super.initState();
    _loadSensors();
  }

  Future<void> _loadSensors() async {
    setState(() => _isLoading = true);
    final sensors = await _databaseHelper.getZoneSensors(widget.zone.id!);
    setState(() {
      _sensors = sensors;
      _isLoading = false;
    });
  }

  Future<void> _addSensor() async {
    await _showSensorDialog();
  }

  Future<void> _editSensor(Sensor sensor) async {
    await _showSensorDialog(sensor: sensor);
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
      await _databaseHelper.deleteSensor(sensor.id);
      _loadSensors();
    }
  }

  Future<void> _showSensorDialog({Sensor? sensor}) async {
    final isEditing = sensor != null;
    final nameController = TextEditingController(text: sensor?.name ?? '');
    final addressController = TextEditingController(text: sensor?.address ?? '');
    final calibrationController = TextEditingController(text: sensor?.calibrationOffset.toString() ?? '0.0');
    final scaleController = TextEditingController(text: sensor?.scaleFactor.toString() ?? '1.0'); // NEW
    String selectedType = sensor?.sensorType ?? _sensorTypes.first;
    bool isEnabled = sensor?.enabled ?? true;
    
    // Hub Selection
    List<SensorHub> hubs = await _databaseHelper.getSensorHubs();
    int? selectedHubId = sensor?.hubId;
    
    // Channel Selection
    List<IoChannel> availableChannels = [];
    int? selectedChannelId = sensor?.inputChannel; 

    // Helper to load channels
    Future<List<IoChannel>> loadChannels(int hubId) async {
      final channels = await _databaseHelper.getIoChannelsByModule(hubId);
      // Filter based on selectedType
      return channels.where((c) {
        if (!c.isInput) return false;
        // Basic filtering logic
        if (selectedType == 'flow_rate' || selectedType == 'water_level') {
          return c.type == 'di';
        } else if (selectedType == 'ph_sensor' || selectedType == 'ec_sensor') {
          return c.type == 'ai_4_20ma' || c.type == 'i2c'; // Support both
        } else if (['bme280', 'bme680', 'light_sensor', 'co2_sensor', 'pressure_sensor'].contains(selectedType)) {
          return c.type == 'i2c';
        } else if (selectedType == 'soil_moisture') {
           return c.type == 'ai_4_20ma' || c.type == 'ao_0_10v'; // Some are analog
        }
        return true; // Allow all for others
      }).toList();
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Load channels if hub is selected
          if (selectedHubId != null && availableChannels.isEmpty) {
             _databaseHelper.getIoChannelsByModule(selectedHubId!).then((channels) {
               // Filter logic repeated or moved to helper
               final filtered = channels.where((c) {
                  if (!c.isInput) return false;
                  if (selectedType == 'flow_rate' || selectedType == 'water_level') return c.type == 'di';
                  if (['bme280', 'bme680', 'light_sensor', 'co2_sensor', 'pressure_sensor'].contains(selectedType)) return c.type == 'i2c';
                  return true;
               }).toList();
               
               if (context.mounted) {
                 setState(() => availableChannels = filtered);
               }
             });
          }

          return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            isEditing ? 'Edit Sensor' : 'Add Sensor',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VirtualKeyboardTextField(
                  controller: nameController,
                  label: 'Sensor Name',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Sensor Type',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  ),
                  items: _sensorTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.toUpperCase().replaceAll('_', ' ')),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                        selectedChannelId = null; // Reset channel on type change
                        availableChannels.clear(); // Force reload
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Hub Selection
                DropdownButtonFormField<int>(
                  value: selectedHubId,
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Connect to Hub',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  ),
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('None (Direct/GPIO)')),
                    ...hubs.map((h) => DropdownMenuItem(value: h.id, child: Text(h.name))),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedHubId = val;
                      selectedChannelId = null;
                      availableChannels.clear();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Channel Selection (Only if Hub selected)
                if (selectedHubId != null)
                  DropdownButtonFormField<int>(
                    value: selectedChannelId,
                    dropdownColor: Colors.grey[850],
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Hub Channel',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                    ),
                    items: availableChannels.map((c) {
                      return DropdownMenuItem(
                        value: c.channelNumber, // Storing channel number
                        child: Text('${c.name} (${c.type?.toUpperCase() ?? "Unknown"})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedChannelId = val),
                  ),

                if (selectedHubId == null) ...[
                  const SizedBox(height: 16),
                  VirtualKeyboardTextField(
                    controller: addressController,
                    label: 'Address (Optional)',
                    hintText: 'e.g., GPIO pin or I2C address',
                  ),
                ],
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: VirtualKeyboardTextField(
                        controller: scaleController,
                        label: 'Scale Factor',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: VirtualKeyboardTextField(
                        controller: calibrationController,
                        label: 'Offset',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enabled', style: TextStyle(color: Colors.white)),
                  value: isEnabled,
                  onChanged: (value) => setState(() => isEnabled = value),
                  activeColor: Colors.greenAccent,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;

                try {
                  final newSensor = Sensor(
                    id: isEditing ? sensor!.id : 0, // ID ignored on insert
                    zoneId: widget.zone.id!,
                    sensorType: selectedType,
                    name: nameController.text,
                    address: selectedHubId == null ? (addressController.text.isEmpty ? null : addressController.text) : null,
                    calibrationOffset: double.tryParse(calibrationController.text) ?? 0.0,
                    scaleFactor: double.tryParse(scaleController.text) ?? 1.0, // NEW
                    enabled: isEnabled,
                    hubId: selectedHubId,
                    inputChannel: selectedChannelId, // Storing channel number
                    createdAt: isEditing ? sensor!.createdAt : DateTime.now().millisecondsSinceEpoch ~/ 1000,
                    updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  );

                  if (isEditing) {
                    await _databaseHelper.updateSensor(newSensor);
                  } else {
                    await _databaseHelper.addSensor(newSensor);
                  }

                  // Refresh the list immediately so the user sees the new sensor
                  // even while the connector info dialog is open
                  _loadSensors();

                  if (mounted) {
                    Navigator.pop(context); // Close the add/edit dialog
                  }
                } catch (e) {
                  debugPrint('Error saving sensor: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving sensor: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
        }
      ),
    );
  }

  Map<String, String> _getConnectorInfo(String sensorType) {
    switch (sensorType) {
      case 'bme280':
      case 'bme680':
      case 'light_sensor':
      case 'co2_sensor':
      case 'pressure_sensor':
        return {
          'type': 'I2C Connector (JST-SH 4-pin)',
          'description': 'Use any available I2C port. Daisy-chaining is supported if addresses differ.',
        };
      case 'flow_rate':
        return {'type': 'GPIO', 'description': 'Connect to Digital Input pin'};
      case 'dht22':
      case 'soil_moisture':
      case 'water_level':
        return {
          'type': 'GPIO / Analog (JST-PH 3-pin)',
          'description': 'Connect to a GPIO or Analog port. Check pinout configuration.',
        };
      case 'ph_sensor':
      case 'ec_sensor':
        return {
          'type': 'I2C or Analog (Check Module)',
          'description': 'Most high-end modules use I2C (JST-SH), cheaper ones use Analog (JST-PH).',
        };
      default:
        return {
          'type': 'General Purpose IO',
          'description': 'Check sensor documentation for wiring details.',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('${widget.zone.name} Sensors'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSensor,
        backgroundColor: Colors.purpleAccent,
        child: const Icon(Icons.add),
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _sensors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sensors_off, size: 64, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No sensors configured',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sensors.length,
                      itemBuilder: (context, index) {
                        final sensor = _sensors[index];
                        final sensorColor = _getSensorColor(sensor.sensorType);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: sensor.enabled ? sensorColor.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                                    width: sensor.enabled ? 2 : 1,
                                  ),
                                ),
                                  child: ListTile(
                                    onTap: () => _editSensor(sensor),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: sensor.enabled ? sensorColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getSensorIcon(sensor.sensorType),
                                        color: sensor.enabled ? sensorColor : Colors.white38,
                                      ),
                                    ),
                                    title: Text(
                                      sensor.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sensor.sensorType.toUpperCase().replaceAll('_', ' '),
                                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                        ),
                                        if (sensor.address != null && sensor.address!.isNotEmpty)
                                          Text(
                                            'Addr: ${sensor.address}',
                                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.tune, color: Colors.blueAccent),
                                          tooltip: 'Calibrate',
                                          onPressed: () => _showCalibrationDialog(sensor),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                                          onPressed: () => _deleteSensor(sensor),
                                        ),
                                      ],
                                    ),
                                  ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Future<void> _showCalibrationDialog(Sensor sensor) async {
    final offsetController = TextEditingController(text: sensor.calibrationOffset.toString());
    final scaleController = TextEditingController(text: sensor.scaleFactor.toString());
    
    // Mock raw value for demonstration
    double rawValue = 50.0; 
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double offset = double.tryParse(offsetController.text) ?? 0.0;
          double scale = double.tryParse(scaleController.text) ?? 1.0;
          double calibrated = (rawValue * scale) + offset;

          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('Calibrate Sensor', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sensor: ${sensor.name}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Raw Value', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(rawValue.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 18)),
                          ],
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.white38),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Calibrated', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                            Text(calibrated.toStringAsFixed(2), style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  VirtualKeyboardTextField(
                    controller: scaleController,
                    label: 'Scale Factor (Slope)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  VirtualKeyboardTextField(
                    controller: offsetController,
                    label: 'Offset',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Formula: (Raw * Scale) + Offset',
                    style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final newSensor = sensor.copyWith(
                    calibrationOffset: double.tryParse(offsetController.text) ?? 0.0,
                    scaleFactor: double.tryParse(scaleController.text) ?? 1.0,
                  );
                  await _databaseHelper.updateSensor(newSensor);
                  _loadSensors();
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  Color _getSensorColor(String type) {
    switch (type) {
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
      case 'flow_rate':
        return Colors.cyan;
      default:
        return Colors.green;
    }
  }

  IconData _getSensorIcon(String type) {
    switch (type) {
      case 'dht22':
        return Icons.thermostat;
      case 'soil_moisture':
        return Icons.water_drop;
      case 'ph_sensor':
        return Icons.science;
      case 'light_sensor':
        return Icons.wb_sunny;
      case 'co2_sensor':
        return Icons.cloud;
      case 'bme280':
      case 'bme680':
        return Icons.thermostat_auto;
      case 'flow_rate':
        return Icons.waves;
      default:
        return Icons.sensors;
    }
  }
}
