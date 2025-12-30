import 'package:flutter/material.dart';
import '../../models/sensor_hub.dart';
import '../../services/sensor_hub_service.dart';
import '../../services/database_helper.dart';
import 'hub_detail_screen.dart';

class HubNetworkScreen extends StatefulWidget {
  const HubNetworkScreen({super.key});

  @override
  State<HubNetworkScreen> createState() => _HubNetworkScreenState();
}

class _HubNetworkScreenState extends State<HubNetworkScreen> {
  final SensorHubService _hubService = SensorHubService();
  final DatabaseHelper _db = DatabaseHelper();
  List<SensorHub> _hubs = [];
  bool _isLoading = true;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadHubs();
    _hubService.init(); // Ensure service is initialized
  }

  Future<void> _loadHubs() async {
    setState(() => _isLoading = true);
    final hubs = await _db.getSensorHubs();
    setState(() {
      _hubs = hubs;
      _isLoading = false;
    });
  }

  Future<void> _scanForHubs() async {
    setState(() => _isScanning = true);
    try {
      final newHubs = await _hubService.discoverHubs();
      if (newHubs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found ${newHubs.length} new hubs!')),
        );
        await _loadHubs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No new hubs found.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning: $e')),
      );
    } finally {
      setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Hub Network'),
        actions: [
          IconButton(
            icon: _isScanning 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _scanForHubs,
            tooltip: 'Scan for Hubs',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hubs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hub, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No Sensor Hubs Found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Tap the scan button to discover hubs on the network.'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _scanForHubs,
                        icon: const Icon(Icons.search),
                        label: const Text('Scan Network'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _hubs.length,
                  itemBuilder: (context, index) {
                    final hub = _hubs[index];
                    return _buildHubCard(hub);
                  },
                ),
    );
  }

  Widget _buildHubCard(SensorHub hub) {
    final isOnline = hub.status == 'online';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HubDetailScreen(hub: hub)),
          );
          _loadHubs(); // Refresh on return
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status Indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isOnline ? Colors.green : Colors.red).withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Hub Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hub.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Address: ${hub.modbusAddress} • Channels: ${hub.totalChannels}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Arrow
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
