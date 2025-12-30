import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/zone.dart';
import '../../models/guardian_config.dart';
import '../../models/guardian_report.dart';
import '../../services/database_helper.dart';
import '../../services/camera_service.dart';
import '../../widgets/common/sprigrig_background.dart';
import '../../widgets/common/sprigrig_num_pad.dart';
import '../../widgets/common/sprigrig_keyboard.dart';
import '../../widgets/cards/glass_card.dart';
import '../../services/anthropic_service.dart';
import '../../services/secure_storage_service.dart';
import 'package:uuid/uuid.dart';

class GuardianSetupScreen extends StatefulWidget {
  final Zone zone;

  const GuardianSetupScreen({super.key, required this.zone});

  @override
  State<GuardianSetupScreen> createState() => _GuardianSetupScreenState();
}

class _GuardianSetupScreenState extends State<GuardianSetupScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final CameraService _cameraService = CameraService.instance;
  
  bool _isLoading = true;
  GuardianConfig? _config;
  List<GuardianReport> _recentReports = [];
  List<Map<String, dynamic>> _availableCameras = [];
  
  List<Map<String, dynamic>> _apiKeys = [];
  String? _activeKeyId;
  
  // Controllers (we'll use strings to manage state for custom keyboard)
  // String _apiKey = ''; // Removed legacy field
  String _checkInterval = '24';
  String _alertSensitivity = 'medium';
  
  // Voice Settings
  bool _voiceEnabled = false;
  String _wakeWord = 'sprigrig';
  String? _selectedMic;
  String? _selectedSpeaker;
  bool _proactiveVoice = true;
  
  // Camera Settings
  String? _selectedCamera;
  bool _captureOnSchedule = true;

  // AI Actions Settings
  bool _actionsEnabled = false;
  Map<String, bool> _actionPermissions = {
    'fertigation_ph': false,
    'fertigation_ec': false,
    'fertigation_pumps': false,
    'lighting': false,
    'hvac': false,
    'irrigation': false,
    'recipes': false,
    'setpoints': false,
  };
  bool _requireConfirmation = true;
  int _actionCooldownMinutes = 5;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _config = await _databaseHelper.getGuardianConfig(widget.zone.id!);
      if (_config == null) {
        _config = GuardianConfig(
          zoneId: widget.zone.id!,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await _databaseHelper.saveGuardianConfig(_config!);
      }
      
      // Load keys
      _apiKeys = await _databaseHelper.getGuardianApiKeys();
      
      // Migration: If we have a legacy key in config but no active key ID
      if (_config?.apiKey != null && _config!.apiKey!.isNotEmpty && _config?.activeKeyId == null) {
        final newId = const Uuid().v4();
        await SecureStorageService().saveApiKey(newId, _config!.apiKey!);
        await _databaseHelper.insertGuardianApiKey({
          'id': newId,
          'name': 'Legacy Key',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'last_used_at': DateTime.now().millisecondsSinceEpoch,
        });
        
        // Update config immediately to reflect migration
        final migratedConfig = _config!.copyWith(
          activeKeyId: newId,
          apiKey: null, // Clear legacy field
        );
        await _databaseHelper.saveGuardianConfig(migratedConfig);
        _config = migratedConfig;
        
        // Reload keys
        _apiKeys = await _databaseHelper.getGuardianApiKeys();
      }

      // Load values
      _activeKeyId = _config?.activeKeyId;
      // _apiKey = _config?.apiKey ?? ''; // Removed legacy field
      _checkInterval = _config?.checkIntervalHours.toString() ?? '24';
      _alertSensitivity = _config?.alertSensitivity ?? 'medium';
      
      // Load new fields
      _voiceEnabled = _config?.voiceEnabled ?? false;
      _wakeWord = _config?.wakeWord ?? 'sprigrig';
      _selectedMic = _config?.microphoneDeviceId;
      _selectedSpeaker = _config?.speakerDeviceId;
      _proactiveVoice = _config?.proactiveVoice ?? true;
      _selectedCamera = _config?.cameraDeviceId;
      _captureOnSchedule = _config?.captureOnSchedule ?? true;
      
      // Load action settings
      _actionsEnabled = _config?.actionsEnabled ?? false;
      _actionPermissions = Map<String, bool>.from(_config?.actionPermissions ?? {});
      _requireConfirmation = _config?.requireConfirmation ?? true;
      _actionCooldownMinutes = _config?.actionCooldownMinutes ?? 5;

      // Load reports
      _recentReports = await _databaseHelper.getGuardianReports(widget.zone.id!);
      
      // Load cameras
      try {
        _availableCameras = await _cameraService.detectCameras();
      } catch (e) {
        debugPrint('Error detecting cameras: $e');
        // Mock if failed (e.g. dev environment)
        _availableCameras = [
          {'id': 'cam0', 'name': 'Camera 1 (USB)'},
          {'id': 'cam1', 'name': 'Camera 2 (CSI)'},
        ];
      }
      
    } catch (e) {
      debugPrint('Error loading guardian data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;
    
    final updatedConfig = _config!.copyWith(
      activeKeyId: _activeKeyId,
      apiKey: null, // Ensure legacy field is cleared
      checkIntervalHours: int.tryParse(_checkInterval) ?? 24,
      alertSensitivity: _alertSensitivity,
      voiceEnabled: _voiceEnabled,
      wakeWord: _wakeWord,
      microphoneDeviceId: _selectedMic,
      speakerDeviceId: _selectedSpeaker,
      proactiveVoice: _proactiveVoice,
      cameraDeviceId: _selectedCamera,
      captureOnSchedule: _captureOnSchedule,
      actionsEnabled: _actionsEnabled,
      actionPermissions: _actionPermissions,
      requireConfirmation: _requireConfirmation,
      actionCooldownMinutes: _actionCooldownMinutes,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    await _databaseHelper.saveGuardianConfig(updatedConfig);
    setState(() => _config = updatedConfig);

    // Also update the Zone to indicate it has Guardian enabled
    if (updatedConfig.enabled) {
      await _databaseHelper.updateZone(
        widget.zone.id,
        widget.zone.name,
        widget.zone.enabled ? 1 : 0,
        hasGuardian: true,
      );
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardian configuration saved')),
      );
    }
  }

  void _showNumPad(String title, String currentValue, Function(String) onSave) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(currentValue.isEmpty ? 'Enter Value' : currentValue, 
              style: const TextStyle(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SprigrigNumPad(
              onKeyPressed: (key) {
                // Update local state in bottom sheet if needed, but for simplicity we'll just rebuild
                // Actually, we need a stateful builder or similar to update the display
                // For now, let's just pass the key back to parent? No, NumPad handles keys.
                // We need to handle the string manipulation here.
                // Simplified: We'll just update the value and call setState in the parent if we were inline.
                // Since we are in a modal, we need a StatefulBuilder.
              },
              onDelete: () {},
              onClear: () {},
            ),
             // Wait, SprigrigNumPad is stateless. We need to wrap it.
             // Let's implement a proper input handler.
          ],
        ),
      ),
    );
    // Actually, let's use a simpler approach: Pass a controller-like callback
  }
  
  // Helper to show custom input sheets
  void _showInputSheet({
    required String title,
    required String initialValue,
    required bool isNumeric,
    required Function(String) onSave,
  }) {
    String currentValue = initialValue;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  currentValue.isEmpty ? ' ' : currentValue,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Courier'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 24),
              if (isNumeric)
                SprigrigNumPad(
                  onKeyPressed: (key) => setSheetState(() => currentValue += key),
                  onDelete: () => setSheetState(() {
                    if (currentValue.isNotEmpty) currentValue = currentValue.substring(0, currentValue.length - 1);
                  }),
                  onClear: () => setSheetState(() => currentValue = ''),
                )
              else
                SprigrigKeyboard(
                  onKeyPressed: (key) => setSheetState(() => currentValue += key),
                  onDelete: () => setSheetState(() {
                    if (currentValue.isNotEmpty) currentValue = currentValue.substring(0, currentValue.length - 1);
                  }),
                  onSpace: () => setSheetState(() => currentValue += ' '),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onSave(currentValue);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Guardian Setup', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SprigrigBackground(
        primaryColor: Colors.deepPurple,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildMainSettings(),
                      const SizedBox(height: 16),
                      _buildVoiceSection(),
                      const SizedBox(height: 16),
                      _buildCameraSection(),
                      const SizedBox(height: 16),
                      _buildActionsSection(),
                      const SizedBox(height: 16),
                      _buildReportsSection(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveConfig,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Save Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Icon(Icons.psychology, size: 64, color: Colors.purpleAccent),
          SizedBox(height: 16),
          Text(
            'Guardian Overseer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'AI-powered botanical wisdom and monitoring.',
            style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainSettings() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Enable Guardian AI', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Automated monitoring and advice', style: TextStyle(color: Colors.white70)),
              value: _config!.enabled,
              onChanged: (val) async {
                final newConfig = _config!.copyWith(enabled: val);
                await _databaseHelper.saveGuardianConfig(newConfig);
                setState(() => _config = newConfig);
              },
              activeColor: Colors.purpleAccent,
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            
            // API Configuration
            Row(
              children: [
                const Text('API Keys', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.white54, size: 20),
                  onPressed: _showApiKeyHelp,
                  tooltip: 'What is this?',
                ),
                TextButton.icon(
                  onPressed: () => _launchURL('https://console.anthropic.com/settings/keys'),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Get Key'),
                  style: TextButton.styleFrom(foregroundColor: Colors.cyanAccent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Key List
            if (_apiKeys.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Center(child: Text('No API keys found', style: TextStyle(color: Colors.white54))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _apiKeys.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final key = _apiKeys[index];
                  final isSelected = key['id'] == _activeKeyId;
                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.purple.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? Colors.purpleAccent : Colors.white10),
                    ),
                    child: RadioListTile<String>(
                      value: key['id'],
                      groupValue: _activeKeyId,
                      onChanged: (val) => setState(() => _activeKeyId = val),
                      title: Text(key['name'], style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        'Created: ${DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(key['created_at']))}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      secondary: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deleteApiKey(key['id']),
                      ),
                      activeColor: Colors.purpleAccent,
                    ),
                  );
                },
              ),
              
            const SizedBox(height: 12),
            
            // Add Key Button
            OutlinedButton.icon(
              onPressed: _showAddKeyDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add New Key'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),

            const SizedBox(height: 16),
            
            // Test Connection Button
            OutlinedButton.icon(
              onPressed: _activeKeyId == null ? null : () async {
                setState(() => _isLoading = true);
                final key = await SecureStorageService().getApiKey(_activeKeyId!);
                if (key != null) {
                  final success = await AnthropicService().testConnection(key);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              success ? Icons.check_circle : Icons.error,
                              color: success ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(success ? 'API Connection Successful' : 'API Connection Failed'),
                          ],
                        ),
                        backgroundColor: success ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    );
                  }
                }
                setState(() => _isLoading = false);
              },
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Test Connection'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.purpleAccent),
            ),

            const SizedBox(height: 16),
            
            // Monitoring Settings
            const Text('Monitoring Settings', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showInputSheet(
                      title: 'Check Interval (Hours)',
                      initialValue: _checkInterval,
                      isNumeric: true,
                      onSave: (val) => setState(() => _checkInterval = val),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Interval (Hours)', style: TextStyle(color: Colors.white54, fontSize: 10)),
                          Text(_checkInterval, style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _alertSensitivity,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (val) => setState(() => _alertSensitivity = val!),
                    decoration: InputDecoration(
                      labelText: 'Sensitivity',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.mic, color: Colors.purpleAccent),
                SizedBox(width: 8),
                Text('Voice Assistant', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Voice', style: TextStyle(color: Colors.white)),
              value: _voiceEnabled,
              onChanged: (val) => setState(() => _voiceEnabled = val),
              activeColor: Colors.purpleAccent,
            ),
            if (_voiceEnabled) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Wake Word', style: TextStyle(color: Colors.white)),
                subtitle: Text(_wakeWord, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.lock, color: Colors.white24, size: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMic,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Default Microphone')),
                  ...['USB Mic', 'Built-in Mic'].map((e) => DropdownMenuItem(value: e, child: Text(e))),
                ],
                onChanged: (val) => setState(() => _selectedMic = val),
                decoration: InputDecoration(
                  labelText: 'Input Device',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSpeaker,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Default Speaker')),
                  ...['USB Speaker', 'HDMI Audio'].map((e) => DropdownMenuItem(value: e, child: Text(e))),
                ],
                onChanged: (val) => setState(() => _selectedSpeaker = val),
                decoration: InputDecoration(
                  labelText: 'Output Device',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Mock Mic Test
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recording... Say something!')));
                        Future.delayed(const Duration(seconds: 3), () {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playing back...')));
                        });
                      },
                      icon: const Icon(Icons.record_voice_over),
                      label: const Text('Test Mic'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.purpleAccent),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('Proactive Feedback', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Speak alerts automatically', style: TextStyle(color: Colors.white70)),
                value: _proactiveVoice,
                onChanged: (val) => setState(() => _proactiveVoice = val),
                activeColor: Colors.purpleAccent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.purpleAccent),
                SizedBox(width: 8),
                Text('Camera', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCamera,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              items: [
                const DropdownMenuItem(value: null, child: Text('Select Camera')),
                ..._availableCameras.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name']))),
              ],
              onChanged: (val) => setState(() => _selectedCamera = val),
              decoration: InputDecoration(
                labelText: 'Active Camera',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (_selectedCamera != null) ...[
              const SizedBox(height: 16),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off, color: Colors.white24, size: 48),
                      SizedBox(height: 8),
                      Text('Preview Unavailable', style: TextStyle(color: Colors.white24)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Capturing test image...')));
                },
                icon: const Icon(Icons.camera),
                label: const Text('Capture Test Image'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.purpleAccent),
              ),
              SwitchListTile(
                title: const Text('Scheduled Analysis', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Capture at check intervals', style: TextStyle(color: Colors.white70)),
                value: _captureOnSchedule,
                onChanged: (val) => setState(() => _captureOnSchedule = val),
                activeColor: Colors.purpleAccent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: Colors.purpleAccent),
                SizedBox(width: 8),
                Text('Recent Reports', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentReports.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No reports yet', style: TextStyle(color: Colors.white54))),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentReports.length,
                itemBuilder: (context, index) {
                  final report = _recentReports[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description, color: Colors.white70),
                    title: Text(
                      DateFormat('MMM d, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(report.createdAt * 1000)),
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      report.reportType.toUpperCase(),
                      style: const TextStyle(color: Colors.purpleAccent, fontSize: 10),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                    onTap: () {
                      // Show details
                    },
                  );
                },
              ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to full history
                },
                child: const Text('View All Reports', style: TextStyle(color: Colors.purpleAccent)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.science, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                const Text('AI Actions', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orangeAccent),
                  ),
                  child: const Text('EXPERIMENTAL', style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Warning banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orangeAccent, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Allow AI to make system adjustments. Always validate settings.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Master toggle
            SwitchListTile(
              title: const Text('Enable AI System Management', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Allow Guardian to make adjustments', style: TextStyle(color: Colors.white70)),
              value: _actionsEnabled,
              onChanged: (val) {
                if (val) {
                  _showActionsWarningDialog().then((confirmed) {
                    if (confirmed) setState(() => _actionsEnabled = true);
                  });
                } else {
                  setState(() => _actionsEnabled = false);
                }
              },
              activeColor: Colors.orangeAccent,
            ),
            
            if (_actionsEnabled) ...[
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              
              SwitchListTile(
                title: const Text('Require Confirmation', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Ask before executing', style: TextStyle(color: Colors.white70)),
                value: _requireConfirmation,
                onChanged: (val) => setState(() => _requireConfirmation = val),
                activeColor: Colors.orangeAccent,
              ),
              
              const SizedBox(height: 8),
              const Text('Permissions', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              _buildPermissionTile(Icons.science, 'pH Control', 'Adjust targets, trigger doses', 'fertigation_ph'),
              _buildPermissionTile(Icons.water_drop, 'EC / Nutrients', 'Adjust EC targets', 'fertigation_ec'),
              _buildPermissionTile(Icons.lightbulb, 'Lighting', 'Adjust schedules', 'lighting'),
              _buildPermissionTile(Icons.thermostat, 'HVAC', 'Control fans, heaters', 'hvac'),
              _buildPermissionTile(Icons.grass, 'Irrigation', 'Trigger watering', 'irrigation'),
              _buildPermissionTile(Icons.tune, 'Setpoints', 'Modify targets', 'setpoints'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile(IconData icon, String title, String subtitle, String permissionKey) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.white54),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      value: _actionPermissions[permissionKey] ?? false,
      onChanged: (val) => setState(() => _actionPermissions[permissionKey] = val),
      activeColor: Colors.orangeAccent,
      dense: true,
    );
  }

  Future<bool> _showActionsWarningDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orangeAccent),
            SizedBox(width: 12),
            Text('Enable AI Actions?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This experimental feature allows Guardian AI to make adjustments.\n\n'
              'Safety measures:\n'
              '• Monitor your system regularly\n'
              '• Keep "Require Confirmation" enabled\n'
              '• Start with minimal permissions',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('Enable'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _deleteApiKey(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete API Key?', style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SecureStorageService().deleteApiKey(id);
      await _databaseHelper.deleteGuardianApiKey(id);
      
      if (_activeKeyId == id) {
        setState(() => _activeKeyId = null);
      }
      
      final keys = await _databaseHelper.getGuardianApiKeys();
      setState(() => _apiKeys = keys);
    }
  }

  void _showAddKeyDialog() {
    String name = '';
    String key = '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Add API Key', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Key Name (e.g. "My Pro Key")',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 16),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'API Key (sk-...)',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                onChanged: (val) => key = val,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: (name.isEmpty || key.isEmpty) ? null : () async {
                final id = const Uuid().v4();
                await SecureStorageService().saveApiKey(id, key);
                await _databaseHelper.insertGuardianApiKey({
                  'id': id,
                  'name': name,
                  'created_at': DateTime.now().millisecondsSinceEpoch,
                  'last_used_at': null,
                });
                
                if (mounted) {
                  Navigator.pop(context);
                  final keys = await _databaseHelper.getGuardianApiKeys();
                  // If this is the first key, select it automatically
                  if (_apiKeys.isEmpty) {
                    _activeKeyId = id;
                  }
                  // Update parent state
                  this.setState(() => _apiKeys = keys);
                }
              },
              child: const Text('Add', style: TextStyle(color: Colors.purpleAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  void _showApiKeyHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('About API Keys', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'An API Key is like a password that allows SprigRig to talk to the AI brain (Claude by Anthropic).',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              '1. Click "Get Key" to go to Anthropic\'s website.',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              '2. Sign up or log in.',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              '3. Create a new key and copy it.',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              '4. Paste it here.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              'Note: Usage may incur small costs from Anthropic.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }
}
