import 'package:flutter/material.dart';
import '../../models/sensor_hub.dart';
import '../../models/sensor.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';

class AddSensorWizard extends StatefulWidget {
  final SensorHub hub;
  final int channel;

  const AddSensorWizard({super.key, required this.hub, required this.channel});

  @override
  State<AddSensorWizard> createState() => _AddSensorWizardState();
}

class _AddSensorWizardState extends State<AddSensorWizard> {
  final DatabaseHelper _db = DatabaseHelper();
  int _currentStep = 0;
  
  // Form Data
  String? _inputType;
  String? _sensorType;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController(); // I2C address or similar
  
  // Available Options
  final List<Map<String, dynamic>> _inputTypes = [
    {'id': 'i2c', 'name': 'I2C Digital', 'icon': Icons.memory},
    {'id': 'spi', 'name': 'SPI Digital', 'icon': Icons.cable},
    {'id': 'analog_0_10v', 'name': 'Analog 0-10V', 'icon': Icons.speed},
    {'id': 'analog_4_20ma', 'name': 'Analog 4-20mA', 'icon': Icons.electric_meter},
  ];

  final Map<String, List<String>> _sensorTypesByInput = {
    'i2c': ['dht22', 'bme280', 'tsl2561', 'ads1115'],
    'spi': ['max31865', 'mcp3008'],
    'analog_0_10v': ['ph_sensor', 'ec_sensor', 'pressure_sensor'],
    'analog_4_20ma': ['water_level', 'co2_sensor'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Sensor - Channel ${widget.channel}'),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                if (_currentStep < 2)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Next'),
                  )
                else
                  ElevatedButton(
                    onPressed: _saveSensor,
                    child: const Text('Save Sensor'),
                  ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Input Type'),
            content: _buildInputTypeSelection(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Sensor Type'),
            content: _buildSensorTypeSelection(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Configure'),
            content: _buildConfigurationForm(),
            isActive: _currentStep >= 2,
            state: _currentStep == 2 ? StepState.editing : StepState.indexed,
          ),
        ],
      ),
    );
  }

  Widget _buildInputTypeSelection() {
    return Column(
      children: _inputTypes.map((type) {
        final isSelected = _inputType == type['id'];
        return Card(
          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
          child: ListTile(
            leading: Icon(type['icon'], color: isSelected ? Colors.blue : Colors.grey),
            title: Text(type['name']),
            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
            onTap: () {
              setState(() {
                _inputType = type['id'];
                _sensorType = null; // Reset sensor type
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSensorTypeSelection() {
    if (_inputType == null) return const Text('Please select an input type first.');
    
    final types = _sensorTypesByInput[_inputType] ?? [];
    
    return Column(
      children: types.map((type) {
        final isSelected = _sensorType == type;
        return Card(
          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
          child: ListTile(
            title: Text(type.toUpperCase().replaceAll('_', ' ')),
            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
            onTap: () {
              setState(() => _sensorType = type);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfigurationForm() {
    return Column(
      children: [
        VirtualKeyboardTextField(
          controller: _nameController,
          label: 'Sensor Name',
          textColor: Colors.black,
        ),
        const SizedBox(height: 16),
        if (_inputType == 'i2c')
          VirtualKeyboardTextField(
            controller: _addressController,
            label: 'I2C Address (e.g., 0x48)',
            textColor: Colors.black,
          ),
      ],
    );
  }

  void _nextStep() {
    if (_currentStep == 0 && _inputType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an input type')),
      );
      return;
    }
    if (_currentStep == 1 && _sensorType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a sensor type')),
      );
      return;
    }
    
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveSensor() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a sensor name')),
      );
      return;
    }

    try {
      final newSensor = Sensor(
        id: 0,
        zoneId: widget.hub.zoneId ?? 1, // Default to zone 1 if hub not assigned
        sensorType: _sensorType!,
        name: _nameController.text,
        hubId: widget.hub.id,
        inputChannel: widget.channel,
        inputType: _inputType,
        i2cAddress: _addressController.text.isNotEmpty ? _addressController.text : null,
        enabled: true,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      await _db.addSensor(newSensor);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving sensor: $e')),
      );
    }
  }
}
