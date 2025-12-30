import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../services/modbus_service.dart';
import '../../widgets/common/app_background.dart';
import '../../models/sensor_hub.dart';

class TopologySetupScreen extends StatefulWidget {
  const TopologySetupScreen({super.key});

  @override
  State<TopologySetupScreen> createState() => _TopologySetupScreenState();
}

class _TopologySetupScreenState extends State<TopologySetupScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final ModbusService _modbus = ModbusService();
  
  // State
  List<SensorHub> _hubs = [];
  bool _isLoading = true;
  
  // Relay Configuration
  int _relayChannelCount = 8; // 8, 16, or 32
  int _relayAddress = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load Hubs
    _hubs = await _db.getSensorHubs();
    
    // Load Relay Config (mock for now, should be in DB settings)
    final relayType = await _db.getSetting('relay_board_type') ?? '8_channel';
    _relayChannelCount = int.tryParse(relayType.split('_')[0]) ?? 8;
    
    setState(() => _isLoading = false);
  }

  Future<void> _scanHubs() async {
    setState(() => _isLoading = true);
    try {
      // Trigger scan in service (assuming service exists and is linked)
      // For now, we'll use ModbusService directly or mock
      // final newHubs = await SensorHubService().discoverHubs();
      // _loadData();
      
      // Mock scan for demo
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock: Ensure at least one hub exists and generate its IOs
      if (_hubs.isEmpty) {
        final mockHub = SensorHub(
          id: 0, 
          modbusAddress: 1, 
          name: 'Hub #1', 
          status: 'online', 
          createdAt: DateTime.now().toIso8601String()
        );
        await _db.insertSensorHub(mockHub);
        await _db.generateHubChannels(1);
        _loadData();
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan complete.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('System Topology'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 40),
                      _buildBusVisualization(
                        title: 'Bus 1: Relay Control',
                        color: Colors.orangeAccent,
                        icon: Icons.power,
                        child: _buildRelayNode(),
                      ),
                      const SizedBox(height: 40),
                      _buildBusVisualization(
                        title: 'Bus 2: Sensor Network',
                        color: Colors.cyanAccent,
                        icon: Icons.sensors,
                        child: _buildHubNodes(),
                        onAdd: _scanHubs,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Network Topology',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Configure your RS485 buses. Bus 1 is dedicated to high-power relays. Bus 2 handles the sensor mesh.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildBusVisualization({
    required String title,
    required Color color,
    required IconData icon,
    required Widget child,
    VoidCallback? onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            if (onAdd != null) ...[
              const Spacer(),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.refresh, color: Colors.white70),
                tooltip: 'Scan for Devices',
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Stack(
            children: [
              // The "Bus" Line
              Positioned(
                top: 24,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.1), color, color.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // The Nodes
              child,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRelayNode() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orangeAccent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.memory, color: Colors.white, size: 32),
                const SizedBox(height: 4),
                Text(
                  'Waveshare\n$_relayChannelCount-CH',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              'Addr: $_relayAddress',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Courier'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showRelayConfigDialog,
            child: const Text('Configure', style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildHubNodes() {
    if (_hubs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text(
            'No hubs detected.\nCheck connections and scan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _hubs.map((hub) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hub.status == 'online' ? Colors.cyanAccent : Colors.redAccent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (hub.status == 'online' ? Colors.cyanAccent : Colors.redAccent).withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hub, color: Colors.white, size: 32),
                      Text(
                        'ID: ${hub.modbusAddress}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    hub.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showRelayConfigDialog() async {
    int tempChannels = _relayChannelCount;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Relay Configuration', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select your Waveshare Modbus RTU Relay model:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<int>(
                value: tempChannels,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Channel Count',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orangeAccent)),
                ),
                items: const [
                  DropdownMenuItem(value: 8, child: Text('8 Channels')),
                  DropdownMenuItem(value: 16, child: Text('16 Channels')),
                  DropdownMenuItem(value: 32, child: Text('32 Channels')),
                ],
                onChanged: (val) => setState(() => tempChannels = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _db.saveSetting('relay_board_type', '${tempChannels}_channel', 'string');
                await _db.generateRelayChannels(tempChannels);
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.orangeAccent)),
            ),
          ],
        ),
      ),
    );
  }
}
