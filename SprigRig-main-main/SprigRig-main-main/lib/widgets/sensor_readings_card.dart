import 'package:flutter/material.dart';
import '../models/sensor.dart';

class SensorReadingCard extends StatelessWidget {
  final String readingType;
  final List<SensorReading> readings;

  const SensorReadingCard({
    super.key,
    required this.readingType,
    required this.readings,
  });

  @override
  Widget build(BuildContext context) {
    // Sort readings by timestamp (newest first)
    final sortedReadings = List<SensorReading>.from(readings)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Get the newest reading
    final latestReading =
        sortedReadings.isNotEmpty ? sortedReadings.first : null;

    // Calculate average value
    double? averageValue;
    if (sortedReadings.isNotEmpty) {
      final sum = sortedReadings.fold<double>(
        0,
        (sum, reading) => sum + reading.value,
      );
      averageValue = sum / sortedReadings.length;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade700.withValues(alpha: .5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon and label row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _getReadingGradient()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getReadingIcon(), size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getReadingName(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Main value
          if (latestReading != null)
            Text(
              _formatValue(latestReading.value),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getReadingColor(),
              ),
            )
          else
            Text(
              'No data',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade400,
              ),
            ),

          const SizedBox(height: 8),

          // Average and timestamp info
          if (latestReading != null) ...[
            if (averageValue != null && sortedReadings.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade700.withValues(alpha: .4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Avg: ${_formatValue(averageValue, true)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade300,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 6),

            Text(
              _formatTimestamp(latestReading.timestamp),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],

          // Data points indicator
          if (sortedReadings.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timeline, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${sortedReadings.length} readings',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getReadingName() {
    switch (readingType) {
      case 'temperature':
        return 'Temperature';
      case 'humidity':
        return 'Humidity';
      case 'pressure':
        return 'Pressure';
      case 'moisture':
        return 'Soil Moisture';
      case 'ph':
        return 'pH Level';
      case 'ec':
        return 'EC';
      case 'light_intensity':
        return 'Light';
      case 'water_level':
        return 'Water Level';
      default:
        return readingType
            .split('_')
            .map(
              (word) => word.substring(0, 1).toUpperCase() + word.substring(1),
            )
            .join(' ');
    }
  }

  IconData _getReadingIcon() {
    switch (readingType) {
      case 'temperature':
        return Icons.thermostat_outlined;
      case 'humidity':
        return Icons.water_drop_outlined;
      case 'pressure':
        return Icons.speed_outlined;
      case 'moisture':
        return Icons.water_outlined;
      case 'ph':
        return Icons.science_outlined;
      case 'ec':
        return Icons.bolt_outlined;
      case 'light_intensity':
        return Icons.light_mode_outlined;
      case 'water_level':
        return Icons.height_outlined;
      default:
        return Icons.sensors_outlined;
    }
  }

  Color _getReadingColor() {
    switch (readingType) {
      case 'temperature':
        return Colors.red.shade400;
      case 'humidity':
        return Colors.blue.shade400;
      case 'pressure':
        return Colors.purple.shade400;
      case 'moisture':
        return Colors.blue.shade600;
      case 'ph':
        return Colors.green.shade400;
      case 'ec':
        return Colors.orange.shade400;
      case 'light_intensity':
        return Colors.amber.shade400;
      case 'water_level':
        return Colors.cyan.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  List<Color> _getReadingGradient() {
    switch (readingType) {
      case 'temperature':
        return [Colors.red.shade400, Colors.orange.shade500];
      case 'humidity':
        return [Colors.blue.shade400, Colors.cyan.shade500];
      case 'pressure':
        return [Colors.purple.shade400, Colors.indigo.shade500];
      case 'moisture':
        return [Colors.blue.shade600, Colors.blue.shade400];
      case 'ph':
        return [Colors.green.shade400, Colors.teal.shade500];
      case 'ec':
        return [Colors.orange.shade400, Colors.yellow.shade500];
      case 'light_intensity':
        return [Colors.amber.shade400, Colors.yellow.shade300];
      case 'water_level':
        return [Colors.cyan.shade400, Colors.blue.shade300];
      default:
        return [Colors.grey.shade400, Colors.grey.shade600];
    }
  }

  String _formatValue(double value, [bool isAverage = false]) {
    // Format the value with the appropriate unit and precision
    switch (readingType) {
      case 'temperature':
        return '${value.toStringAsFixed(1)}°C';
      case 'humidity':
        return '${value.toStringAsFixed(isAverage ? 1 : 0)}%';
      case 'pressure':
        return '${value.toStringAsFixed(0)} hPa';
      case 'moisture':
        return '${value.toStringAsFixed(isAverage ? 1 : 0)}%';
      case 'ph':
        return value.toStringAsFixed(1);
      case 'ec':
        return '${value.toStringAsFixed(0)} μS/cm';
      case 'light_intensity':
        return '${value.toStringAsFixed(0)} lux';
      case 'water_level':
        return '${value.toStringAsFixed(isAverage ? 1 : 0)}%';
      default:
        return value.toStringAsFixed(1);
    }
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();

    // If it's today, just show the time
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // If it's yesterday, show "Yesterday"
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // Otherwise show the full date
    return '${date.month}/${date.day}/${date.year}';
  }
}
