// lib/widgets/cards/lighting/lighting_controls.dart
import 'package:flutter/material.dart';
import '../../common/base_card.dart';

/// Detailed lighting control screen
class LightingDetailScreen extends StatefulWidget {
  final int zoneId;
  final bool isLightOn;
  final int brightness;
  final String schedule;
  final bool isScheduleActive;
  final VoidCallback? onToggle;
  final ValueChanged<int>? onBrightnessChanged;

  const LightingDetailScreen({
    super.key,
    required this.zoneId,
    required this.isLightOn,
    required this.brightness,
    required this.schedule,
    required this.isScheduleActive,
    this.onToggle,
    this.onBrightnessChanged,
  });

  @override
  State<LightingDetailScreen> createState() => _LightingDetailScreenState();
}

class _LightingDetailScreenState extends State<LightingDetailScreen> {
  late bool _isLightOn;
  late int _brightness;
  String _selectedScheduleType = 'manual';
  TimeOfDay _onTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _offTime = const TimeOfDay(hour: 22, minute: 0);
  int _sunriseOffset = 0; // minutes
  int _sunsetOffset = 0; // minutes

  @override
  void initState() {
    super.initState();
    _isLightOn = widget.isLightOn;
    _brightness = widget.brightness;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // slate-900
              Color(0xFF1E3A8A), // blue-900
              Color(0xFF1E293B), // slate-800
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildBrightnessCard(),
                      const SizedBox(height: 16),
                      _buildScheduleCard(),
                      const SizedBox(height: 16),
                      _buildStatsCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.yellow, Colors.orange],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Lighting Control',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Light Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isLightOn 
                      ? Colors.green.withValues(alpha:0.2)
                      : Colors.grey.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isLightOn ? Colors.green : Colors.grey,
                  ),
                ),
                child: Text(
                  _isLightOn ? 'ON' : 'OFF',
                  style: TextStyle(
                    color: _isLightOn ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Large toggle button
          GestureDetector(
            onTap: () {
              setState(() {
                _isLightOn = !_isLightOn;
              });
              widget.onToggle?.call();
            },
            child: Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isLightOn
                      ? [Colors.yellow, Colors.orange]
                      : [Colors.grey.shade700, Colors.grey.shade800],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isLightOn ? [
                  BoxShadow(
                    color: Colors.yellow.withValues(alpha:0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ] : null,
              ),
              child: Icon(
                _isLightOn ? Icons.lightbulb : Icons.lightbulb_outline,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrightnessCard() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Brightness',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$_brightness%',
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Brightness slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.yellow,
              inactiveTrackColor: Colors.grey.shade700,
              thumbColor: Colors.yellow,
              overlayColor: Colors.yellow.withValues(alpha:0.2),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: _brightness.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: _isLightOn ? (value) {
                setState(() {
                  _brightness = value.round();
                });
              } : null,
              onChangeEnd: (value) {
                widget.onBrightnessChanged?.call(value.round());
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Preset buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBrightnessPreset('Low', 25),
              _buildBrightnessPreset('Medium', 50),
              _buildBrightnessPreset('High', 75),
              _buildBrightnessPreset('Max', 100),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrightnessPreset(String label, int value) {
    final isSelected = _brightness == value;
    
    return GestureDetector(
      onTap: _isLightOn ? () {
        setState(() {
          _brightness = value;
        });
        widget.onBrightnessChanged?.call(value);
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow.withValues(alpha:0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.yellow : Colors.grey.shade600,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _isLightOn 
                ? (isSelected ? Colors.yellow : Colors.grey.shade300)
                : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Light Schedule',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Schedule type selector
          Row(
            children: [
              _buildScheduleTab('Manual', 'manual'),
              _buildScheduleTab('Timer', 'timer'),
              _buildScheduleTab('Astral', 'astral'),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Schedule configuration
          _buildScheduleConfig(),
        ],
      ),
    );
  }

  Widget _buildScheduleTab(String label, String type) {
    final isSelected = _selectedScheduleType == type;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedScheduleType = type;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withValues(alpha:0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleConfig() {
    switch (_selectedScheduleType) {
      case 'manual':
        return _buildManualConfig();
      case 'timer':
        return _buildTimerConfig();
      case 'astral':
        return _buildAstralConfig();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildManualConfig() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha:0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.touch_app, color: Colors.grey, size: 20),
          SizedBox(width: 12),
          Text(
            'Lights controlled manually only',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerConfig() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTimeSelector(
                'Turn On',
                _onTime,
                (time) => setState(() => _onTime = time),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeSelector(
                'Turn Off',
                _offTime,
                (time) => setState(() => _offTime = time),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lights will turn on at ${_onTime.format(context)} and off at ${_offTime.format(context)} daily',
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAstralConfig() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOffsetSelector(
                'Sunrise Offset',
                _sunriseOffset,
                (offset) => setState(() => _sunriseOffset = offset),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOffsetSelector(
                'Sunset Offset',
                _sunsetOffset,
                (offset) => setState(() => _sunsetOffset = offset),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.wb_sunny, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lights follow sunrise/sunset with your custom offsets',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return GestureDetector(
      onTap: () async {
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (selectedTime != null) {
          onChanged(selectedTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withValues(alpha:0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade600),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffsetSelector(String label, int offset, ValueChanged<int> onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha:0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: () => onChanged(offset - 15),
                icon: const Icon(Icons.remove, color: Colors.white, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
              Expanded(
                child: Text(
                  offset == 0 
                      ? 'Exact time'
                      : '${offset > 0 ? '+' : ''}${offset}min',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onChanged(offset + 15),
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usage Statistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Today',
                  '8.5h',
                  Icons.today,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'This Week',
                  '42h',
                  Icons.calendar_view_week,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Energy',
                  '2.4 kWh',
                  Icons.flash_on,
                  Colors.yellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}