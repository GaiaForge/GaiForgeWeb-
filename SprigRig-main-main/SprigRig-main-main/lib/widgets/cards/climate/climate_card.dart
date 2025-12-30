// lib/widgets/cards/climate/climate_card.dart
import 'package:flutter/material.dart';
import '../base_control_card.dart';
import 'climate_detail_screen.dart';

class ClimateCard extends BaseControlCard {
  final bool isClimateControlActive;
  final double currentTemperature;
  final double currentHumidity;
  final double targetTempDay;
  final double targetTempNight;
  final double targetHumidity;
  final String mode; // 'manual', 'automatic', 'vpd-based'
  final bool heatingEnabled;
  final bool coolingEnabled;
  final VoidCallback? onToggle;
  final ValueChanged<double>? onTargetTempDayChanged;
  final ValueChanged<double>? onTargetTempNightChanged;
  final ValueChanged<double>? onTargetHumidityChanged;
  final ValueChanged<String>? onModeChanged;

  const ClimateCard({
    super.key,
    required super.zoneId,
    required this.isClimateControlActive,
    required this.currentTemperature,
    required this.currentHumidity,
    required this.targetTempDay,
    required this.targetTempNight,
    required this.targetHumidity,
    required this.mode,
    required this.heatingEnabled,
    required this.coolingEnabled,
    this.onToggle,
    this.onTargetTempDayChanged,
    this.onTargetTempNightChanged,
    this.onTargetHumidityChanged,
    this.onModeChanged,
    super.isCompact = false,
    super.onTap,
    super.onDetailTap,
  }) : super(
          title: 'Climate',
          icon: Icons.thermostat,
          color: Colors.orange,
        );

  @override
  bool get hasDetailScreen => true; // Has detail screen

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current conditions row
        Row(
          children: [
            Expanded(
              child: CardStatusIndicator(
                label: 'Temperature',
                value: '${currentTemperature.toStringAsFixed(1)}°C',
                color: _getTemperatureColor(currentTemperature),
                icon: Icons.thermostat,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CardStatusIndicator(
                label: 'Humidity',
                value: '${currentHumidity.toStringAsFixed(0)}%',
                color: _getHumidityColor(currentHumidity),
                icon: Icons.water_drop,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Status and target info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isClimateControlActive
                ? Colors.orange.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isClimateControlActive ? Colors.orange : Colors.grey,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _getModeIcon(mode),
                    color: isClimateControlActive ? Colors.orange : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getModeDisplayName(mode),
                      style: TextStyle(
                        color: isClimateControlActive ? Colors.orange : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    _getClimateStatus(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Target: ${_getCurrentTarget()}°C',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 10,
                    ),
                  ),
                  Row(
                    children: [
                      if (heatingEnabled) ...[
                        Icon(
                          Icons.whatshot,
                          color: Colors.red,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (coolingEnabled) ...[
                        Icon(
                          Icons.ac_unit,
                          color: Colors.blue,
                          size: 12,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const Spacer(),

        // Quick action buttons
        Row(
          children: [
            Expanded(
              child: CardActionButton(
                label: isClimateControlActive ? 'Stop' : 'Start',
                icon: isClimateControlActive ? Icons.stop : Icons.play_arrow,
                color: isClimateControlActive ? Colors.red : Colors.orange,
                onPressed: onToggle,
                isSelected: false,
              ),
            ),
            const SizedBox(width: 8),
            CardActionButton(
              label: 'Auto',
              icon: Icons.auto_mode,
              color: Colors.green,
              onPressed: () {
                // Quick auto mode
                onModeChanged?.call('automatic');
              },
              isSelected: mode == 'automatic',
            ),
          ],
        ),
      ],
    );
  }

  @override
  String getStatusText() {
    if (isClimateControlActive) {
      return '${currentTemperature.round()}°C • ${currentHumidity.round()}%';
    } else {
      return 'Inactive';
    }
  }

  @override
  Widget? buildDetailScreen(BuildContext context) {
    return ClimateDetailScreen(
      zoneId: zoneId,
      isClimateControlActive: isClimateControlActive,
      currentTemperature: currentTemperature,
      currentHumidity: currentHumidity,
      targetTempDay: targetTempDay,
      targetTempNight: targetTempNight,
      targetHumidity: targetHumidity,
      mode: mode,
      heatingEnabled: heatingEnabled,
      coolingEnabled: coolingEnabled,
      onToggle: onToggle,
      onTargetTempDayChanged: onTargetTempDayChanged,
      onTargetTempNightChanged: onTargetTempNightChanged,
      onTargetHumidityChanged: onTargetHumidityChanged,
      onModeChanged: onModeChanged,
    );
  }

  // Helper methods
  Color _getTemperatureColor(double temp) {
    if (temp < 18) return Colors.blue;
    if (temp < 22) return Colors.cyan;
    if (temp < 28) return Colors.green;
    if (temp < 32) return Colors.orange;
    return Colors.red;
  }

  Color _getHumidityColor(double humidity) {
    if (humidity < 40) return Colors.red;
    if (humidity < 50) return Colors.orange;
    if (humidity < 70) return Colors.green;
    if (humidity < 80) return Colors.yellow;
    return Colors.red;
  }

  Color _getStatusColor() {
    if (!isClimateControlActive) return Colors.grey;
    
    final tempOk = (currentTemperature >= targetTempDay - 2) && 
                   (currentTemperature <= targetTempDay + 2);
    final humidityOk = (currentHumidity >= targetHumidity - 10) && 
                       (currentHumidity <= targetHumidity + 10);
    
    if (tempOk && humidityOk) return Colors.green;
    if (tempOk || humidityOk) return Colors.yellow;
    return Colors.red;
  }

  String _getClimateStatus() {
    if (!isClimateControlActive) return 'Inactive';
    
    final tempOk = (currentTemperature >= targetTempDay - 2) && 
                   (currentTemperature <= targetTempDay + 2);
    final humidityOk = (currentHumidity >= targetHumidity - 10) && 
                       (currentHumidity <= targetHumidity + 10);
    
    if (tempOk && humidityOk) return 'Optimal';
    if (tempOk || humidityOk) return 'Adjusting';
    return 'Out of Range';
  }

  String _getCurrentTarget() {
    // Simple day/night logic - in real app, this would check actual time
    final hour = DateTime.now().hour;
    final isDayTime = hour >= 6 && hour < 22;
    return isDayTime ? targetTempDay.round().toString() : targetTempNight.round().toString();
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'manual': return Icons.touch_app;
      case 'automatic': return Icons.schedule;
      case 'vpd-based': return Icons.analytics;
      default: return Icons.settings;
    }
  }

  String _getModeDisplayName(String mode) {
    switch (mode) {
      case 'manual': return 'Manual';
      case 'automatic': return 'Auto';
      case 'vpd-based': return 'VPD';
      default: return mode;
    }
  }
}

