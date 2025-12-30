import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/zone.dart';
import '../../models/sensor.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/app_background.dart';

class AnalyticsScreen extends StatefulWidget {
  final Zone zone;
  const AnalyticsScreen({super.key, required this.zone});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = true;
  List<Sensor> _sensors = [];
  
  // Selection State
  final Set<int> _selectedSensorIds = {};
  String _selectedTimeRange = '24H'; // 1H, 6H, 24H, 7D, 30D
  DateTimeRange? _customTimeRange;
  
  // Data State
  Map<int, List<FlSpot>> _sensorData = {};
  Map<int, Color> _sensorColors = {};
  
  // Chart State
  double _minY = 0;
  double _maxY = 100;
  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSensors();
  }

  Future<void> _loadSensors() async {
    setState(() => _isLoading = true);
    final sensors = await _databaseHelper.getZoneSensors(widget.zone.id!);
    
    if (sensors.isNotEmpty) {
      setState(() {
        _sensors = sensors;
        // Default select first sensor
        _selectedSensorIds.add(sensors.first.id!);
        _assignSensorColors();
      });
      await _loadData();
    } else {
      setState(() => _isLoading = false);
    }
  }
  
  void _assignSensorColors() {
    final colors = [
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.tealAccent,
    ];
    
    int i = 0;
    for (var sensor in _sensors) {
      _sensorColors[sensor.id!] = colors[i % colors.length];
      i++;
    }
  }

  Future<void> _loadData() async {
    if (_selectedSensorIds.isEmpty) {
      setState(() {
        _sensorData = {};
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTime.now();
    DateTime start;
    
    switch (_selectedTimeRange) {
      case '1H':
        start = now.subtract(const Duration(hours: 1));
        break;
      case '6H':
        start = now.subtract(const Duration(hours: 6));
        break;
      case '24H':
        start = now.subtract(const Duration(hours: 24));
        break;
      case '7D':
        start = now.subtract(const Duration(days: 7));
        break;
      case '30D':
        start = now.subtract(const Duration(days: 30));
        break;
      default:
        start = now.subtract(const Duration(hours: 24));
    }
    
    _rangeStart = start;
    _rangeEnd = now;

    Map<int, List<FlSpot>> newData = {};
    double globalMin = double.infinity;
    double globalMax = double.negativeInfinity;

    for (int sensorId in _selectedSensorIds) {
      final sensor = _sensors.firstWhere((s) => s.id == sensorId);
      
      // Determine reading type (simplified)
      String readingType = 'temperature';
      if (sensor.sensorType.contains('humidity')) readingType = 'humidity';
      if (sensor.sensorType.contains('ph')) readingType = 'ph';
      if (sensor.sensorType.contains('ec')) readingType = 'ec';
      if (sensor.sensorType.contains('co2')) readingType = 'co2';
      if (sensor.sensorType.contains('light')) readingType = 'light_intensity';
      if (sensor.sensorType.contains('soil')) readingType = 'moisture';

      final readings = await _databaseHelper.getSensorReadings(
        sensorId,
        readingType,
        startTime: start.millisecondsSinceEpoch ~/ 1000,
        endTime: now.millisecondsSinceEpoch ~/ 1000,
      );

      final points = <FlSpot>[];
      for (final reading in readings) {
        final timestamp = reading.timestamp.toDouble();
        final value = reading.value;
        points.add(FlSpot(timestamp, value));
        
        if (value < globalMin) globalMin = value;
        if (value > globalMax) globalMax = value;
      }
      newData[sensorId] = points;
    }
    
    if (globalMin == double.infinity) {
      globalMin = 0;
      globalMax = 100;
    } else {
      // Add padding
      final range = globalMax - globalMin;
      globalMin -= range * 0.1;
      globalMax += range * 0.1;
      if (globalMin == globalMax) {
        globalMin -= 10;
        globalMax += 10;
      }
    }

    setState(() {
      _sensorData = newData;
      _minY = globalMin;
      _maxY = globalMax;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.zone.name, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Time Range Selector
              _buildTimeRangeSelector(),
              
              // Sensor Selector
              _buildSensorSelector(),
              
              // Chart
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildChart(),
              ),
              
              // Statistics Panel (Placeholder for now)
              _buildStatisticsPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    final ranges = ['1H', '6H', '24H', '7D', '30D'];
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ranges.length,
        separatorBuilder: (c, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final range = ranges[index];
          final isSelected = _selectedTimeRange == range;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedTimeRange = range);
              _loadData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? Border.all(color: Colors.blueAccent.shade100) : null,
              ),
              alignment: Alignment.center,
              child: Text(
                range,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSensorSelector() {
    if (_sensors.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _sensors.length,
        separatorBuilder: (c, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sensor = _sensors[index];
          final isSelected = _selectedSensorIds.contains(sensor.id);
          final color = _sensorColors[sensor.id] ?? Colors.grey;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedSensorIds.remove(sensor.id);
                } else {
                  _selectedSensorIds.add(sensor.id!);
                }
              });
              _loadData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sensor.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart() {
    if (_sensorData.isEmpty || _sensorData.values.every((l) => l.isEmpty)) {
      return const Center(child: Text('No data available', style: TextStyle(color: Colors.white54)));
    }

    return Padding(
      padding: const EdgeInsets.only(right: 24, left: 12, top: 24, bottom: 12),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _getTimeInterval(),
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _formatTimeLabel(date),
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: _rangeStart.millisecondsSinceEpoch / 1000,
          maxX: _rangeEnd.millisecondsSinceEpoch / 1000,
          minY: _minY,
          maxY: _maxY,
          lineBarsData: _selectedSensorIds.map((id) {
            final points = _sensorData[id] ?? [];
            final color = _sensorColors[id] ?? Colors.blue;
            return LineChartBarData(
              spots: points,
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.1),
              ),
            );
          }).toList(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final sensorId = _selectedSensorIds.elementAt(spot.barIndex);
                  final sensor = _sensors.firstWhere((s) => s.id == sensorId);
                  return LineTooltipItem(
                    '${sensor.name}: ${spot.y.toStringAsFixed(1)}',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatisticsPanel() {
    // Placeholder for statistics
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Statistics (Selected Range)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_selectedSensorIds.isNotEmpty)
            ..._selectedSensorIds.map((id) {
               final sensor = _sensors.firstWhere((s) => s.id == id);
               final points = _sensorData[id] ?? [];
               if (points.isEmpty) return const SizedBox.shrink();
               
               final values = points.map((p) => p.y).toList();
               final avg = values.reduce((a, b) => a + b) / values.length;
               final min = values.reduce((a, b) => a < b ? a : b);
               final max = values.reduce((a, b) => a > b ? a : b);
               final color = _sensorColors[id] ?? Colors.white;
               
               return Padding(
                 padding: const EdgeInsets.only(bottom: 12),
                 child: Row(
                   children: [
                     Container(width: 4, height: 40, color: color),
                     const SizedBox(width: 12),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(sensor.name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                           const SizedBox(height: 4),
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               _StatItem(label: 'Avg', value: avg.toStringAsFixed(1)),
                               _StatItem(label: 'Min', value: min.toStringAsFixed(1)),
                               _StatItem(label: 'Max', value: max.toStringAsFixed(1)),
                             ],
                           ),
                         ],
                       ),
                     ),
                   ],
                 ),
               );
            }),
        ],
      ),
    );
  }

  double _getTimeInterval() {
    switch (_selectedTimeRange) {
      case '1H': return 60 * 10; // 10 minutes
      case '6H': return 60 * 60; // 1 hour
      case '24H': return 60 * 60 * 4; // 4 hours
      case '7D': return 60 * 60 * 24; // 1 day
      case '30D': return 60 * 60 * 24 * 5; // 5 days
      default: return 60 * 60 * 4;
    }
  }

  String _formatTimeLabel(DateTime date) {
    switch (_selectedTimeRange) {
      case '1H': 
      case '6H':
        return DateFormat('HH:mm').format(date);
      case '24H':
        return DateFormat('HH:mm').format(date);
      case '7D': 
      case '30D':
        return DateFormat('MM/dd').format(date);
      default: return DateFormat('HH:mm').format(date);
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  
  const _StatItem({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
