import 'package:flutter/material.dart';
import '../../animated_status_icons.dart';
import '../glass_card.dart';

class SeedlingMatTile extends StatelessWidget {
  final bool isActive;
  final double? currentTemp;
  final double targetTemp;
  final String mode; // 'manual', 'thermostat', 'scheduled'
  final bool autoOffEnabled;
  final int? daysRemaining;
  final bool sensorError;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;

  const SeedlingMatTile({
    super.key,
    required this.isActive,
    this.currentTemp,
    required this.targetTemp,
    required this.mode,
    required this.autoOffEnabled,
    this.daysRemaining,
    required this.sensorError,
    this.onTap,
    this.onToggle,
  });

  Color get _statusColor {
    if (sensorError) return Colors.red;
    if (!isActive) return Colors.grey;
    if (currentTemp == null) return Colors.orange;
    if ((currentTemp! - targetTemp).abs() <= 1.0) return Colors.green;
    return Colors.orange;
  }

  String get _statusText {
    if (sensorError) return 'Sensor Error';
    if (!isActive) return 'Off';
    if (currentTemp == null) return 'No Reading';
    if (currentTemp! < targetTemp - 1.0) return 'Heating';
    if (currentTemp! > targetTemp + 1.0) return 'Cooling';
    return 'At Target';
  }

  String _formatMode(String mode) {
    if (mode.isEmpty) return '';
    return mode[0].toUpperCase() + mode.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SeedlingMatStatusIcon(
                          isActive: isActive,
                          color: _statusColor == Colors.grey ? Colors.orange : _statusColor, // Use orange when active but not at target, or grey when off
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Seedling Mat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (onToggle != null)
                      GestureDetector(
                        onTap: onToggle,
                        child: Text(
                          isActive ? '[ON]' : '[OFF]',
                          style: TextStyle(
                            color: isActive ? Colors.cyanAccent : Colors.white38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12), // Reduced from 16

                // Temperature Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current:', style: TextStyle(color: Colors.white70)),
                    Text(
                      currentTemp != null ? '${currentTemp!.toStringAsFixed(1)}°C' : '--',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Target:', style: TextStyle(color: Colors.white70)),
                    Text(
                      '${targetTemp.toStringAsFixed(1)}°C',
                      style: TextStyle(color: _statusColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Reduced from 12

                // Temperature Indicator
                _buildTemperatureIndicator(),
                
                const SizedBox(height: 8), // Reduced from 12
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),

                // Mode
                _InfoRow(
                  label: 'Mode',
                  value: _formatMode(mode),
                  valueColor: Colors.white70,
                ),

                // Auto-off countdown (if enabled)
                if (autoOffEnabled && daysRemaining != null) ...[
                  const SizedBox(height: 4),
                  _InfoRow(
                    label: 'Auto-off',
                    value: '$daysRemaining days left',
                    valueColor: daysRemaining! <= 2 ? Colors.orange : Colors.white70,
                  ),
                ],
                
                // Status Text (if active)
                if (isActive) ...[
                  const SizedBox(height: 4),
                  _InfoRow(
                    label: 'Status',
                    value: _statusText,
                    valueColor: _statusColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemperatureIndicator() {
    // Visual bar showing current temp position relative to target
    // Range: target - 5°C to target + 5°C
    final minTemp = targetTemp - 5;
    final maxTemp = targetTemp + 5;
    
    double? position;
    if (currentTemp != null) {
      position = ((currentTemp! - minTemp) / (maxTemp - minTemp)).clamp(0.0, 1.0);
    } else {
      position = 0.5; // Default to center if no reading
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.green, Colors.orange, Colors.red],
              stops: [0.0, 0.4, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Target marker (center)
              Positioned(
                left: (0.5 * constraints.maxWidth) - 2,
                child: Container(width: 4, height: 8, color: Colors.white),
              ),
              // Current position marker
              if (currentTemp != null)
                Positioned(
                  left: (position! * constraints.maxWidth) - 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _statusColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 12)),
      ],
    );
  }
}
