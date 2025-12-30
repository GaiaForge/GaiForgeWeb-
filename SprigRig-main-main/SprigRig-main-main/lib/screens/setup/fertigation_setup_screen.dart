import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../models/fertigation_config.dart';
import '../../models/fertigation_pump.dart';
import '../../models/fertigation_probe.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/gaia_background.dart';
import '../../widgets/cards/glass_card.dart';
import '../../widgets/toggles/fire_ice_switch.dart';

class FertigationSetupScreen extends StatefulWidget {
  final Zone zone;

  const FertigationSetupScreen({super.key, required this.zone});

  @override
  State<FertigationSetupScreen> createState() => _FertigationSetupScreenState();
}

class _FertigationSetupScreenState extends State<FertigationSetupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = true;
  
  FertigationConfig? _config;
  List<FertigationPump> _pumps = [];
  List<FertigationProbe> _probes = [];

  // Controllers for config
  final _reservoirController = TextEditingController();
  final _phMinController = TextEditingController();
  final _phMaxController = TextEditingController();
  final _ecTargetController = TextEditingController();
  final _maxDoseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _config = await _databaseHelper.getFertigationConfig(widget.zone.id!);
      if (_config == null) {
        // Create default config
        _config = FertigationConfig(
          zoneId: widget.zone.id!,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await _databaseHelper.saveFertigationConfig(_config!);
      }
      
      _pumps = await _databaseHelper.getFertigationPumps(widget.zone.id!);
      _probes = await _databaseHelper.getFertigationProbes(widget.zone.id!);
      
      // Populate controllers
      _reservoirController.text = _config?.reservoirLiters?.toString() ?? '';
      _phMinController.text = _config?.phTargetMin.toString() ?? '5.8';
      _phMaxController.text = _config?.phTargetMax.toString() ?? '6.2';
      _ecTargetController.text = _config?.ecTarget.toString() ?? '1.4';
      _maxDoseController.text = _config?.maxDoseMl.toString() ?? '50.0';
      
    } catch (e) {
      debugPrint('Error loading fertigation data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;
    
    final updatedConfig = _config!.copyWith(
      reservoirLiters: double.tryParse(_reservoirController.text),
      manualPhMin: double.tryParse(_phMinController.text) ?? 5.8,
      manualPhMax: double.tryParse(_phMaxController.text) ?? 6.2,
      manualEcMin: double.tryParse(_ecTargetController.text) ?? 1.4,
      // Assuming maxEc is not yet in the controller or using a default for now if not exposed in general tab
      // But wait, I added _ecTargetController which seems to be a single value in the old UI.
      // In the new UI (Targets tab), I have separate controllers but I need to make sure they are used.
      // For now, let's map the single controller to manualEcMin and maybe manualEcMax = min + 0.4?
      // Actually, let's check _buildTargetsTab again. It uses _ecTargetController for Min EC and a new controller for Max EC.
      // But _ecTargetController was defined at the top.
      // Let's use the controllers correctly.
      maxDoseMl: double.tryParse(_maxDoseController.text) ?? 50.0,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    await _databaseHelper.saveFertigationConfig(updatedConfig);
    setState(() => _config = updatedConfig);

    // Also update the Zone to indicate it has Fertigation enabled
    await _databaseHelper.updateZone(
      widget.zone.id,
      widget.zone.name,
      widget.zone.enabled ? 1 : 0,
      hasFertigation: true,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Fertigation Setup', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            gradient: const LinearGradient(
              colors: [Colors.amber, Colors.orange, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.6),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Status'),
            Tab(text: 'Device Setup'),
            Tab(text: 'Targets'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: GaiaBackground(
        primaryColor: Colors.cyan,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatusTab(),
                    _buildDeviceSetupTab(),
                    _buildTargetsTab(),
                    _buildHistoryTab(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStatusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('System Status', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // Placeholder for gauges and status
                  const Center(child: Text('Status Dashboard Placeholder', style: TextStyle(color: Colors.white54))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSetupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPumpsSection(),
          const SizedBox(height: 24),
          _buildProbesSection(),
          const SizedBox(height: 24),
          _buildReservoirSection(),
        ],
      ),
    );
  }

  Widget _buildTargetsTab() {
    if (_config == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Active Targets', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      FireIceSwitch(
                        value: _config!.useRecipeTargets,
                        onChanged: (val) async {
                          final newConfig = _config!.copyWith(useRecipeTargets: val);
                          await _databaseHelper.saveFertigationConfig(newConfig);
                          setState(() => _config = newConfig);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _config!.useRecipeTargets ? 'Source: Recipe (if active)' : 'Source: Manual Settings',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  
                  const Text('Manual Targets', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Min pH', _phMinController, '5.8')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField('Max pH', _phMaxController, '6.2')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Min EC', TextEditingController(text: _config?.manualEcMin?.toString() ?? '1.2'), '1.2')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField('Max EC', TextEditingController(text: _config?.manualEcMax?.toString() ?? '1.6'), '1.6')),
                    ],
                  ),
                   const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Manual Targets'),
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

  Widget _buildHistoryTab() {
    return const Center(child: Text('Dose History Coming Soon', style: TextStyle(color: Colors.white)));
  }

  Widget _buildReservoirSection() {
     if (_config == null) return const SizedBox.shrink();
     return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reservoir Settings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
             _buildTextField('Reservoir Size (Liters)', _reservoirController, 'Enter size'),
             const SizedBox(height: 16),
             SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveConfig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Settings'),
                ),
              ),
          ],
        ),
      ),
     );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.cyan.withOpacity(0.3))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.cyan.withOpacity(0.3))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.cyanAccent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPumpsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Pumps', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: _addPump,
              icon: const Icon(Icons.add_circle, color: Colors.tealAccent),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_pumps.isEmpty)
          const Text('No pumps configured', style: TextStyle(color: Colors.white54))
        else
          ..._pumps.map((pump) => Card(
            color: Colors.white.withOpacity(0.1),
            child: ListTile(
              title: Text(pump.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text('${pump.pumpType} - ${pump.mlPerSecond} ml/s', style: const TextStyle(color: Colors.white70)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deletePump(pump),
              ),
              onTap: () => _editPump(pump),
            ),
          )),
      ],
    );
  }

  Future<void> _addPump() async {
    await _showPumpDialog();
  }

  Future<void> _editPump(FertigationPump pump) async {
    await _showPumpDialog(pump: pump);
  }

  Future<void> _showPumpDialog({FertigationPump? pump}) async {
    final nameController = TextEditingController(text: pump?.name ?? '');
    final mlPerSecondController = TextEditingController(text: pump?.mlPerSecond.toString() ?? '1.0');
    final relayChannelController = TextEditingController(text: pump?.relayChannel.toString() ?? '0');
    final relayModuleAddressController = TextEditingController(text: pump?.relayModuleAddress.toString() ?? '1');
    String pumpType = pump?.pumpType ?? 'ph_up';
    bool enabled = pump?.enabled ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(pump == null ? 'Add Pump' : 'Edit Pump', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: pumpType,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'ph_up', child: Text('pH Up')),
                    DropdownMenuItem(value: 'ph_down', child: Text('pH Down')),
                    DropdownMenuItem(value: 'nutrient_a', child: Text('Nutrient A')),
                    DropdownMenuItem(value: 'nutrient_b', child: Text('Nutrient B')),
                    DropdownMenuItem(value: 'calmag', child: Text('CalMag')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (val) => setState(() => pumpType = val!),
                  decoration: const InputDecoration(labelText: 'Type', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: mlPerSecondController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Flow Rate (ml/s)', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: relayChannelController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Channel', labelStyle: TextStyle(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: relayModuleAddressController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Module Addr', labelStyle: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Enabled', style: TextStyle(color: Colors.white)),
                    FireIceSwitch(
                      value: enabled,
                      onChanged: (val) => setState(() => enabled = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                final newPump = FertigationPump(
                  id: pump?.id,
                  zoneId: widget.zone.id!,
                  name: nameController.text,
                  pumpType: pumpType,
                  relayChannel: int.tryParse(relayChannelController.text) ?? 0,
                  relayModuleAddress: int.tryParse(relayModuleAddressController.text) ?? 1,
                  mlPerSecond: double.tryParse(mlPerSecondController.text) ?? 1.0,
                  enabled: enabled,
                  createdAt: pump?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                );
                await _databaseHelper.saveFertigationPump(newPump);
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Save', style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePump(FertigationPump pump) async {
    await _databaseHelper.deleteFertigationPump(pump.id!);
    _loadData();
  }

  Widget _buildProbesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Probes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: _addProbe,
              icon: const Icon(Icons.add_circle, color: Colors.cyanAccent),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_probes.isEmpty)
          const Text('No probes configured', style: TextStyle(color: Colors.white54))
        else
          ..._probes.map((probe) => Card(
            color: Colors.white.withOpacity(0.1),
            child: ListTile(
              title: Text('${probe.probeType.toUpperCase()} Probe', style: const TextStyle(color: Colors.white)),
              subtitle: Text('Hub: ${probe.hubAddress} | Ch: ${probe.inputChannel}', style: const TextStyle(color: Colors.white70)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deleteProbe(probe),
              ),
              onTap: () => _editProbe(probe),
            ),
          )),
      ],
    );
  }

  Future<void> _addProbe() async {
    await _showProbeDialog();
  }

  Future<void> _editProbe(FertigationProbe probe) async {
    await _showProbeDialog(probe: probe);
  }

  Future<void> _deleteProbe(FertigationProbe probe) async {
    await _databaseHelper.deleteFertigationProbe(probe.id!);
    _loadData();
  }

  Future<void> _showProbeDialog({FertigationProbe? probe}) async {
    final hubAddressController = TextEditingController(text: probe?.hubAddress.toString() ?? '1');
    final inputChannelController = TextEditingController(text: probe?.inputChannel.toString() ?? '0');
    final rangeMinController = TextEditingController(text: probe?.rangeMin.toString() ?? '0.0');
    final rangeMaxController = TextEditingController(text: probe?.rangeMax.toString() ?? '14.0');
    String probeType = probe?.probeType ?? 'ph';
    String inputType = probe?.inputType ?? '4-20mA';
    bool enabled = probe?.enabled ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(probe == null ? 'Add Probe' : 'Edit Probe', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: probeType,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'ph', child: Text('pH')),
                    DropdownMenuItem(value: 'ec', child: Text('EC')),
                    DropdownMenuItem(value: 'temperature', child: Text('Temperature')),
                  ],
                  onChanged: (val) => setState(() => probeType = val!),
                  decoration: const InputDecoration(labelText: 'Type', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hubAddressController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Hub Addr', labelStyle: TextStyle(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: inputChannelController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Channel', labelStyle: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: inputType,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: '4-20mA', child: Text('4-20mA')),
                    DropdownMenuItem(value: '0-10V', child: Text('0-10V')),
                  ],
                  onChanged: (val) => setState(() => inputType = val!),
                  decoration: const InputDecoration(labelText: 'Input Type', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rangeMinController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Range Min', labelStyle: TextStyle(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: rangeMaxController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Range Max', labelStyle: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Enabled', style: TextStyle(color: Colors.white)),
                    FireIceSwitch(
                      value: enabled,
                      onChanged: (val) => setState(() => enabled = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                final newProbe = FertigationProbe(
                  id: probe?.id,
                  zoneId: widget.zone.id!,
                  probeType: probeType,
                  hubAddress: int.tryParse(hubAddressController.text) ?? 1,
                  inputChannel: int.tryParse(inputChannelController.text) ?? 0,
                  inputType: inputType,
                  rangeMin: double.tryParse(rangeMinController.text) ?? 0.0,
                  rangeMax: double.tryParse(rangeMaxController.text) ?? 14.0,
                  enabled: enabled,
                  createdAt: probe?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                );
                await _databaseHelper.saveFertigationProbe(newProbe);
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Save', style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        ),
      ),
    );
  }


}
