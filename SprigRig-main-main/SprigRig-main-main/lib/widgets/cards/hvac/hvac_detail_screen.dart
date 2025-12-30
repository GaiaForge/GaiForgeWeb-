// lib/widgets/cards/ventilation/ventilation_detail_screen.dart
import 'package:flutter/material.dart';

class HvacDetailScreen extends StatefulWidget {
  final int zoneId;
  final bool isFanRunning;
  final int fanSpeed; // 0-100%
  final String mode; // 'manual', 'automatic', 'temperature-based'
  final double targetTemperature;
  final String schedule;
  final VoidCallback? onToggle;
  final ValueChanged<int>? onSpeedChanged;
  final ValueChanged<String>? onModeChanged;
  final ValueChanged<double>? onTargetTempChanged;

  const HvacDetailScreen({
    super.key,
    required this.zoneId,
    required this.isFanRunning,
    required this.fanSpeed,
    required this.mode,
    required this.targetTemperature,
    required this.schedule,
    this.onToggle,
    this.onSpeedChanged,
    this.onModeChanged,
    this.onTargetTempChanged,
  });

  @override
  State<HvacDetailScreen> createState() => _HvacDetailScreenState();
}

class _HvacDetailScreenState extends State<HvacDetailScreen> {
  late bool _isFanRunning;
  late int _fanSpeed;
  late String _selectedMode;
  late double _targetTemperature;
  late TimeOfDay _onTime;
  late TimeOfDay _offTime;

  final List<String> _modes = ['manual', 'automatic', 'temperature-based'];

  @override
  void initState() {
    super.initState();
    _isFanRunning = widget.isFanRunning;
    _fanSpeed = widget.fanSpeed;
    _selectedMode = widget.mode;
    _targetTemperature = widget.targetTemperature;
    _onTime = const TimeOfDay(hour: 6, minute: 0);
    _offTime = const TimeOfDay(hour: 22, minute: 0);
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
            Color(0xFF7C3AED), // purple-600
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
                      colors: [Colors.purple, Colors.purpleAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.air, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'HVAC Control',
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
                  _buildFanSpeedCard(),
                  const SizedBox(height: 16),
                  _buildModeCard(),
                  const SizedBox(height: 16),
                  if (_selectedMode == 'temperature-based') _buildTemperatureCard(),
                  if (_selectedMode == 'automatic') _buildScheduleCard(),
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
                'Fan Status',
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
                  color: _isFanRunning 
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isFanRunning ? Colors.green : Colors.grey,
                  ),
                ),
                child: Text(
                  _isFanRunning ? 'RUNNING' : 'STOPPED',
                  style: TextStyle(
                    color: _isFanRunning ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Fan speed and airflow info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fan Speed',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.speed,
                          color: _getSpeedColor(_fanSpeed),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_fanSpeed%',
                          style: TextStyle(
                            color: _getSpeedColor(_fanSpeed),
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
                      'Airflow',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getAirflowRate(_fanSpeed),
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
                  _isFanRunning = !_isFanRunning;
                });
                widget.onToggle?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFanRunning ? Colors.red : Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isFanRunning ? Icons.stop : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(
                    _isFanRunning ? 'Stop Fan' : 'Start Fan',
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

  Widget _buildFanSpeedCard() {
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
            'Fan Speed Control',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Speed slider
          Row(
            children: [
              const Icon(Icons.volume_down, color: Colors.purple, size: 20),
              Expanded(
                child: Slider(
                  value: _fanSpeed.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 10,
                  activeColor: Colors.purple,
                  inactiveColor: Colors.grey.shade600,
                  onChanged: (value) {
                    setState(() {
                      _fanSpeed = value.round();
                    });
                    widget.onSpeedChanged?.call(_fanSpeed);
                  },
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.purple, size: 20),
            ],
          ),
          
          // Speed presets
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [25, 50, 75, 100].map((speed) {
              final isSelected = _fanSpeed == speed;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _fanSpeed = speed;
                  });
                  widget.onSpeedChanged?.call(speed);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.purple.withValues(alpha: 0.3)
                        : Colors.grey.shade700.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.purple : Colors.grey.shade600,
                    ),
                  ),
                  child: Text(
                    '$speed%',
                    style: TextStyle(
                      color: isSelected ? Colors.purple : Colors.grey.shade400,
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
            'Ventilation Mode',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Mode selection
          Column(
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
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.purple.withValues(alpha: 0.3)
                        : Colors.grey.shade700.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.purple : Colors.grey.shade600,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getModeIcon(mode),
                        color: isSelected ? Colors.purple : Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getModeDisplayName(mode),
                              style: TextStyle(
                                color: isSelected ? Colors.purple : Colors.grey.shade400,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getModeDescription(mode),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureCard() {
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
            'Temperature Control',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Target temperature slider
          Text(
            'Activate fan when temperature exceeds: ${_targetTemperature.round()}°C',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          
          Slider(
            value: _targetTemperature,
            min: 15,
            max: 35,
            divisions: 20,
            activeColor: Colors.purple,
            inactiveColor: Colors.grey.shade600,
            onChanged: (value) {
              setState(() {
                _targetTemperature = value;
              });
              widget.onTargetTempChanged?.call(value);
            },
          ),
          
          // Current vs target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Temp',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                  const Text(
                    '23°C',
                    style: TextStyle(
                      color: Colors.white,
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
                    'Target Temp',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${_targetTemperature.round()}°C',
                    style: const TextStyle(
                      color: Colors.purple,
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
            'Ventilation Schedule',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // On time
          _buildTimeSelector(
            'Fan On Time',
            _onTime,
            (TimeOfDay time) {
              setState(() {
                _onTime = time;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Off time
          _buildTimeSelector(
            'Fan Off Time',
            _offTime,
            (TimeOfDay time) {
              setState(() {
                _offTime = time;
              });
            },
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
                  'Fresh Air',
                  Icons.air,
                  Colors.purple,
                  () {
                    // 5-minute fresh air cycle
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Exhaust',
                  Icons.wind_power,
                  Colors.orange,
                  () {
                    // Quick exhaust cycle
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
      case 'manual': return 'Manual Control';
      case 'automatic': return 'Scheduled';
      case 'temperature-based': return 'Temperature Based';
      default: return mode;
    }
  }

  String _getModeDescription(String mode) {
    switch (mode) {
      case 'manual': return 'Control fan manually when needed';
      case 'automatic': return 'Run fan on a set schedule';
      case 'temperature-based': return 'Activate fan based on temperature';
      default: return '';
    }
  }
}