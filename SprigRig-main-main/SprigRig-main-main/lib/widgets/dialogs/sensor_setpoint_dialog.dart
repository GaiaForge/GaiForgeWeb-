import 'package:flutter/material.dart';
import '../../models/sensor.dart';
import '../common/gaia_num_pad.dart';

class SensorSetpointDialog extends StatefulWidget {
  final Sensor sensor;
  final Function(Sensor) onSave;

  const SensorSetpointDialog({
    super.key,
    required this.sensor,
    required this.onSave,
  });

  @override
  State<SensorSetpointDialog> createState() => _SensorSetpointDialogState();
}

class _SensorSetpointDialogState extends State<SensorSetpointDialog> {
  late bool _useSetpoint;
  late bool _useRange;
  
  // Values as strings to handle partial input (e.g. "1.")
  String _setpointValue = '';
  String _minValue = '';
  String _maxValue = '';
  
  // Track which field is active for input
  String _activeField = 'setpoint'; // 'setpoint', 'min', 'max'

  @override
  void initState() {
    super.initState();
    _useSetpoint = widget.sensor.useSetpoint;
    _useRange = widget.sensor.useRange;
    
    _setpointValue = widget.sensor.setpointValue?.toString() ?? '';
    _minValue = widget.sensor.minValue?.toString() ?? '';
    _maxValue = widget.sensor.maxValue?.toString() ?? '';
    
    // Set initial active field based on what's enabled
    if (_useSetpoint) {
      _activeField = 'setpoint';
    } else if (_useRange) {
      _activeField = 'min';
    } else {
      _activeField = 'none';
    }
  }

  void _handleKeyPress(String key) {
    if (_activeField == 'none') return;
    
    setState(() {
      if (_activeField == 'setpoint') {
        _setpointValue = _appendKey(_setpointValue, key);
      } else if (_activeField == 'min') {
        _minValue = _appendKey(_minValue, key);
      } else if (_activeField == 'max') {
        _maxValue = _appendKey(_maxValue, key);
      }
    });
  }
  
  String _appendKey(String current, String key) {
    if (key == '.' && current.contains('.')) return current;
    return current + key;
  }

  void _handleDelete() {
    if (_activeField == 'none') return;
    
    setState(() {
      if (_activeField == 'setpoint') {
        _setpointValue = _deleteChar(_setpointValue);
      } else if (_activeField == 'min') {
        _minValue = _deleteChar(_minValue);
      } else if (_activeField == 'max') {
        _maxValue = _deleteChar(_maxValue);
      }
    });
  }
  
  String _deleteChar(String current) {
    if (current.isEmpty) return current;
    return current.substring(0, current.length - 1);
  }
  
  void _handleClear() {
    if (_activeField == 'none') return;
    
    setState(() {
      if (_activeField == 'setpoint') {
        _setpointValue = '';
      } else if (_activeField == 'min') {
        _minValue = '';
      } else if (_activeField == 'max') {
        _maxValue = '';
      }
    });
  }

  void _save() {
    final setpoint = double.tryParse(_setpointValue);
    final minVal = double.tryParse(_minValue);
    final maxVal = double.tryParse(_maxValue);

    final updatedSensor = widget.sensor.copyWith(
      useSetpoint: _useSetpoint,
      useRange: _useRange,
      setpointValue: setpoint,
      minValue: minVal,
      maxValue: maxVal,
    );

    widget.onSave(updatedSensor);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(
        'Configure ${widget.sensor.name}',
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 340, // Fixed width for consistent layout
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Setpoint Configuration ---
              _buildSectionHeader('Target Setpoint', _useSetpoint, (val) {
                setState(() {
                  _useSetpoint = val;
                  if (val) _activeField = 'setpoint';
                });
              }),
              
              if (_useSetpoint)
                _buildValueDisplay(
                  label: 'Target Value',
                  value: _setpointValue,
                  isActive: _activeField == 'setpoint',
                  onTap: () => setState(() => _activeField = 'setpoint'),
                ),
                
              const SizedBox(height: 16),
              
              // --- Range Configuration ---
              _buildSectionHeader('Valid Range', _useRange, (val) {
                setState(() {
                  _useRange = val;
                  if (val && _activeField != 'min' && _activeField != 'max') {
                    _activeField = 'min';
                  }
                });
              }),
              
              if (_useRange)
                Row(
                  children: [
                    Expanded(
                      child: _buildValueDisplay(
                        label: 'Min',
                        value: _minValue,
                        isActive: _activeField == 'min',
                        onTap: () => setState(() => _activeField = 'min'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildValueDisplay(
                        label: 'Max',
                        value: _maxValue,
                        isActive: _activeField == 'max',
                        onTap: () => setState(() => _activeField = 'max'),
                      ),
                    ),
                  ],
                ),
                
              const SizedBox(height: 24),
              
              // --- Numeric Keypad ---
              if (_useSetpoint || _useRange)
                GaiaNumPad(
                  onKeyPressed: _handleKeyPress,
                  onDelete: _handleDelete,
                  onClear: _handleClear,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Save'),
        ),
      ],
    );
  }
  
  Widget _buildSectionHeader(String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.green,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
  
  Widget _buildValueDisplay({
    required String label,
    required String value,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              border: Border.all(
                color: isActive ? Colors.green : Colors.white24,
                width: isActive ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.isEmpty ? '--' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.white30 : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
