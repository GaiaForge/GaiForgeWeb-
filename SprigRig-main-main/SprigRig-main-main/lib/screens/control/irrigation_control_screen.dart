import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../models/environmental_control.dart';
import '../../models/sensor.dart';
import '../../services/database_helper.dart';
import '../../services/env_control_service.dart';
import '../../widgets/common/app_background.dart';

class IrrigationControlScreen extends StatefulWidget {
  final Zone zone;

  const IrrigationControlScreen({super.key, required this.zone});

  @override
  State<IrrigationControlScreen> createState() => _IrrigationControlScreenState();
}

class _IrrigationControlScreenState extends State<IrrigationControlScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final EnvironmentalControlService _envControl = EnvironmentalControlService.instance;
  
  List<EnvironmentalControl> _pumps = [];
  List<Sensor> _flowSensors = [];
  bool _isLoading = true;
  Map<int, bool> _pumpStates = {}; // Local state for immediate UI feedback

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
      
      // Filter for pumps (Type 5: Water Pump, Type 6: Nutrient Pump)
      _pumps = allControls.where((c) => c.controlTypeId == 5 || c.controlTypeId == 6).toList();
      
      // Initialize states (in a real app, we'd fetch current hardware state)
      // For now, we assume they are off unless we have a way to query state
      // We can use the 'enabled' flag as a proxy for "available", but actual ON/OFF state 
      // is usually transient. For this demo, we'll track it locally.
      for (var pump in _pumps) {
        if (!_pumpStates.containsKey(pump.id)) {
          _pumpStates[pump.id] = false;
        }
      }

      // Fetch sensors
      final allSensors = await _db.getZoneSensors(widget.zone.id!);
      _flowSensors = allSensors.where((s) => s.sensorType == 'flow_rate').toList();

    } catch (e) {
      debugPrint('Error loading irrigation data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _togglePump(EnvironmentalControl pump, bool value) async {
    try {
      // Update local state immediately for responsiveness
      setState(() {
        _pumpStates[pump.id] = value;
      });

      // Send command to hardware service
      await _envControl.setControl(pump.id, value);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pump.name} turned ${value ? 'ON' : 'OFF'}'),
          backgroundColor: value ? Colors.blue : Colors.grey,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Revert state on error
      setState(() {
        _pumpStates[pump.id] = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Irrigation Control'),
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
                        if (_flowSensors.isNotEmpty) ...[
                          _buildSectionHeader('Flow Monitoring', Icons.waves),
                          const SizedBox(height: 16),
                          _buildFlowSensorsGrid(),
                          const SizedBox(height: 32),
                        ],
                        
                        _buildSectionHeader('Manual Pump Control', Icons.water_drop),
                        const SizedBox(height: 16),
                        if (_pumps.isEmpty)
                          _buildEmptyState('No pumps configured for this zone.')
                        else
                          _buildPumpsList(),
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
        Icon(icon, color: Colors.blueAccent, size: 24),
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

  Widget _buildFlowSensorsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _flowSensors.length,
      itemBuilder: (context, index) {
        final sensor = _flowSensors[index];
        // Simulate flow reading (replace with real data in production)
        final flowRate = sensor.enabled ? '2.5 L/min' : '--';
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyan.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.waves, color: Colors.cyan, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sensor.name,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    flowRate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Current Flow',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPumpsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pumps.length,
      itemBuilder: (context, index) {
        final pump = _pumps[index];
        final isOn = _pumpStates[pump.id] ?? false;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isOn ? Colors.blue.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOn ? Colors.blue.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                    width: isOn ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isOn ? Colors.blue : Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: isOn ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ] : null,
                      ),
                      child: Icon(
                        Icons.water_drop,
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
                            pump.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            pump.controlTypeId == 6 ? 'Nutrient Pump' : 'Water Pump',
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
                      onChanged: (value) => _togglePump(pump, value),
                      activeColor: Colors.blue,
                      activeTrackColor: Colors.blue.withOpacity(0.3),
                    ),
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
