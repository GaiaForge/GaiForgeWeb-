import 'package:flutter/material.dart';
import '../../models/sensor_hub.dart';
import '../../models/sensor.dart';
import '../../services/database_helper.dart';
import 'add_sensor_wizard.dart';
import 'sensor_calibration_screen.dart';

class HubDetailScreen extends StatefulWidget {
  final SensorHub hub;

  const HubDetailScreen({super.key, required this.hub});

  @override
  State<HubDetailScreen> createState() => _HubDetailScreenState();
}

class _HubDetailScreenState extends State<HubDetailScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Sensor> _sensors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSensors();
  }

  Future<void> _loadSensors() async {
    setState(() => _isLoading = true);
    final sensors = await _db.getSensorsByHub(widget.hub.id);
    setState(() {
      _sensors = sensors;
      _isLoading = false;
    });
  }

  Sensor? _getSensorForChannel(int channel) {
    try {
      return _sensors.firstWhere((s) => s.inputChannel == channel);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hub.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Hub settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: ${widget.hub.status.toUpperCase()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.hub.status == 'online' ? Colors.green : Colors.red,
                      ),
                    ),
                    Text('Address: ${widget.hub.modbusAddress}'),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Show diagnostics screen
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text('Diagnostics'),
                ),
              ],
            ),
          ),
          
          // Channels Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: 8, // Fixed 8 channels for now
                    itemBuilder: (context, index) {
                      final channelNum = index + 1;
                      final sensor = _getSensorForChannel(channelNum);
                      return _buildChannelCard(channelNum, sensor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelCard(int channelNum, Sensor? sensor) {
    final isOccupied = sensor != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isOccupied ? Colors.white : Colors.grey[100],
      child: InkWell(
        onTap: () async {
          if (isOccupied) {
            // Edit/Calibrate existing sensor
             await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SensorCalibrationScreen(sensor: sensor),
              ),
            );
          } else {
            // Add new sensor
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddSensorWizard(hub: widget.hub, channel: channelNum),
              ),
            );
          }
          _loadSensors();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isOccupied ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$channelNum',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOccupied ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (isOccupied) ...[
                Text(
                  sensor.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  sensor.sensorType.toUpperCase(),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                // Placeholder for live reading
                Text(
                  '-- ${sensor.getSupportedReadingTypes().first}', // Mock reading
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ] else ...[
                const Icon(Icons.add, color: Colors.grey, size: 32),
                const Text('Empty', style: TextStyle(color: Colors.grey)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
