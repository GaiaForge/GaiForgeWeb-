import 'package:flutter/material.dart';
import '../../models/sensor.dart';
import '../../models/sensor_calibration.dart';
import '../../services/sensor_hub_service.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';

class SensorCalibrationScreen extends StatefulWidget {
  final Sensor sensor;

  const SensorCalibrationScreen({super.key, required this.sensor});

  @override
  State<SensorCalibrationScreen> createState() => _SensorCalibrationScreenState();
}

class _SensorCalibrationScreenState extends State<SensorCalibrationScreen> {
  final SensorHubService _hubService = SensorHubService();
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _referenceController = TextEditingController();
  
  List<SensorCalibration> _history = [];
  double _currentReading = 25.0; // Mock reading
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // Simulate live readings
    // In real app, subscribe to stream
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _db.getSensorCalibrations(widget.sensor.id);
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _calibrate() async {
    if (_referenceController.text.isEmpty) return;
    
    final reference = double.tryParse(_referenceController.text);
    if (reference == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid number')),
      );
      return;
    }

    await _hubService.calibrateSensor(widget.sensor.id, reference, _currentReading);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calibration applied!')),
    );
    
    _referenceController.clear();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calibrate ${widget.sensor.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Current Reading', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      '${_currentReading.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Offset:'),
                        Text(
                          '${widget.sensor.calibrationOffset > 0 ? '+' : ''}${widget.sensor.calibrationOffset.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Calibration Form
            const Text(
              'One-Point Calibration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the actual known value (reference) for this sensor. The system will calculate the offset.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: VirtualKeyboardTextField(
                    controller: _referenceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    label: 'Reference Value',
                    // suffixText: 'Units', // TODO: Get units from sensor type
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _calibrate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: const Text('Calibrate'),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // History
            const Text(
              'Calibration History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? const Text('No calibration history found.')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          return ListTile(
                            title: Text('Offset: ${item.offsetValue.toStringAsFixed(2)}'),
                            subtitle: Text(item.calibrationDate),
                            leading: const Icon(Icons.history),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
