import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../models/io_channel.dart';
import '../../models/sensor_hub.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';
import '../../services/modbus_service.dart';
import '../../widgets/common/app_background.dart';
import 'relay_test_screen.dart';
import 'wifi_settings_tab.dart';
import 'user_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;

  // Modbus Settings
  final _relayPortController = TextEditingController();
  final _hubPortController = TextEditingController();
  int _relayBaudRate = 9600;
  int _hubBaudRate = 9600;
  final List<int> _baudRates = [4800, 9600, 19200, 38400, 57600, 115200];

  // Hub Topology
  List<SensorHub> _hubs = [];

  // IO Assignments
  List<IoChannel> _ioChannels = [];
  int _selectedModule = 100; // Default to Relay Board (100)
  List<Map<String, dynamic>> _availableModules = [
    {'id': 100, 'name': 'Waveshare Relay Board (Main)'}
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSettings();
  }

  // ... (lines 47-120)



  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    // Load Modbus Settings
    _relayPortController.text = await _db.getSetting('modbus_relay_port') ?? '/dev/ttyUSB0';
    _hubPortController.text = await _db.getSetting('modbus_hub_port') ?? '/dev/ttyUSB1';
    _relayBaudRate = await _db.getIntSetting('modbus_relay_baud', defaultValue: 9600);
    _hubBaudRate = await _db.getIntSetting('modbus_hub_baud', defaultValue: 9600);

    // Load Hubs
    _hubs = await _db.getSensorHubs();
    
    // Update available modules for IO tab
    _availableModules = [
      {'id': 100, 'name': 'Waveshare Relay Board (Main)'}
    ];
    for (var hub in _hubs) {
      _availableModules.add({
        'id': hub.id, // Using hub ID as module number for simplicity
        'name': '${hub.name} (Hub #${hub.id})'
      });
    }

    // Ensure selected module is valid
    if (!_availableModules.any((m) => m['id'] == _selectedModule)) {
      _selectedModule = 100;
    }

    // Load IO Channels for selected module
    await _loadIoChannels();

    setState(() => _isLoading = false);
  }

  Future<void> _loadIoChannels() async {
    _ioChannels = await _db.getIoChannelsByModule(_selectedModule);
    setState(() {});
  }

  Future<void> _saveModbusSettings() async {
    await _db.saveStringSetting('modbus_relay_port', _relayPortController.text);
    await _db.saveStringSetting('modbus_hub_port', _hubPortController.text);
    await _db.saveIntSetting('modbus_relay_baud', _relayBaudRate);
    await _db.saveIntSetting('modbus_hub_baud', _hubBaudRate);
    
    // Reload service with new settings
    await ModbusService().reloadSettings();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modbus settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('System Settings', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(icon: Icon(Icons.wifi), text: 'Network'),
              Tab(icon: Icon(Icons.settings_ethernet), text: 'Modbus'),
              Tab(icon: Icon(Icons.hub), text: 'Topology'),
              Tab(icon: Icon(Icons.input), text: 'IO Assignments'),
              Tab(icon: Icon(Icons.people), text: 'Users'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : TabBarView(
                controller: _tabController,
                children: [
                  const WifiSettingsTab(),
                  _buildModbusTab(),
                  _buildTopologyTab(),
                  _buildIoAssignmentsTab(),
                  _buildUserPermissionsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildModbusTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Relay Channel (Channel 1)'),
        _buildGlassCard(
          child: Column(
            children: [
              VirtualKeyboardTextField(
                controller: _relayPortController,
                label: 'Port (e.g., /dev/ttyUSB0)',
                hintText: 'Serial port for Waveshare Relay Board',
                textColor: Colors.white,
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                value: _relayBaudRate,
                label: 'Baud Rate',
                items: _baudRates,
                onChanged: (v) => setState(() => _relayBaudRate = v!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Hub Channel (Channel 2)'),
        _buildGlassCard(
          child: Column(
            children: [
              VirtualKeyboardTextField(
                controller: _hubPortController,
                label: 'Port (e.g., /dev/ttyUSB1)',
                hintText: 'Serial port for Sensor Hubs',
                textColor: Colors.white,
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                value: _hubBaudRate,
                label: 'Baud Rate',
                items: _baudRates,
                onChanged: (v) => setState(() => _hubBaudRate = v!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _saveModbusSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader('Diagnostics'),
        _buildGlassCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.build, color: Colors.orange),
            ),
            title: const Text('Relay Board Test', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Manually toggle relays to verify hardware', style: TextStyle(color: Colors.white.withOpacity(0.6))),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RelayTestScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String label,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: Colors.grey.shade900,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.amber),
        ),
        filled: true,
        fillColor: Colors.black12,
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text('$item'),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTopologyTab() {
    return Stack(
      children: [
        if (_hubs.isEmpty)
          Center(child: Text('No Sensor Hubs Configured', style: TextStyle(color: Colors.white.withOpacity(0.5))))
        else
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _hubs.length,
            itemBuilder: (context, index) {
              final hub = _hubs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildGlassCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.router, color: Colors.blue),
                    ),
                    title: Text(hub.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: FutureBuilder<String>(
                      future: ModbusService().checkHubStatus(hub.modbusAddress),
                      builder: (context, snapshot) {
                        final status = snapshot.data ?? 'Checking...';
                        Color statusColor = Colors.grey;
                        if (status == 'Connected') statusColor = Colors.greenAccent;
                        if (status == 'Disconnected') statusColor = Colors.redAccent;
                        if (status == 'Mock') statusColor = Colors.orangeAccent;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modbus ID: ${hub.modbusAddress} | Channels: ${hub.totalChannels}',
                              style: TextStyle(color: Colors.white.withOpacity(0.6)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8, 
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statusColor, 
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 4, spreadRadius: 1),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  status.toUpperCase(), 
                                  style: TextStyle(
                                    color: statusColor, 
                                    fontSize: 11, 
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteHub(hub),
                    ),
                    onTap: () => _editHub(hub),
                  ),
                ),
              );
            },
          ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            onPressed: _addHub,
            backgroundColor: Colors.amber,
            child: const Icon(Icons.add, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildIoAssignmentsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildGlassCard(
            child: DropdownButtonFormField<int>(
              value: _selectedModule,
              dropdownColor: Colors.grey.shade900,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Select Module',
                labelStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                filled: false,
              ),
              items: _availableModules.map((m) {
                return DropdownMenuItem<int>(
                  value: m['id'] as int,
                  child: Text(m['name'] as String),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedModule = val);
                  _loadIoChannels();
                }
              },
            ),
          ),
        ),
        Expanded(
          child: _ioChannels.isEmpty 
            ? Center(child: Text('No channels found for this module', style: TextStyle(color: Colors.white.withOpacity(0.5))))
            : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _ioChannels.length,
            itemBuilder: (context, index) {
              final channel = _ioChannels[index];
              final isAssigned = channel.isAssigned;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildGlassCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: isAssigned ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                      child: Text(
                        '${channel.channelNumber + 1}',
                        style: TextStyle(
                          color: isAssigned ? Colors.green : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      channel.name ?? 'Unnamed Channel',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (channel.type != null)
                          Text(
                            'Type: ${channel.type!.toUpperCase()}',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                          ),
                        Text(
                          isAssigned 
                              ? 'Assigned to: ${channel.assignedTo ?? "Unknown System"}' 
                              : 'Available',
                          style: TextStyle(
                            color: isAssigned ? Colors.greenAccent : Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: isAssigned
                        ? IconButton(
                            icon: const Icon(Icons.link_off, color: Colors.redAccent),
                            onPressed: () => _confirmClearAssignment(channel),
                          )
                        : Icon(Icons.check_circle_outline, color: Colors.white.withOpacity(0.1)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold,
          color: Colors.amber,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _addHub() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    // Channels is now fixed to 11 based on hardware spec
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Add Sensor Hub', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VirtualKeyboardTextField(controller: nameController, label: 'Hub Name', textColor: Colors.white),
            const SizedBox(height: 16),
            VirtualKeyboardTextField(controller: addressController, label: 'Modbus Address (ID)', keyboardType: TextInputType.number, textColor: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Standard Hub Topology: 11 Channels\n(4 DI, 2 AI, 2 AO, 2 I2C, 1 SPI)',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () async {
              if (nameController.text.isNotEmpty && addressController.text.isNotEmpty) {
                final hub = SensorHub(
                  id: 0, // Auto-increment handled by DB helper
                  name: nameController.text,
                  modbusAddress: int.parse(addressController.text),
                  totalChannels: 11, // Fixed
                  createdAt: DateTime.now().toIso8601String(),
                );
                
                final newId = await _db.insertSensorHub(hub);
                
                // Create IO channels for this hub (using hub ID as module number)
                await _db.createIoChannelsForModule(newId, 11, prefix: '${nameController.text} Ch');
                
                Navigator.pop(context);
                _loadSettings();
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _editHub(SensorHub hub) async {
    // Placeholder for edit functionality
  }

  Future<void> _deleteHub(SensorHub hub) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Delete Hub?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${hub.name}"? This will also remove associated IO channels.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteSensorHub(hub.id);
      _loadSettings();
    }
  }

  Future<void> _confirmClearAssignment(IoChannel channel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Warning: Active Assignment', style: TextStyle(color: Colors.white)),
        content: Text(
          'Channel ${channel.channelNumber + 1} is currently assigned to "${channel.assignedTo}".\n\n'
          'Clearing this assignment will affect schedules and system operation. '
          'Are you sure you want to proceed?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Assignment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.assignIoChannel(channel.id, false);
      _loadIoChannels();
    }
  }

  Widget _buildUserPermissionsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          const Text(
            'User Permissions',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage users, roles, and access control.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserManagementScreen()),
              );
            },
            icon: const Icon(Icons.manage_accounts),
            label: const Text('Manage Users'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
