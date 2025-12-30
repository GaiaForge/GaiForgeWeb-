import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Zone zone;
  final int templateId;

  const RecipeDetailScreen({
    super.key,
    required this.zone,
    required this.templateId,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;
  Map<String, dynamic>? _template;
  List<Map<String, dynamic>> _phases = [];
  final TextEditingController _cropNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _cropNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      _template = await _db.getRecipeTemplateById(widget.templateId);
      _phases = await _db.getPhasesForTemplate(widget.templateId);
      // Sort phases by order
      _phases.sort((a, b) => (a['phase_order'] as int).compareTo(b['phase_order'] as int));
      
      if (_template != null) {
        _cropNameController.text = '${_template!['name']} - ${widget.zone.name}';
      }
    } catch (e) {
      debugPrint('Error loading recipe details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _assignToZone() async {
    if (_template == null || _phases.isEmpty) return;

    if (_cropNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a crop name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Create zone crop assignment
      await _db.assignCropToZone({
        'zone_id': widget.zone.id,
        'crop_name': _cropNameController.text,
        'template_id': widget.templateId,
        'current_phase_id': _phases.first['id'], // Start with first phase
        'phase_start_date': DateTime.now().toIso8601String(),
        'grow_start_date': DateTime.now().toIso8601String(),
        'expected_harvest_date': DateTime.now().add(Duration(days: _template!['total_cycle_days'])).toIso8601String(),
        'use_recipe_profile': 1,
        'is_active': 1,
      });

      if (mounted) {
        // Pop back to Crop Management Screen (which will reload and show active crop)
        Navigator.pop(context); // Pop detail
        Navigator.pop(context); // Pop selection
      }
    } catch (e) {
      debugPrint('Error assigning crop: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning crop: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_template?['name'] ?? 'Recipe Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Description
                            Text(
                              _template?['description'] ?? '',
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            const SizedBox(height: 24),

                            // Crop Name Input
                            VirtualKeyboardTextField(
                              controller: _cropNameController,
                              label: 'Crop Name',
                            ),
                            const SizedBox(height: 24),

                            // Phases Header
                            const Text(
                              'Growth Phases',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Phases List
                            ..._phases.map((phase) => _buildPhaseCard(phase)),
                          ],
                        ),
                      ),
                    ),
                    
                    // Bottom Action Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                      ),
                      child: ElevatedButton(
                        onPressed: _assignToZone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Start Crop with This Recipe',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPhaseCard(Map<String, dynamic> phase) {
    return Card(
      color: const Color(0xFF1E1E2C), // Dark card background
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: ExpansionTile(
        title: Text(
          phase['phase_name'],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${phase['duration_days']} days',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.2),
          child: Text(
            '${phase['phase_order']}',
            style: const TextStyle(color: Colors.blueAccent),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPhaseDetail(Icons.light_mode, 'Light', '${phase['light_hours_on']}h ON / ${phase['light_hours_off']}h OFF @ ${phase['light_intensity_percent']}%'),
                const SizedBox(height: 8),
                _buildPhaseDetail(Icons.thermostat, 'Temp', '${phase['target_temp_day']}°C Day / ${phase['target_temp_night']}°C Night'),
                const SizedBox(height: 8),
                _buildPhaseDetail(Icons.water_drop, 'Humidity', '${phase['target_humidity']}%'),
                const SizedBox(height: 8),
                _buildPhaseDetail(Icons.science, 'pH / EC', 'pH ${phase['target_ph_min']}-${phase['target_ph_max']} / EC ${phase['target_ec_min']}-${phase['target_ec_max']}'),
                if (phase['notes'] != null && phase['notes'].isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      phase['notes'],
                      style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
