// lib/widgets/cards/hvac/hvac_card.dart
import 'package:flutter/material.dart';
import '../base_control_card.dart';
import 'hvac_detail_screen.dart';

class HvacCard extends BaseControlCard {
  final bool isFanRunning;
  final int fanSpeed; // 0-100%
  final String mode; // 'manual', 'automatic', 'temperature-based'
  final double targetTemperature;
  final String schedule;
  final VoidCallback? onToggle;
  final ValueChanged<int>? onSpeedChanged;
  final ValueChanged<String>? onModeChanged;
  final ValueChanged<double>? onTargetTempChanged;

  const HvacCard({
    super.key,
    required super.zoneId,
    required this.isFanRunning,
    required this.fanSpeed,
    required this.mode,
    required this.targetTemperature,
    required this.schedule,
    this.onToggle,
    this.onSpeedChanged,
    this.onModeChanged,
    this.onTargetTempChanged,
    super.isCompact = false,
    super.onTap,
    super.onDetailTap,
  }) : super(
          title: 'HVAC',
          icon: Icons.air,
          color: Colors.purple,
        );

  @override
  bool get hasDetailScreen => true; // Has detail screen

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status and speed row
        Row(
          children: [
            Expanded(
              child: CardStatusIndicator(
                label: 'Fan Status',
                value: isFanRunning ? 'RUNNING' : 'STOPPED',
                color: isFanRunning ? Colors.green : Colors.grey,
                icon: isFanRunning ? Icons.air : Icons.stop_circle_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CardStatusIndicator(
                label: 'Speed',
                value: '$fanSpeed%',
                color: _getSpeedColor(fanSpeed),
                icon: Icons.speed,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Mode and airflow info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFanRunning
                ? Colors.purple.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFanRunning ? Colors.purple : Colors.grey,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _getModeIcon(mode),
                    color: isFanRunning ? Colors.purple : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getModeDisplayName(mode),
                      style: TextStyle(
                        color: isFanRunning ? Colors.purple : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    _getAirflowRate(fanSpeed),
                    style: TextStyle(
                      color: isFanRunning ? Colors.purple : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (mode == 'temperature-based') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.thermostat,
                      color: Colors.grey.shade400,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Target: ${targetTemperature.round()}°C',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
              if (schedule.isNotEmpty && mode == 'automatic') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.grey.shade400,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      schedule,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const Spacer(),

        // Quick action buttons
        Row(
          children: [
            Expanded(
              child: CardActionButton(
                label: isFanRunning ? 'Stop' : 'Start',
                icon: isFanRunning ? Icons.stop : Icons.play_arrow,
                color: isFanRunning ? Colors.red : Colors.purple,
                onPressed: onToggle,
                isSelected: false,
              ),
            ),
            const SizedBox(width: 8),
            CardActionButton(
              label: 'Fresh Air',
              icon: Icons.air,
              color: Colors.cyan,
              onPressed: () {
                // Quick fresh air cycle
                debugPrint('Fresh air cycle triggered');
              },
              isSelected: false,
            ),
          ],
        ),
      ],
    );
  }

  @override
  String getStatusText() {
    if (isFanRunning) {
      return 'Running • $fanSpeed%';
    } else {
      return 'Stopped';
    }
  }

  @override
  Widget? buildDetailScreen(BuildContext context) {
    return HvacDetailScreen(
      zoneId: zoneId,
      isFanRunning: isFanRunning,
      fanSpeed: fanSpeed,
      mode: mode,
      targetTemperature: targetTemperature,
      schedule: schedule,
      onToggle: onToggle,
      onSpeedChanged: onSpeedChanged,
      onModeChanged: onModeChanged,
      onTargetTempChanged: onTargetTempChanged,
    );
  }

  Color _getSpeedColor(int speed) {
    if (speed >= 80) return Colors.red;
    if (speed >= 60) return Colors.orange;
    if (speed >= 40) return Colors.yellow;
    if (speed >= 20) return Colors.green;
    return Colors.grey;
  }

  String _getAirflowRate(int speed) {
    if (speed == 0) return '0 CFM';
    final cfm = (speed * 2.5).round(); // Mock calculation
    return '$cfm CFM';
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'manual': return Icons.touch_app;
      case 'automatic': return Icons.schedule;
      case 'temperature-based': return Icons.thermostat;
      default: return Icons.settings;
    }
  }

  String _getModeDisplayName(String mode) {
    switch (mode) {
      case 'manual': return 'Manual';
      case 'automatic': return 'Scheduled';
      case 'temperature-based': return 'Auto Temp';
      default: return mode;
    }
  }
}
