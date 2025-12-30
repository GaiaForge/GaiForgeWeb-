// lib/widgets/cards/climate/climate_detail_screen.dart
import 'package:flutter/material.dart';

class ClimateDetailScreen extends StatefulWidget {
  final int zoneId;
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

  const ClimateDetailScreen({
    super.key,
    required this.zoneId,
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
  });

  @override
  State<ClimateDetailScreen> createState() => _ClimateDetailScreenState();
}

class _ClimateDetailScreenState extends State<ClimateDetailScreen> {
  late bool _isClimateControlActive;
  late double _targetTempDay;
  late double _targetTempNight;
  late double _targetHumidity;
  late String _selectedMode;
  late TimeOfDay _dayStartTime;
  late TimeOfDay _nightStartTime;
  bool _vpdControlEnabled = false;
  double _targetVpd = 1.2; // kPa

  final List<String> _modes = ['manual', 'automatic', 'vpd-based'];

  @override
  void initState() {
    super.initState();
    _isClimateControlActive = widget.isClimateControlActive;
    _targetTempDay = widget.targetTempDay;
    _targetTempNight = widget.targetTempNight;
    _targetHumidity = widget.targetHumidity;
    _selectedMode = widget.mode;
    _dayStartTime = const TimeOfDay(hour: 6, minute: 0);
    _nightStartTime = const TimeOfDay(hour: 22, minute: 0);
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
            Color(0xFFEA580C), // orange-600
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
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.thermostat, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Climate Control',
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
                  _buildCurrentConditionsCard(),
                  const SizedBox(height: 16),
                  _buildModeCard(),
                  const SizedBox(height: 16),
                  _buildTemperatureControlCard(),
                  const SizedBox(height: 16),
                  _buildHumidityControlCard(),
                  const SizedBox(height: 16),
                  if (_selectedMode == 'vpd-based') _buildVpdCard(),
                  if (_selectedMode == 'automatic') _buildScheduleCard(),
                  const SizedBox(height: 16),
                  _buildSystemStatusCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentConditionsCard() {
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
                'Current Conditions',
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
                  color: _isClimateControlActive 
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isClimateControlActive ? Colors.green : Colors.grey,
                  ),
                ),
                child: Text(
                  _isClimateControlActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: _isClimateControlActive ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Current readings
          Row(
            children: [
              Expanded(
                child: _buildConditionDisplay(
                  'Temperature',
                  '${widget.currentTemperature.toStringAsFixed(1)}°C',
                  Icons.thermostat,
                  _getTemperatureColor(widget.currentTemperature),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildConditionDisplay(
                  'Humidity',
                  '${widget.currentHumidity.toStringAsFixed(0)}%',
                  Icons.water_drop,
                  _getHumidityColor(widget.currentHumidity),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // VPD calculation
          Row(
            children: [
              Expanded(
                child: _buildConditionDisplay(
                  'VPD',
                  '${_calculateVpd(widget.currentTemperature, widget.currentHumidity).toStringAsFixed(2)} kPa',
                  Icons.analytics,
                  _getVpdColor(_calculateVpd(widget.currentTemperature, widget.currentHumidity)),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildConditionDisplay(
                  'Status',
                  _getClimateStatus(),
                  Icons.eco,
                  _getStatusColor(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Master control button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isClimateControlActive = !_isClimateControlActive;
                });
                widget.onToggle?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isClimateControlActive ? Colors.red : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isClimateControlActive ? Icons.stop : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(
                    _isClimateControlActive ? 'Stop Climate Control' : 'Start Climate Control',
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

  Widget _buildConditionDisplay(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
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
            'Control Mode',
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
                        ? Colors.orange.withValues(alpha: 0.3)
                        : Colors.grey.shade700.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.grey.shade600,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getModeIcon(mode),
                        color: isSelected ? Colors.orange : Colors.grey.shade400,
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
                                color: isSelected ? Colors.orange : Colors.grey.shade400,
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

  Widget _buildTemperatureControlCard() {
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
          
          // Day temperature
          Text(
            'Day Temperature: ${_targetTempDay.round()}°C',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          Slider(
            value: _targetTempDay,
            min: 15,
            max: 35,
            divisions: 20,
            activeColor: Colors.orange,
            inactiveColor: Colors.grey.shade600,
            onChanged: (value) {
              setState(() {
                _targetTempDay = value;
              });
              widget.onTargetTempDayChanged?.call(value);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Night temperature
          Text(
            'Night Temperature: ${_targetTempNight.round()}°C',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          Slider(
            value: _targetTempNight,
            min: 10,
            max: 30,
            divisions: 20,
            activeColor: Colors.blue,
            inactiveColor: Colors.grey.shade600,
            onChanged: (value) {
              setState(() {
                _targetTempNight = value;
              });
              widget.onTargetTempNightChanged?.call(value);
            },
          ),
          
          // Current vs targets
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTargetDisplay('Current', '${widget.currentTemperature.round()}°C', Colors.white),
              _buildTargetDisplay('Day Target', '${_targetTempDay.round()}°C', Colors.orange),
              _buildTargetDisplay('Night Target', '${_targetTempNight.round()}°C', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityControlCard() {
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
            'Humidity Control',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Target humidity slider
          Text(
            'Target Humidity: ${_targetHumidity.round()}%',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          Slider(
            value: _targetHumidity,
            min: 30,
            max: 90,
            divisions: 12,
            activeColor: Colors.cyan,
            inactiveColor: Colors.grey.shade600,
            onChanged: (value) {
              setState(() {
                _targetHumidity = value;
              });
              widget.onTargetHumidityChanged?.call(value);
            },
          ),
          
          // Current vs target
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTargetDisplay('Current', '${widget.currentHumidity.round()}%', Colors.white),
              _buildTargetDisplay('Target', '${_targetHumidity.round()}%', Colors.cyan),
              _buildTargetDisplay('Deviation', '${(widget.currentHumidity - _targetHumidity).abs().round()}%', 
                  (widget.currentHumidity - _targetHumidity).abs() > 10 ? Colors.red : Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVpdCard() {
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
            'VPD (Vapor Pressure Deficit) Control',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // VPD explanation
          Text(
            'VPD indicates the plant\'s ability to transpire. Optimal range: 0.8-1.5 kPa',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          
          // Target VPD slider
          Text(
            'Target VPD: ${_targetVpd.toStringAsFixed(1)} kPa',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          Slider(
            value: _targetVpd,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            activeColor: Colors.green,
            inactiveColor: Colors.grey.shade600,
            onChanged: (value) {
              setState(() {
                _targetVpd = value;
              });
            },
          ),
          
          // VPD status
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTargetDisplay('Current VPD', '${_calculateVpd(widget.currentTemperature, widget.currentHumidity).toStringAsFixed(1)} kPa', 
                  _getVpdColor(_calculateVpd(widget.currentTemperature, widget.currentHumidity))),
              _buildTargetDisplay('Target VPD', '${_targetVpd.toStringAsFixed(1)} kPa', Colors.green),
              _buildTargetDisplay('Status', _getVpdStatus(), _getVpdStatusColor()),
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
            'Day/Night Schedule',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Day start time
          _buildTimeSelector(
            'Day Period Starts',
            _dayStartTime,
            (TimeOfDay time) {
              setState(() {
                _dayStartTime = time;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Night start time
          _buildTimeSelector(
            'Night Period Starts',
            _nightStartTime,
            (TimeOfDay time) {
              setState(() {
                _nightStartTime = time;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard() {
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
            'System Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // System components status
          Row(
            children: [
              Expanded(
                child: _buildSystemComponent(
                  'Heating',
                  widget.heatingEnabled,
                  Icons.whatshot,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSystemComponent(
                  'Cooling',
                  widget.coolingEnabled,
                  Icons.ac_unit,
                  Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Quick actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Boost Heat',
                  Icons.whatshot,
                  Colors.red,
                  () {
                    // Quick heating boost
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Cool Down',
                  Icons.ac_unit,
                  Colors.blue,
                  () {
                    // Quick cooling
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetDisplay(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemComponent(String name, bool isActive, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive 
            ? color.withValues(alpha: 0.2)
            : Colors.grey.shade700.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? color : Colors.grey.shade600,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isActive ? color : Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              color: isActive ? color : Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isActive ? 'ON' : 'OFF',
            style: TextStyle(
              color: isActive ? color : Colors.grey.shade400,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
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

  // Helper methods
  double _calculateVpd(double temperature, double humidity) {
    // Simplified VPD calculation
    final saturationVaporPressure = 0.6108 * (2.71828 * (17.27 * temperature / (temperature + 237.3)));
    final actualVaporPressure = saturationVaporPressure * (humidity / 100);
    return saturationVaporPressure - actualVaporPressure;
  }

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

  Color _getVpdColor(double vpd) {
    if (vpd < 0.8) return Colors.blue;
    if (vpd < 1.5) return Colors.green;
    return Colors.red;
  }

  Color _getStatusColor() {
    if (!_isClimateControlActive) return Colors.grey;
    
    final tempOk = (widget.currentTemperature >= _targetTempDay - 2) && 
                   (widget.currentTemperature <= _targetTempDay + 2);
    final humidityOk = (widget.currentHumidity >= _targetHumidity - 10) && 
                       (widget.currentHumidity <= _targetHumidity + 10);
    
    if (tempOk && humidityOk) return Colors.green;
    if (tempOk || humidityOk) return Colors.yellow;
    return Colors.red;
  }

  String _getClimateStatus() {
    if (!_isClimateControlActive) return 'Inactive';
    
    final tempOk = (widget.currentTemperature >= _targetTempDay - 2) && 
                   (widget.currentTemperature <= _targetTempDay + 2);
    final humidityOk = (widget.currentHumidity >= _targetHumidity - 10) && 
                       (widget.currentHumidity <= _targetHumidity + 10);
    
    if (tempOk && humidityOk) return 'Optimal';
    if (tempOk || humidityOk) return 'Adjusting';
    return 'Out of Range';
  }

  String _getVpdStatus() {
    final vpd = _calculateVpd(widget.currentTemperature, widget.currentHumidity);
    if (vpd < 0.8) return 'Low';
    if (vpd < 1.5) return 'Optimal';
    return 'High';
  }

  Color _getVpdStatusColor() {
    final vpd = _calculateVpd(widget.currentTemperature, widget.currentHumidity);
    if (vpd < 0.8) return Colors.blue;
    if (vpd < 1.5) return Colors.green;
    return Colors.red;
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
      case 'manual': return 'Manual Control';
      case 'automatic': return 'Automatic Schedule';
      case 'vpd-based': return 'VPD-Based Control';
      default: return mode;
    }
  }

  String _getModeDescription(String mode) {
    switch (mode) {
      case 'manual': return 'Manual temperature and humidity control';
      case 'automatic': return 'Scheduled day/night temperature cycles';
      case 'vpd-based': return 'Advanced VPD-optimized control';
      default: return '';
    }
  }
}