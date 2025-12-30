import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/zone.dart';
import '../../models/astral_simulation_settings.dart';
import '../../services/database_helper.dart';
import '../../services/astral_simulation_service.dart';
import '../../widgets/common/app_background.dart';

class AstralSimulationScreen extends StatefulWidget {
  final Zone zone;

  const AstralSimulationScreen({super.key, required this.zone});

  @override
  State<AstralSimulationScreen> createState() => _AstralSimulationScreenState();
}

class _AstralSimulationScreenState extends State<AstralSimulationScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final AstralSimulationService _astralService = AstralSimulationService.instance;
  
  bool _isLoading = true;
  AstralSimulationSettings? _settings;
  
  // Form State
  final _formKey = GlobalKey<FormState>();
  late double _latitude;
  late double _longitude;
  String _locationName = '';
  String _simulationMode = 'full_year';
  double _timeCompression = 1.0;
  int _sunriseOffset = 0;
  int _sunsetOffset = 0;
  bool _useIntensityCurve = false;
  
  // Preview State
  DateTime _previewDate = DateTime.now();
  SunTimes? _previewSunTimes;
  AstralLightingSchedule? _previewSchedule;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _db.getAstralSimulationSettings(widget.zone.id!);
      
      if (settings != null) {
        _settings = settings;
        _latitude = settings.latitude;
        _longitude = settings.longitude;
        _locationName = settings.locationName ?? '';
        _simulationMode = settings.simulationMode;
        _timeCompression = settings.timeCompression;
        _sunriseOffset = settings.sunriseOffsetMinutes;
        _sunsetOffset = settings.sunsetOffsetMinutes;
        _useIntensityCurve = settings.useIntensityCurve;
      } else {
        // Defaults (e.g., San Francisco)
        _latitude = 37.7749;
        _longitude = -122.4194;
        _locationName = 'San Francisco, CA';
      }
      
      _updatePreview();
    } catch (e) {
      debugPrint('Error loading astral settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updatePreview() {
    final tempSettings = _buildSettingsFromState();
    _previewDate = _astralService.getCurrentSimulatedDate(tempSettings);
    _previewSunTimes = _astralService.calculateSunTimes(_latitude, _longitude, _previewDate);
    _previewSchedule = _astralService.getTodaySchedule(tempSettings);
  }

  AstralSimulationSettings _buildSettingsFromState() {
    return AstralSimulationSettings(
      id: _settings?.id,
      zoneId: widget.zone.id!,
      enabled: _settings?.enabled ?? false,
      latitude: _latitude,
      longitude: _longitude,
      locationName: _locationName,
      simulationMode: _simulationMode,
      timeCompression: _timeCompression,
      simulationStartDate: _settings?.simulationStartDate ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      sunriseOffsetMinutes: _sunriseOffset,
      sunsetOffsetMinutes: _sunsetOffset,
      useIntensityCurve: _useIntensityCurve,
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);
    try {
      final settings = _buildSettingsFromState();
      await _db.saveAstralSimulationSettings(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Astral simulation settings saved')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _toggleEnabled(bool value) async {
    setState(() => _isLoading = true);
    try {
      final settings = _buildSettingsFromState();
      // Create a new object with the toggled enabled state
      final newSettings = AstralSimulationSettings(
        id: settings.id,
        zoneId: settings.zoneId,
        enabled: value,
        latitude: settings.latitude,
        longitude: settings.longitude,
        locationName: settings.locationName,
        simulationMode: settings.simulationMode,
        timeCompression: settings.timeCompression,
        simulationStartDate: settings.simulationStartDate,
        sunriseOffsetMinutes: settings.sunriseOffsetMinutes,
        sunsetOffsetMinutes: settings.sunsetOffsetMinutes,
        useIntensityCurve: settings.useIntensityCurve,
      );
      
      await _db.saveAstralSimulationSettings(newSettings);
      
      // Also update the zone's lighting mode to 'Astral' if enabling
      if (value) {
        await _db.saveLightingSettings(widget.zone.id!, 'Astral', 'None', 0, 0);
      }
      
      _settings = newSettings;
      _updatePreview();
    } catch (e) {
      debugPrint('Error toggling astral: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Astral Simulation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildEnableSwitch(),
                      const SizedBox(height: 24),
                      _buildLocationSection(),
                      const SizedBox(height: 24),
                      _buildSimulationModeSection(),
                      const SizedBox(height: 24),
                      _buildTimeCompressionSection(),
                      const SizedBox(height: 24),
                      _buildOffsetsSection(),
                      const SizedBox(height: 24),
                      _buildPreviewSection(),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.amber,
                        ),
                        child: const Text(
                          'SAVE CONFIGURATION',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEnableSwitch() {
    final isEnabled = _settings?.enabled ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? Colors.amber : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wb_sunny,
            color: isEnabled ? Colors.amber : Colors.white54,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Astral Simulation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isEnabled ? 'Active' : 'Disabled',
                  style: TextStyle(
                    color: isEnabled ? Colors.amber : Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: _toggleEnabled,
            activeColor: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LOCATION',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              TextFormField(
                initialValue: _locationName,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Location Name',
                  labelStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Icon(Icons.location_on, color: Colors.white54),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                onChanged: (val) => _locationName = val,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _latitude.toString(),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        labelStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _latitude = double.tryParse(val) ?? _latitude;
                          _updatePreview();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _longitude.toString(),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        labelStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _longitude = double.tryParse(val) ?? _longitude;
                          _updatePreview();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SIMULATION MODE',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('Full Year Cycle', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Simulate all 365 days', style: TextStyle(color: Colors.white54)),
                value: 'full_year',
                groupValue: _simulationMode,
                activeColor: Colors.amber,
                onChanged: (val) {
                  setState(() {
                    _simulationMode = val!;
                    _updatePreview();
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Fixed Day', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Constant photoperiod', style: TextStyle(color: Colors.white54)),
                value: 'fixed_day',
                groupValue: _simulationMode,
                activeColor: Colors.amber,
                onChanged: (val) {
                  setState(() {
                    _simulationMode = val!;
                    _updatePreview();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCompressionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TIME COMPRESSION',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Speed', style: TextStyle(color: Colors.white)),
                  Text(
                    '${_timeCompression.toStringAsFixed(1)}x',
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: _timeCompression,
                min: 1.0,
                max: 12.0,
                divisions: 11,
                activeColor: Colors.amber,
                label: '${_timeCompression.toStringAsFixed(1)}x',
                onChanged: (val) {
                  setState(() {
                    _timeCompression = val;
                    _updatePreview();
                  });
                },
              ),
              const Text(
                '1x = Real Time, 12x = 1 Year in 1 Month',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOffsetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OFFSETS & INTENSITY',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildOffsetSlider('Sunrise Offset', _sunriseOffset, (val) => _sunriseOffset = val),
              const Divider(color: Colors.white10),
              _buildOffsetSlider('Sunset Offset', _sunsetOffset, (val) => _sunsetOffset = val),
              const Divider(color: Colors.white10),
              SwitchListTile(
                title: const Text('Use Intensity Curve', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Ramp up/down at dawn/dusk', style: TextStyle(color: Colors.white54)),
                value: _useIntensityCurve,
                activeColor: Colors.amber,
                onChanged: (val) {
                  setState(() {
                    _useIntensityCurve = val;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOffsetSlider(String label, int value, Function(int) onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white)),
            Text(
              '$value min',
              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: -60,
          max: 60,
          divisions: 24,
          activeColor: Colors.amber,
          onChanged: (val) {
            setState(() {
              onChanged(val.round());
              _updatePreview();
            });
          },
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    if (_previewSunTimes == null || _previewSchedule == null) return const SizedBox.shrink();

    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat('HH:mm');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PREVIEW',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900.withOpacity(0.5), Colors.purple.shade900.withOpacity(0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: [
              Text(
                'Simulated Date: ${dateFormat.format(_previewDate)}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimeColumn('Sunrise', _previewSunTimes!.sunrise, Icons.wb_twilight),
                  _buildTimeColumn('Sunset', _previewSunTimes!.sunset, Icons.nightlight_round),
                  Column(
                    children: [
                      const Icon(Icons.timer, color: Colors.white70),
                      const SizedBox(height: 4),
                      const Text('Day Length', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        _previewSunTimes!.dayLengthFormatted,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'Lights On: ${_formatTimeOfDay(_previewSchedule!.lightsOn)}',
                      style: const TextStyle(color: Colors.amberAccent),
                    ),
                    Text(
                      'Lights Off: ${_formatTimeOfDay(_previewSchedule!.lightsOff)}',
                      style: const TextStyle(color: Colors.amberAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeColumn(String label, TimeOfDay time, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(
          _formatTimeOfDay(time),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }
}
