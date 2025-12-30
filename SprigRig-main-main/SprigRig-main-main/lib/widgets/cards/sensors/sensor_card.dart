// lib/widgets/cards/sensors/sensor_card.dart - UPDATED WITH DETAIL SCREEN
import 'package:flutter/material.dart';
import '../base_control_card.dart';
import 'sensor_detail_screen.dart';

class SensorCard extends BaseControlCard {
  final double temperature;
  final double humidity;
  final int soilMoisture;
  final double lightLevel;
  final String lastUpdate;
  final List<dynamic> recentReadings;
  final VoidCallback? onCalibrateTemperature;
  final VoidCallback? onCalibrateHumidity;
  final VoidCallback? onCalibrateSoilMoisture;
  final VoidCallback? onCalibrateLightLevel;
  final ValueChanged<Map<String, double>>? onThresholdsChanged;

  const SensorCard({
    super.key,
    required super.zoneId,
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.lightLevel,
    required this.lastUpdate,
    required this.recentReadings,
    this.onCalibrateTemperature,
    this.onCalibrateHumidity,
    this.onCalibrateSoilMoisture,
    this.onCalibrateLightLevel,
    this.onThresholdsChanged,
    super.isCompact = false,
    super.onTap,
    super.onDetailTap,
  }) : super(
          title: 'Sensors',
          icon: Icons.sensors,
          color: Colors.blue,
        );

  @override
  bool get hasDetailScreen => true; // Now has detail screen

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary readings row
        Row(
          children: [
            Expanded(
              child: CardStatusIndicator(
                label: 'Temperature',
                value: '${temperature.toStringAsFixed(1)}°C',
                color: _getTemperatureColor(temperature),
                icon: Icons.thermostat,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CardStatusIndicator(
                label: 'Humidity',
                value: '${humidity.toStringAsFixed(0)}%',
                color: _getHumidityColor(humidity),
                icon: Icons.water_drop,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Secondary readings and status
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMiniReading(
                      'Soil',
                      '$soilMoisture%',
                      Icons.grass,
                      _getSoilMoistureColor(soilMoisture.toDouble()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniReading(
                      'Light',
                      '${lightLevel.toStringAsFixed(0)} lux',
                      Icons.wb_sunny,
                      _getLightLevelColor(lightLevel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.grey.shade400,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Updated: $lastUpdate',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                label: 'Calibrate',
                icon: Icons.tune,
                color: Colors.orange,
                onPressed: () {
                  // Quick calibration action
                  if (onDetailTap != null) onDetailTap!();
                },
                isSelected: false,
              ),
            ),
            const SizedBox(width: 8),
            CardActionButton(
              label: 'Export',
              icon: Icons.download,
              color: Colors.green,
              onPressed: () {
                // Quick export action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exporting sensor data...'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              isSelected: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniReading(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 9,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  String getStatusText() {
    return '${temperature.round()}°C • ${humidity.round()}%';
  }

  @override
  Widget? buildDetailScreen(BuildContext context) {
    return SensorDetailScreen(
      zoneId: zoneId,
      temperature: temperature,
      humidity: humidity,
      soilMoisture: soilMoisture,
      lightLevel: lightLevel,
      lastUpdate: lastUpdate,
      recentReadings: recentReadings,
      onCalibrateTemperature: onCalibrateTemperature,
      onCalibrateHumidity: onCalibrateHumidity,
      onCalibrateSoilMoisture: onCalibrateSoilMoisture,
      onCalibrateLightLevel: onCalibrateLightLevel,
      onThresholdsChanged: onThresholdsChanged,
    );
  }

  // Helper methods for color coding
  Color _getTemperatureColor(double temp) {
    if (temp < 15) return Colors.blue;
    if (temp < 20) return Colors.cyan;
    if (temp < 25) return Colors.green;
    if (temp < 30) return Colors.orange;
    return Colors.red;
  }

  Color _getHumidityColor(double humidity) {
    if (humidity < 30) return Colors.red;
    if (humidity < 50) return Colors.orange;
    if (humidity < 70) return Colors.green;
    if (humidity < 85) return Colors.yellow;
    return Colors.red;
  }

  Color _getSoilMoistureColor(double moisture) {
    if (moisture < 20) return Colors.red;
    if (moisture < 40) return Colors.orange;
    if (moisture < 70) return Colors.green;
    return Colors.blue;
  }

  Color _getLightLevelColor(double light) {
    if (light < 200) return Colors.indigo;
    if (light < 400) return Colors.blue;
    if (light < 600) return Colors.green;
    if (light < 800) return Colors.yellow;
    return Colors.orange;
  }
}
