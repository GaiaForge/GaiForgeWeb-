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

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getReadingIcon(), size: 28, color: _getReadingColor()),
            const SizedBox(height: 8),
            Text(
              _getReadingName(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (latestReading != null)
              Text(
                _formatValue(latestReading.value),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getReadingColor(),
                ),
              )
            else
              const Text(
                'No data',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 4),
            if (averageValue != null && sortedReadings.length > 1)
              Text(
                'Avg: ${_formatValue(averageValue, true)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            if (latestReading != null)
              Text(
                _formatTimestamp(latestReading.timestamp),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
          ],
        ),
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
        return 'pH';
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
        return Colors.red.shade700;
      case 'humidity':
        return Colors.blue.shade700;
      case 'pressure':
        return Colors.purple.shade700;
      case 'moisture':
        return Colors.blue.shade800;
      case 'ph':
        return Colors.green.shade700;
      case 'ec':
        return Colors.orange.shade700;
      case 'light_intensity':
        return Colors.amber.shade700;
      case 'water_level':
        return Colors.cyan.shade700;
      default:
        return Colors.grey.shade700;
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
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // If it's yesterday, show "Yesterday"
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // Otherwise show the full date
    return '${date.month}/${date.day}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
