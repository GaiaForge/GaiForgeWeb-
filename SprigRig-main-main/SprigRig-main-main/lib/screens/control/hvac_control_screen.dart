import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../models/environmental_control.dart';
import '../../services/database_helper.dart';
import '../../services/env_control_service.dart';
import '../../widgets/common/app_background.dart';

class HvacControlScreen extends StatefulWidget {
  final Zone zone;

  const HvacControlScreen({super.key, required this.zone});

  @override
  State<HvacControlScreen> createState() => _HvacControlScreenState();
}

class _HvacControlScreenState extends State<HvacControlScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final EnvironmentalControlService _envControl = EnvironmentalControlService.instance;
  
  List<EnvironmentalControl> _fans = [];
  bool _isLoading = true;
  Map<int, bool> _fanStates = {};
  Map<int, double> _fanSpeeds = {}; // For variable speed fans

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
      
      // Filter for fans (Type 3: Intake Fan, Type 4: Exhaust Fan, Type 7: Circulation Fan)
      _fans = allControls.where((c) => [3, 4, 7].contains(c.controlTypeId)).toList();
      
      // Initialize states
      for (var fan in _fans) {
        if (!_fanStates.containsKey(fan.id)) {
          _fanStates[fan.id] = false; // Default to off
          _fanSpeeds[fan.id] = 100.0; // Default to full speed
        }
      }

    } catch (e) {
      debugPrint('Error loading ventilation data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFan(EnvironmentalControl fan, bool value) async {
    try {
      setState(() {
        _fanStates[fan.id] = value;
      });

      await _envControl.setControl(fan.id, value);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${fan.name} turned ${value ? 'ON' : 'OFF'}'),
          backgroundColor: value ? Colors.green : Colors.grey,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      setState(() {
        _fanStates[fan.id] = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _setFanSpeed(EnvironmentalControl fan, double speed) async {
    setState(() {
      _fanSpeeds[fan.id] = speed;
    });
    // In a real implementation, we would send a PWM or analog signal here
    // await _envControl.setFanSpeed(fan.id, speed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('HVAC Control'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
                        _buildSectionHeader('Manual Fan Control', Icons.wind_power),
                        const SizedBox(height: 16),
                        if (_fans.isEmpty)
                          _buildEmptyState('No fans configured for this zone.')
                        else
                          _buildFansList(),
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
        Icon(icon, color: Colors.cyanAccent, size: 24),
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

  Widget _buildFansList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _fans.length,
      itemBuilder: (context, index) {
        final fan = _fans[index];
        final isOn = _fanStates[fan.id] ?? false;
        final speed = _fanSpeeds[fan.id] ?? 100.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isOn ? Colors.cyan.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOn ? Colors.cyan.withOpacity(0.5) : Colors.white.withOpacity(0.1),
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
                            color: isOn ? Colors.cyan : Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            boxShadow: isOn ? [
                              BoxShadow(
                                color: Colors.cyan.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ] : null,
                          ),
                          child: Icon(
                            Icons.cyclone,
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
                                fan.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getFanType(fan.controlTypeId),
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
                          onChanged: (value) => _toggleFan(fan, value),
                          activeColor: Colors.cyan,
                          activeTrackColor: Colors.cyan.withOpacity(0.3),
                        ),
                      ],
                    ),
                    if (isOn) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.speed, color: Colors.white54, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Speed: ${speed.round()}%',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                      Slider(
                        value: speed,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        activeColor: Colors.cyan,
                        inactiveColor: Colors.white.withOpacity(0.1),
                        onChanged: (value) => _setFanSpeed(fan, value),
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

  String _getFanType(int typeId) {
    switch (typeId) {
      case 3: return 'Intake Fan';
      case 4: return 'Exhaust Fan';
      case 7: return 'Circulation Fan';
      default: return 'Fan';
    }
  }
}
