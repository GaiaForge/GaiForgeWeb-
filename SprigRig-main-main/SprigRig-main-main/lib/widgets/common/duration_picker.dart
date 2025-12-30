import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DurationPicker extends StatefulWidget {
  final Duration initialDuration;
  final ValueChanged<Duration> onDurationChanged;

  const DurationPicker({
    super.key,
    required this.initialDuration,
    required this.onDurationChanged,
  });

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late int _selectedValue;
  late String _selectedUnit;
  final List<String> _units = ['Seconds', 'Minutes', 'Hours'];

  @override
  void initState() {
    super.initState();
    _calculateInitialValues();
  }

  void _calculateInitialValues() {
    if (widget.initialDuration.inHours > 0) {
      _selectedValue = widget.initialDuration.inHours;
      _selectedUnit = 'Hours';
    } else if (widget.initialDuration.inMinutes > 0) {
      _selectedValue = widget.initialDuration.inMinutes;
      _selectedUnit = 'Minutes';
    } else {
      _selectedValue = widget.initialDuration.inSeconds > 0 ? widget.initialDuration.inSeconds : 15;
      _selectedUnit = 'Seconds';
    }
  }

  void _updateDuration() {
    Duration newDuration;
    switch (_selectedUnit) {
      case 'Hours':
        newDuration = Duration(hours: _selectedValue);
        break;
      case 'Minutes':
        newDuration = Duration(minutes: _selectedValue);
        break;
      case 'Seconds':
      default:
        newDuration = Duration(seconds: _selectedValue);
        break;
    }
    widget.onDurationChanged(newDuration);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Value Picker
          Expanded(
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(initialItem: _selectedValue - 1),
              itemExtent: 40,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedValue = index + 1;
                  _updateDuration();
                });
              },
              children: List.generate(60, (index) {
                return Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                );
              }),
            ),
          ),
          // Unit Picker
          Expanded(
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(initialItem: _units.indexOf(_selectedUnit)),
              itemExtent: 40,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedUnit = _units[index];
                  _updateDuration();
                });
              },
              children: _units.map((unit) {
                return Center(
                  child: Text(
                    unit,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
