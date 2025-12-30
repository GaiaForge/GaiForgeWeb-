import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../models/sensor.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/app_background.dart';

class SeedlingMatScreen extends StatefulWidget {
  final Zone zone;
  const SeedlingMatScreen({super.key, required this.zone});

  @override
  State<SeedlingMatScreen> createState() => _SeedlingMatScreenState();
}

class _SeedlingMatScreenState extends State<SeedlingMatScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;

  // Settings State
  bool _enabled = false;
  String _mode = 'manual'; // 'manual', 'thermostat', 'scheduled'
  double _targetTemp = 24.0;
  bool _autoOffEnabled = false;
  int _autoOffDays = 14;
  int? _sensorId;
  DateTime? _createdAt;

  // Available sensors for thermostat mode
  List<Sensor> _temperatureSensors = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load existing settings
    final settings = await _db.getSeedlingMatSettings(widget.zone.id!);
    
    // Load temperature sensors for this zone
    final sensors = await _db.getZoneSensors(widget.zone.id!);
    final tempSensors = sensors.where((s) {
      final type = s.sensorType.toLowerCase();
      return type.contains('dht') || type.contains('bme') || type.contains('temp');
    }).toList();

    setState(() {
      if (settings != null) {
        _enabled = settings['enabled'] == 1;
        _mode = settings['mode'] ?? 'manual';
        _targetTemp = (settings['target_temp'] as num?)?.toDouble() ?? 24.0;
        _autoOffEnabled = settings['auto_off_enabled'] == 1;
        _autoOffDays = settings['auto_off_days'] ?? 14;
        _sensorId = settings['sensor_id'] as int?;
        if (settings['created_at'] != null) {
          final val = settings['created_at'] as int;
          // If value is small (seconds), convert to ms. Otherwise assume ms.
          final ms = val < 10000000000 ? val * 1000 : val;
          _createdAt = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      }
      _temperatureSensors = tempSensors;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final settings = {
      'zone_id': widget.zone.id,
      'enabled': _enabled ? 1 : 0,
      'mode': _mode,
      'target_temp': _targetTemp,
      'auto_off_enabled': _autoOffEnabled ? 1 : 0,
      'auto_off_days': _autoOffDays,
      'sensor_id': _sensorId,
      'created_at': _createdAt?.millisecondsSinceEpoch ?? now,
      'updated_at': now,
    };
    await _db.saveSeedlingMatSettings(settings);
  }

  int? _calculateDaysRemaining() {
    if (!_autoOffEnabled || _createdAt == null) return null;
    final daysSinceCreation = DateTime.now().difference(_createdAt!).inDays;
    final remaining = _autoOffDays - daysSinceCreation;
    return remaining > 0 ? remaining : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Seedling Mat'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              await _saveSettings();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Master Toggle Card
                      _buildGlassCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _enabled 
                                        ? Colors.orange.withOpacity(0.2) 
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.thermostat,
                                    color: _enabled ? Colors.orange : Colors.white54,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Seedling Mat',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _enabled ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        color: _enabled ? Colors.orange : Colors.white54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: _enabled,
                              activeColor: Colors.orange,
                              onChanged: (val) {
                                setState(() {
                                  _enabled = val;
                                  if (val && _createdAt == null) {
                                    _createdAt = DateTime.now();
                                  }
                                });
                                _saveSettings();
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Mode Selection
                      const Text(
                        'Control Mode',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildModeSelector(),

                      const SizedBox(height: 24),

                      // Thermostat Settings (only visible in thermostat mode)
                      if (_mode == 'thermostat') ...[
                        _buildGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.device_thermostat, color: Colors.orange.shade300),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Thermostat Settings',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Target Temperature
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Target Temperature', style: TextStyle(color: Colors.white70)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      '${_targetTemp.toStringAsFixed(1)}°C',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.orange,
                                  inactiveTrackColor: Colors.white.withOpacity(0.1),
                                  thumbColor: Colors.orange,
                                  overlayColor: Colors.orange.withOpacity(0.2),
                                ),
                                child: Slider(
                                  value: _targetTemp,
                                  min: 18.0,
                                  max: 35.0,
                                  divisions: 34,
                                  onChanged: (val) => setState(() => _targetTemp = val),
                                  onChangeEnd: (val) => _saveSettings(),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('18°C', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                                  Text('35°C', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                                ],
                              ),
                              
                              const Divider(color: Colors.white10, height: 32),

                              // Sensor Selection
                              const Text('Temperature Sensor', style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int?>(
                                    value: _sensorId,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF1E293B),
                                    style: const TextStyle(color: Colors.white),
                                    hint: const Text('Select Sensor', style: TextStyle(color: Colors.white54)),
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('None', style: TextStyle(color: Colors.white54)),
                                      ),
                                      ..._temperatureSensors.map((s) => DropdownMenuItem<int?>(
                                        value: s.id,
                                        child: Text(s.name, style: const TextStyle(color: Colors.white)),
                                      )),
                                    ],
                                    onChanged: (val) {
                                      setState(() => _sensorId = val);
                                      _saveSettings();
                                    },
                                  ),
                                ),
                              ),
                              if (_temperatureSensors.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'No temperature sensors found. Add a DHT22 or BME280 sensor first.',
                                    style: TextStyle(color: Colors.orange.shade300, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Auto-Off Timer Card
                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.timer_outlined, color: Colors.blue.shade300),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Auto-Off Timer',
                                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: _autoOffEnabled,
                                  activeColor: Colors.blue,
                                  onChanged: (val) {
                                    setState(() => _autoOffEnabled = val);
                                    _saveSettings();
                                  },
                                ),
                              ],
                            ),
                            if (_autoOffEnabled) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Automatically disable the seedling mat after a set number of days. '
                                'Useful for preventing overheating once seedlings have established roots.',
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Days until auto-off', style: TextStyle(color: Colors.white70)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$_autoOffDays days',
                                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.blue,
                                  inactiveTrackColor: Colors.white.withOpacity(0.1),
                                  thumbColor: Colors.blue,
                                ),
                                child: Slider(
                                  value: _autoOffDays.toDouble(),
                                  min: 7,
                                  max: 30,
                                  divisions: 23,
                                  onChanged: (val) => setState(() => _autoOffDays = val.round()),
                                  onChangeEnd: (val) => _saveSettings(),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('7 days', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                                  Text('30 days', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                                ],
                              ),
                              if (_calculateDaysRemaining() != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _calculateDaysRemaining()! <= 2 
                                        ? Colors.orange.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _calculateDaysRemaining()! <= 2 
                                          ? Colors.orange.withOpacity(0.3)
                                          : Colors.green.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _calculateDaysRemaining()! <= 2 
                                            ? Icons.warning_amber_rounded 
                                            : Icons.check_circle_outline,
                                        color: _calculateDaysRemaining()! <= 2 
                                            ? Colors.orange 
                                            : Colors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_calculateDaysRemaining()} days remaining',
                                        style: TextStyle(
                                          color: _calculateDaysRemaining()! <= 2 
                                              ? Colors.orange 
                                              : Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Reset Timer Button
                      if (_enabled && _autoOffEnabled)
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() => _createdAt = DateTime.now());
                              _saveSettings();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Timer reset. Auto-off countdown restarted.')),
                              );
                            },
                            icon: const Icon(Icons.refresh, color: Colors.white70),
                            label: const Text('Reset Timer', style: TextStyle(color: Colors.white70)),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _buildModeOption('manual', 'Manual', Icons.touch_app),
          _buildModeOption('thermostat', 'Thermostat', Icons.thermostat_auto),
        ],
      ),
    );
  }

  Widget _buildModeOption(String value, String label, IconData icon) {
    final isSelected = _mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _mode = value);
          _saveSettings();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: Colors.orange.withOpacity(0.5))
                : Border.all(color: Colors.transparent),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.orange : Colors.white54,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}
