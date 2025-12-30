// lib/widgets/cards/lighting/lighting_card.dart
import 'package:flutter/material.dart';
import '../base_control_card.dart';
import 'lighting_controls.dart';

class LightingCard extends BaseControlCard {
  final bool isLightOn;
  final int brightness; // 0-100
  final String schedule; // e.g., "Auto", "Manual", "Sunrise + 30min"
  final bool isScheduleActive;
  final VoidCallback? onToggle;
  final ValueChanged<int>? onBrightnessChanged;

  const LightingCard({
    super.key,
    required super.zoneId,
    required this.isLightOn,
    required this.brightness,
    required this.schedule,
    required this.isScheduleActive,
    this.onToggle,
    this.onBrightnessChanged,
    super.isCompact = false,
    super.onTap,
    super.onDetailTap,
  }) : super(
          title: 'Lighting',
          icon: Icons.lightbulb,
          color: Colors.yellow,
        );

  @override
  Widget buildContent(BuildContext context) {
    if (isCompact) {
      return _buildCompactContent(context);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status row
        Row(
          children: [
            Expanded(
              child: CardStatusIndicator(
                label: 'Status',
                value: isLightOn ? 'ON' : 'OFF',
                color: isLightOn ? Colors.green : Colors.grey,
                icon: isLightOn ? Icons.lightbulb : Icons.lightbulb_outline,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CardStatusIndicator(
                label: 'Brightness',
                value: '$brightness%',
                color: Colors.yellow,
                icon: Icons.brightness_6,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Schedule info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isScheduleActive
                ? Colors.blue.withValues(alpha:0.1)
                : Colors.grey.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isScheduleActive ? Colors.blue : Colors.grey,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isScheduleActive ? Icons.schedule : Icons.schedule_outlined,
                color: isScheduleActive ? Colors.blue : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  schedule,
                  style: TextStyle(
                    color: isScheduleActive ? Colors.blue : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isScheduleActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Quick controls
        Row(
          children: [
            Expanded(
              child: CardActionButton(
                label: isLightOn ? 'Turn Off' : 'Turn On',
                icon: isLightOn ? Icons.lightbulb_outline : Icons.lightbulb,
                color: isLightOn ? Colors.red : Colors.green,
                onPressed: onToggle,
                isSelected: isLightOn,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CardActionButton(
                label: 'Dim',
                icon: Icons.tune,
                color: Colors.yellow,
                onPressed: () => _showBrightnessSlider(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactContent(BuildContext context) {
    return const SizedBox.shrink(); // Content is handled by base class for compact mode
  }

  @override
  String getStatusText() {
    if (isLightOn) {
      return 'ON • $brightness%';
    } else {
      return 'OFF';
    }
  }

  @override
  Widget buildDetailScreen(BuildContext context) {
    return LightingDetailScreen(
      zoneId: zoneId,
      isLightOn: isLightOn,
      brightness: brightness,
      schedule: schedule,
      isScheduleActive: isScheduleActive,
      onToggle: onToggle,
      onBrightnessChanged: onBrightnessChanged,
    );
  }

  void _showBrightnessSlider(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BrightnessSliderSheet(
        currentBrightness: brightness,
        onChanged: onBrightnessChanged,
      ),
    );
  }
}

/// Brightness slider bottom sheet
class BrightnessSliderSheet extends StatefulWidget {
  final int currentBrightness;
  final ValueChanged<int>? onChanged;

  const BrightnessSliderSheet({
    super.key,
    required this.currentBrightness,
    this.onChanged,
  });

  @override
  State<BrightnessSliderSheet> createState() => _BrightnessSliderSheetState();
}

class _BrightnessSliderSheetState extends State<BrightnessSliderSheet> {
  late int _brightness;

  @override
  void initState() {
    super.initState();
    _brightness = widget.currentBrightness;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Adjust Brightness',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Brightness display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.brightness_6,
                color: Colors.yellow,
                size: 32,
              ),
              const SizedBox(width: 16),
              Text(
                '$_brightness%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.yellow,
              inactiveTrackColor: Colors.grey.shade700,
              thumbColor: Colors.yellow,
              overlayColor: Colors.yellow.withValues(alpha:0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _brightness.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _brightness = value.round();
                });
              },
              onChangeEnd: (value) {
                widget.onChanged?.call(value.round());
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick preset buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPresetButton('0%', 0),
              _buildPresetButton('25%', 25),
              _buildPresetButton('50%', 50),
              _buildPresetButton('75%', 75),
              _buildPresetButton('100%', 100),
            ],
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, int value) {
    final isSelected = _brightness == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _brightness = value;
        });
        widget.onChanged?.call(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            color: isSelected ? Colors.yellow : Colors.grey.shade300,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}