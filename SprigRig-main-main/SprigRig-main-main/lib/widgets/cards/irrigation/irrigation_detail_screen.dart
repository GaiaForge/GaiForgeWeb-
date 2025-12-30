// lib/widgets/cards/irrigation/irrigation_detail_screen.dart
import 'package:flutter/material.dart';

class IrrigationDetailScreen extends StatefulWidget {
  final int zoneId;
  final bool isRunning;
  final int soilMoisture;
  final String wateringDuration;
  final String schedule;
  final String mode; // 'manual', 'automatic', 'moisture-based'
  final VoidCallback? onToggle;
  final ValueChanged<String>? onDurationChanged;
  final ValueChanged<String>? onModeChanged;

  const IrrigationDetailScreen({
    super.key,
    required this.zoneId,
    required this.isRunning,
    required this.soilMoisture,
    required this.wateringDuration,
    required this.schedule,
    required this.mode,
    this.onToggle,
    this.onDurationChanged,
    this.onModeChanged,
  });

  @override
  State<IrrigationDetailScreen> createState() => _IrrigationDetailScreenState();
}

class _IrrigationDetailScreenState extends State<IrrigationDetailScreen> {
  late bool _isRunning;
  late String _selectedDuration;
  late String _selectedMode;
  late TimeOfDay _morningTime;
  late TimeOfDay _eveningTime;
  late int _moistureThreshold;

  final List<String> _durations = ['5 min', '10 min', '15 min', '20 min', '30 min', 'Custom'];
  final List<String> _modes = ['manual', 'automatic', 'moisture-based'];

  @override
  void initState() {
    super.initState();
    _isRunning = widget.isRunning;
    _selectedDuration = widget.wateringDuration;
    _selectedMode = widget.mode;
    _morningTime = const TimeOfDay(hour: 8, minute: 0);
    _eveningTime = const TimeOfDay(hour: 18, minute: 0);
    _moistureThreshold = 30; // Default 30% moisture threshold
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
            Color(0xFF1E40AF), // blue-700
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
                  child: const Icon(Icons.water_drop, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Irrigation Control',
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
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildModeCard(),
                  const SizedBox(height: 16),
                  _buildDurationCard(),
                  const SizedBox(height: 16),
                  if (_selectedMode == 'automatic') _buildScheduleCard(),
                  if (_selectedMode == 'moisture-based') _buildMoistureCard(),
                  const SizedBox(height: 16),
                  _buildQuickActionsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Irrigation Status',
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
                  color: _isRunning 
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isRunning ? Colors.green : Colors.grey,
                  ),
                ),
                child: Text(
                  _isRunning ? 'WATERING' : 'STOPPED',
                  style: TextStyle(
                    color: _isRunning ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Soil moisture display
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Soil Moisture',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.water_drop,
                          color: _getMoistureColor(widget.soilMoisture),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.soilMoisture}%',
                          style: TextStyle(
                            color: _getMoistureColor(widget.soilMoisture),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duration',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedDuration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Manual control button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isRunning = !_isRunning;
                });
                widget.onToggle?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRunning ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isRunning ? Icons.stop : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(
                    _isRunning ? 'Stop Watering' : 'Start Watering',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard() {
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
            'Watering Mode',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Mode selection buttons
          Wrap(
            spacing: 8,
            children: _modes.map((mode) {
              final isSelected = _selectedMode == mode;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMode = mode;
                  });
                  widget.onModeChanged?.call(mode);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withValues(alpha: 0.3)
                        : Colors.grey.shade700.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade600,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getModeIcon(mode),
                        color: isSelected ? Colors.blue : Colors.grey.shade400,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getModeDisplayName(mode),
                        style: TextStyle(
                          color: isSelected ? Colors.blue : Colors.grey.shade400,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 12),
          
          // Mode description
          Text(
            _getModeDescription(_selectedMode),
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard() {
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
            'Watering Duration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Duration buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _durations.map((duration) {
              final isSelected = _selectedDuration == duration;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDuration = duration;
                  });
                  widget.onDurationChanged?.call(duration);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withValues(alpha: 0.3)
                        : Colors.grey.shade700.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade600,
                    ),
                  ),
                  child: Text(
                    duration,
                    style: TextStyle(
                      color: isSelected ? Colors.blue : Colors.grey.shade400,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
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
            'Watering Schedule',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Morning time
          _buildTimeSelector(
            'Morning Watering',
            _morningTime,
            (TimeOfDay time) {
              setState(() {
                _morningTime = time;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Evening time
          _buildTimeSelector(
            'Evening Watering',
            _eveningTime,
            (TimeOfDay time) {
              setState(() {
                _eveningTime = time;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMoistureCard() {
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
            'Moisture Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Moisture threshold slider
          Text(
            'Water when moisture drops below: $_moistureThreshold%',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          
          Slider(
            value: _moistureThreshold.toDouble(),
            min: 10,
            max: 70,
            divisions: 12,
            activeColor: Colors.blue,
            inactiveColor: Colors.grey.shade600,
            onChanged: (value) {
              setState(() {
                _moistureThreshold = value.round();
              });
            },
          ),
          
          // Current vs threshold
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Moisture',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${widget.soilMoisture}%',
                    style: TextStyle(
                      color: _getMoistureColor(widget.soilMoisture),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Threshold',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$_moistureThreshold%',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
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
            'Quick Actions',
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
                child: _buildQuickActionButton(
                  'Quick Spray',
                  Icons.water,
                  Colors.blue,
                  () {
                    // Quick 30-second spray
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Deep Water',
                  Icons.water_drop,
                  Colors.indigo,
                  () {
                    // Long watering session
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade700.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade600),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ),
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

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getMoistureColor(int moisture) {
    if (moisture >= 60) return Colors.green;
    if (moisture >= 40) return Colors.yellow;
    if (moisture >= 20) return Colors.orange;
    return Colors.red;
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'manual': return Icons.touch_app;
      case 'automatic': return Icons.schedule;
      case 'moisture-based': return Icons.water_drop;
      default: return Icons.settings;
    }
  }

  String _getModeDisplayName(String mode) {
    switch (mode) {
      case 'manual': return 'Manual';
      case 'automatic': return 'Scheduled';
      case 'moisture-based': return 'Smart';
      default: return mode;
    }
  }

  String _getModeDescription(String mode) {
    switch (mode) {
      case 'manual': return 'Water manually when needed';
      case 'automatic': return 'Water on a set schedule';
      case 'moisture-based': return 'Water automatically based on soil moisture';
      default: return '';
    }
  }
}