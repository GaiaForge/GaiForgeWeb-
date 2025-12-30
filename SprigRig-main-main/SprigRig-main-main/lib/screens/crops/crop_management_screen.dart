import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/app_background.dart';
import 'recipe_selection_screen.dart';
import 'recipe_editor_screen.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';

class CropManagementScreen extends StatefulWidget {
  final Zone zone;

  const CropManagementScreen({super.key, required this.zone});

  @override
  State<CropManagementScreen> createState() => _CropManagementScreenState();
}

class _CropManagementScreenState extends State<CropManagementScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;
  Map<String, dynamic>? _activeCrop;
  Map<String, dynamic>? _activeTemplate;
  Map<String, dynamic>? _currentPhase;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final crop = await _db.getZoneCrop(widget.zone.id!);
      if (crop != null) {
        _activeCrop = crop;
        if (crop['template_id'] != null) {
          _activeTemplate = await _db.getRecipeTemplateById(crop['template_id']);
        }
        if (crop['current_phase_id'] != null) {
          _currentPhase = await _db.getPhaseById(crop['current_phase_id']);
        }
      } else {
        _activeCrop = null;
        _activeTemplate = null;
        _currentPhase = null;
      }
    } catch (e) {
      debugPrint('Error loading crop data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editCropName() async {
    final controller = TextEditingController(text: _activeCrop!['crop_name']);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Rename Crop', style: TextStyle(color: Colors.white)),
        content: VirtualKeyboardTextField(
          controller: controller,
          label: 'Crop Name',
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save', style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _activeCrop!['crop_name']) {
      await _db.updateZoneCrop(_activeCrop!['id'], {'crop_name': newName});
      _loadData();
    }
  }

  Future<void> _endCrop() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('End Crop Cycle?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will remove the current crop assignment and stop all recipe automation. Are you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Crop', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true && _activeCrop != null) {
      await _db.deleteZoneCrop(_activeCrop!['id']);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Crop Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _activeCrop == null
                  ? _buildEmptyState()
                  : _buildActiveCropState(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco_outlined, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 24),
          const Text(
            'No Active Crop',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new crop cycle to automate your grow',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeSelectionScreen(zone: widget.zone),
                ),
              );
              _loadData();
            },
            icon: const Icon(Icons.add),
            label: const Text('Start New Crop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCropState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade800, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.eco, size: 48, color: Colors.white.withOpacity(0.9)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _activeCrop!['crop_name'] ?? 'Unknown Crop',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                      onPressed: _editCropName,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _activeTemplate?['name'] ?? 'Custom Recipe',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Phase Info
          if (_currentPhase != null)
            _buildPhaseCard(),

          const SizedBox(height: 24),

          // Actions
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildPhaseCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C), // Dark card background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Phase',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.5)),
                ),
                child: Text(
                  _currentPhase!['phase_name'],
                  style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.timer, 'Duration', '${_currentPhase!['duration_days']} days'),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.light_mode, 'Light', '${_currentPhase!['light_hours_on']}h ON / ${_currentPhase!['light_hours_off']}h OFF'),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.thermostat, 'Temp', '${_currentPhase!['target_temp_day']}°C / ${_currentPhase!['target_temp_night']}°C'),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.water_drop, 'Humidity', '${_currentPhase!['target_humidity']}%'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white54),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white70)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              if (_activeCrop == null || _activeCrop!['template_id'] == null) return;
              
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeEditorScreen(
                    zone: widget.zone,
                    templateId: _activeCrop!['template_id'],
                  ),
                ),
              );

              if (result != null) {
                if (result is int && result != _activeCrop!['template_id']) {
                  // Template ID changed (e.g. created a copy), update the crop
                  await _db.updateZoneCrop(_activeCrop!['id'], {'template_id': result});
                }
                await _loadData();
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Recipe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.2),
              foregroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _endCrop,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('End Crop Cycle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
