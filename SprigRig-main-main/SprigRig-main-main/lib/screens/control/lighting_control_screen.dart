import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../models/environmental_control.dart';
import '../../services/database_helper.dart';
import '../../services/env_control_service.dart';
import '../../widgets/common/app_background.dart';

class LightingControlScreen extends StatefulWidget {
  final Zone zone;

  const LightingControlScreen({super.key, required this.zone});

  @override
  State<LightingControlScreen> createState() => _LightingControlScreenState();
}

class _LightingControlScreenState extends State<LightingControlScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final EnvironmentalControlService _envControl = EnvironmentalControlService.instance;
  
  List<EnvironmentalControl> _lights = [];
  bool _isLoading = true;
  bool _isManualMode = false; // Tracks if user has overridden the schedule
  Map<int, bool> _lightStates = {};
  Map<int, double> _lightIntensity = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch all controls for the zone
      final allControls = await _db.getZoneControls(widget.zone.id!);
      
      // Filter for lights (Type 1: Grow Light, Type 2: UV Light)
      _lights = allControls.where((c) => [1, 2].contains(c.controlTypeId)).toList();
      
      // Initialize states
      for (var light in _lights) {
        if (!_lightStates.containsKey(light.id)) {
          _lightStates[light.id] = false; // Default to off
          _lightIntensity[light.id] = 100.0; // Default to full brightness
        }
      }

    } catch (e) {
      debugPrint('Error loading lighting data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleLight(EnvironmentalControl light, bool value) async {
    setState(() {
      _lightStates[light.id] = value;
      _isManualMode = true; // User interaction triggers manual mode
    });

    try {
      await _envControl.setControl(light.id, value);
    } catch (e) {
      debugPrint('Error toggling light: $e');
    }
  }

  Future<void> _setIntensity(EnvironmentalControl light, double intensity) async {
    setState(() {
      _lightIntensity[light.id] = intensity;
      _isManualMode = true;
    });
    // await _envControl.setLightIntensity(light.id, intensity);
  }

  void _resumeSchedule() {
    setState(() {
      _isManualMode = false;
      // In a real app, we would re-evaluate the schedule and set states accordingly
      // For now, we'll just reset to a "scheduled" state (e.g., all off or based on time)
      // Let's just show a snackbar
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resumed automated schedule'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Lighting Control'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isManualMode)
            TextButton(
              onPressed: _resumeSchedule,
              child: const Text(
                'Resume Schedule',
                style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isManualMode)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber, color: Colors.amber),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Manual Override Active',
                                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                        _buildSectionHeader('Manual Light Control', Icons.light_mode),
                        const SizedBox(height: 16),
                        if (_lights.isEmpty)
                          _buildEmptyState('No lights configured for this zone.')
                        else
                          _buildLightsList(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.amber, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLightsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _lights.length,
      itemBuilder: (context, index) {
        final light = _lights[index];
        final isOn = _lightStates[light.id] ?? false;
        final intensity = _lightIntensity[light.id] ?? 100.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isOn ? Colors.amber.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOn ? Colors.amber.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                    width: isOn ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isOn ? Colors.amber : Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            boxShadow: isOn ? [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ] : null,
                          ),
                          child: Icon(
                            Icons.lightbulb,
                            color: isOn ? Colors.white : Colors.white38,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                light.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                light.controlTypeId == 2 ? 'UV Light' : 'Grow Light',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isOn,
                          onChanged: (value) => _toggleLight(light, value),
                          activeColor: Colors.amber,
                          activeTrackColor: Colors.amber.withOpacity(0.3),
                        ),
                      ],
                    ),
                    if (isOn) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.brightness_6, color: Colors.white54, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Intensity: ${intensity.round()}%',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                      Slider(
                        value: intensity,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        activeColor: Colors.amber,
                        inactiveColor: Colors.white.withOpacity(0.1),
                        onChanged: (value) => _setIntensity(light, value),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
