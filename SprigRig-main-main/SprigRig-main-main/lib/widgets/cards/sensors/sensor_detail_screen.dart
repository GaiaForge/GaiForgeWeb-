// lib/widgets/cards/sensors/sensor_detail_screen.dart
import 'package:flutter/material.dart';

class SensorDetailScreen extends StatefulWidget {
  final int zoneId;
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

  const SensorDetailScreen({
    super.key,
    required this.zoneId,
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
  });

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  late double _tempMin;
  late double _tempMax;
  late double _humidityMin;
  late double _humidityMax;
  late double _soilMoistureMin;
  late double _soilMoistureMax;
  late double _lightMin;
  late double _lightMax;
  
  String _selectedTimeRange = '24 hours';
  bool _alertsEnabled = true;
  
  final List<String> _timeRanges = ['1 hour', '6 hours', '24 hours', '7 days', '30 days'];

  @override
  void initState() {
    super.initState();
    // Initialize default thresholds
    _tempMin = 18.0;
    _tempMax = 28.0;
    _humidityMin = 40.0;
    _humidityMax = 80.0;
    _soilMoistureMin = 30.0;
    _soilMoistureMax = 80.0;
    _lightMin = 200.0;
    _lightMax = 800.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // slate-900
            Color(0xFF3B82F6), // blue-500
            Color(0xFF1E293B), // slate-800
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.blueAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sensors, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Sensor Monitoring',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCurrentReadingsCard(),
                  const SizedBox(height: 16),
                  _buildHistoricalChartsCard(),
                  const SizedBox(height: 16),
                  _buildAlertThresholdsCard(),
                  const SizedBox(height: 16),
                  _buildCalibrationCard(),
                  const SizedBox(height: 16),
                  _buildDataExportCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentReadingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Current Readings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Sensor readings grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildSensorReading(
                'Temperature',
                '${widget.temperature.toStringAsFixed(1)}°C',
                Icons.thermostat,
                _getTemperatureColor(widget.temperature),
                _isTemperatureInRange(widget.temperature),
              ),
              _buildSensorReading(
                'Humidity',
                '${widget.humidity.toStringAsFixed(0)}%',
                Icons.water_drop,
                _getHumidityColor(widget.humidity),
                _isHumidityInRange(widget.humidity),
              ),
              _buildSensorReading(
                'Soil Moisture',
                '${widget.soilMoisture}%',
                Icons.grass,
                _getSoilMoistureColor(widget.soilMoisture.toDouble()),
                _isSoilMoistureInRange(widget.soilMoisture.toDouble()),
              ),
              _buildSensorReading(
                'Light Level',
                '${widget.lightLevel.toStringAsFixed(0)} lux',
                Icons.wb_sunny,
                _getLightLevelColor(widget.lightLevel),
                _isLightLevelInRange(widget.lightLevel),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Last update info
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey.shade400, size: 16),
              const SizedBox(width: 8),
              Text(
                'Last updated: ${widget.lastUpdate}',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  // Refresh readings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing sensor readings...'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorReading(String label, String value, IconData icon, Color color, bool inRange) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade700.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: inRange ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Spacer(),
              Icon(
                inRange ? Icons.check_circle : Icons.warning,
                color: inRange ? Colors.green : Colors.orange,
                size: 12,
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalChartsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Historical Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedTimeRange,
                dropdownColor: Colors.grey.shade800,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                underline: Container(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTimeRange = newValue!;
                  });
                },
                items: _timeRanges.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Mock chart display
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade600),
            ),
            child: Stack(
              children: [
                // Mock chart lines
                Positioned.fill(
                  child: CustomPaint(
                    painter: MockChartPainter(),
                  ),
                ),
                // Chart legend
                Positioned(
                  top: 12,
                  left: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartLegendItem('Temperature', Colors.red),
                      _buildChartLegendItem('Humidity', Colors.blue),
                      _buildChartLegendItem('Soil Moisture', Colors.brown),
                      _buildChartLegendItem('Light Level', Colors.yellow),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Chart controls
          Row(
            children: [
              Expanded(
                child: _buildChartActionButton(
                  'Export Data',
                  Icons.download,
                  Colors.blue,
                  () {
                    // Export chart data
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildChartActionButton(
                  'Full Screen',
                  Icons.fullscreen,
                  Colors.green,
                  () {
                    // Show full screen chart
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 2,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertThresholdsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Alert Thresholds',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Switch(
                value: _alertsEnabled,
                onChanged: (value) {
                  setState(() {
                    _alertsEnabled = value;
                  });
                },
                activeColor: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_alertsEnabled) ...[
            // Temperature thresholds
            _buildThresholdSlider(
              'Temperature',
              '°C',
              _tempMin,
              _tempMax,
              10.0,
              40.0,
              Colors.red,
              (min, max) {
                setState(() {
                  _tempMin = min;
                  _tempMax = max;
                });
                _notifyThresholdChanged();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Humidity thresholds
            _buildThresholdSlider(
              'Humidity',
              '%',
              _humidityMin,
              _humidityMax,
              20.0,
              90.0,
              Colors.blue,
              (min, max) {
                setState(() {
                  _humidityMin = min;
                  _humidityMax = max;
                });
                _notifyThresholdChanged();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Soil moisture thresholds
            _buildThresholdSlider(
              'Soil Moisture',
              '%',
              _soilMoistureMin,
              _soilMoistureMax,
              10.0,
              90.0,
              Colors.brown,
              (min, max) {
                setState(() {
                  _soilMoistureMin = min;
                  _soilMoistureMax = max;
                });
                _notifyThresholdChanged();
              },
            ),
          ] else ...[
            Text(
              'Enable alerts to set threshold ranges for automatic notifications when sensor values go out of range.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThresholdSlider(
    String label,
    String unit,
    double minValue,
    double maxValue,
    double rangeMin,
    double rangeMax,
    Color color,
    Function(double, double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${minValue.round()}$unit - ${maxValue.round()}$unit',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: RangeValues(minValue, maxValue),
          min: rangeMin,
          max: rangeMax,
          divisions: ((rangeMax - rangeMin) / 2).round(),
          activeColor: color,
          inactiveColor: Colors.grey.shade600,
          onChanged: (RangeValues values) {
            onChanged(values.start, values.end);
          },
        ),
      ],
    );
  }

  Widget _buildCalibrationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sensor Calibration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Calibrate sensors for accurate readings. Perform calibration in controlled conditions.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          
          // Calibration buttons grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildCalibrationButton(
                'Temperature',
                Icons.thermostat,
                Colors.red,
                widget.onCalibrateTemperature,
              ),
              _buildCalibrationButton(
                'Humidity',
                Icons.water_drop,
                Colors.blue,
                widget.onCalibrateHumidity,
              ),
              _buildCalibrationButton(
                'Soil Moisture',
                Icons.grass,
                Colors.brown,
                widget.onCalibrateSoilMoisture,
              ),
              _buildCalibrationButton(
                'Light Level',
                Icons.wb_sunny,
                Colors.yellow,
                widget.onCalibrateLightLevel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationButton(String label, IconData icon, Color color, VoidCallback? onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataExportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Export & Analysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Export options
          Row(
            children: [
              Expanded(
                child: _buildExportButton(
                  'Export CSV',
                  Icons.table_chart,
                  Colors.green,
                  () {
                    // Export as CSV
                    _showExportDialog('CSV');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExportButton(
                  'Export JSON',
                  Icons.code,
                  Colors.blue,
                  () {
                    // Export as JSON
                    _showExportDialog('JSON');
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildExportButton(
                  'Generate Report',
                  Icons.assessment,
                  Colors.purple,
                  () {
                    // Generate analysis report
                    _showExportDialog('Report');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExportButton(
                  'Share Data',
                  Icons.share,
                  Colors.orange,
                  () {
                    // Share sensor data
                    _showExportDialog('Share');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade800,
          title: Text(
            'Export $type',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            'Export sensor data as $type for the selected time range: $_selectedTimeRange',
            style: TextStyle(color: Colors.grey.shade300),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$type export started...'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Export'),
            ),
          ],
        );
      },
    );
  }

  void _notifyThresholdChanged() {
    widget.onThresholdsChanged?.call({
      'tempMin': _tempMin,
      'tempMax': _tempMax,
      'humidityMin': _humidityMin,
      'humidityMax': _humidityMax,
      'soilMoistureMin': _soilMoistureMin,
      'soilMoistureMax': _soilMoistureMax,
      'lightMin': _lightMin,
      'lightMax': _lightMax,
    });
  }

  // Helper methods for color coding and range checking
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

  bool _isTemperatureInRange(double temp) {
    return temp >= _tempMin && temp <= _tempMax;
  }

  bool _isHumidityInRange(double humidity) {
    return humidity >= _humidityMin && humidity <= _humidityMax;
  }

  bool _isSoilMoistureInRange(double moisture) {
    return moisture >= _soilMoistureMin && moisture <= _soilMoistureMax;
  }

  bool _isLightLevelInRange(double light) {
    return light >= _lightMin && light <= _lightMax;
  }
}

// Custom painter for mock chart
class MockChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw mock temperature line (red)
    paint.color = Colors.red;
    final tempPath = Path();
    tempPath.moveTo(0, size.height * 0.3);
    tempPath.quadraticBezierTo(size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.4);
    tempPath.quadraticBezierTo(size.width * 0.75, size.height * 0.5, size.width, size.height * 0.3);
    canvas.drawPath(tempPath, paint);

    // Draw mock humidity line (blue)
    paint.color = Colors.blue;
    final humidityPath = Path();
    humidityPath.moveTo(0, size.height * 0.6);
    humidityPath.quadraticBezierTo(size.width * 0.25, size.height * 0.7, size.width * 0.5, size.height * 0.5);
    humidityPath.quadraticBezierTo(size.width * 0.75, size.height * 0.4, size.width, size.height * 0.6);
    canvas.drawPath(humidityPath, paint);

    // Draw mock soil moisture line (brown)
    paint.color = Colors.brown;
    final soilPath = Path();
    soilPath.moveTo(0, size.height * 0.8);
    soilPath.quadraticBezierTo(size.width * 0.25, size.height * 0.7, size.width * 0.5, size.height * 0.9);
    soilPath.quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.7);
    canvas.drawPath(soilPath, paint);

    // Draw mock light level line (yellow)
    paint.color = Colors.yellow;
    final lightPath = Path();
    lightPath.moveTo(0, size.height * 0.4);
    lightPath.quadraticBezierTo(size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.1);
    lightPath.quadraticBezierTo(size.width * 0.75, size.height * 0.3, size.width, size.height * 0.4);
    canvas.drawPath(lightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}