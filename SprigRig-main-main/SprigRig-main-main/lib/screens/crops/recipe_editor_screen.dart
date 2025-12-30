import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';

class RecipeEditorScreen extends StatefulWidget {
  final Zone zone;
  final int? templateId; // If null, creating new

  const RecipeEditorScreen({
    super.key,
    required this.zone,
    this.templateId,
  });

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  
  // Template Fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'custom';
  
  // Phases
  List<Map<String, dynamic>> _phases = [];

  final List<String> _categories = [
    'cannabis', 'tomatoes', 'leafy_greens', 'herbs', 
    'strawberries', 'peppers', 'microgreens', 'cucumbers', 'custom'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.templateId != null) {
      _loadTemplate();
    } else {
      // Add default initial phase for new recipe
      _addPhase();
    }
  }

  Future<void> _loadTemplate() async {
    setState(() => _isLoading = true);
    try {
      final template = await _db.getRecipeTemplateById(widget.templateId!);
      if (template != null) {
        _nameController.text = template['name'];
        _descriptionController.text = template['description'] ?? '';
        _selectedCategory = template['category'];
        
        final phases = await _db.getPhasesForTemplate(widget.templateId!);
        setState(() {
          // Create mutable copies of the maps
          _phases = phases.map((p) => Map<String, dynamic>.from(p)).toList();
          _phases.sort((a, b) => (a['phase_order'] as int).compareTo(b['phase_order'] as int));
        });
      }
    } catch (e) {
      debugPrint('Error loading template: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addPhase() {
    setState(() {
      _phases.add({
        'phase_name': 'New Phase ${_phases.length + 1}',
        'phase_order': _phases.length + 1,
        'duration_days': 7,
        'light_hours_on': 18,
        'light_hours_off': 6,
        'light_intensity_percent': 100,
        'target_temp_day': 24.0,
        'target_temp_night': 20.0,
        'target_humidity': 60.0,
        'target_ph_min': 5.8,
        'target_ph_max': 6.2,
        'target_ec_min': 1.0,
        'target_ec_max': 1.5,
        'watering_frequency_hours': 24,
        'watering_duration_minutes': 5,
        'aeration_on_minutes': 15,
        'aeration_off_minutes': 45,
        'notes': '',
      });
    });
  }

  void _removePhase(int index) {
    if (index < 0 || index >= _phases.length) return;
    try {
      setState(() {
        _phases.removeAt(index);
        // Re-order remaining phases
        for (int i = 0; i < _phases.length; i++) {
          _phases[i]['phase_order'] = i + 1;
        }
      });
    } catch (e) {
      debugPrint('Error removing phase: $e');
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    if (_phases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one phase')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Calculate total days
      int totalDays = _phases.fold(0, (sum, phase) => sum + (phase['duration_days'] as int));

      final templateData = {
        'name': _nameController.text,
        'category': _selectedCategory,
        'description': _descriptionController.text,
        'total_cycle_days': totalDays,
        'is_system_template': 0, // Always user created
        'created_by_user': 1,
      };

      int templateId;
      if (widget.templateId != null) {
        // Update existing (if user created) or create copy?
        // For simplicity, let's assume we're creating a NEW custom recipe if editing a system one,
        // or updating if it's already user-created.
        // But to be safe and simple: Always create NEW if ID is null.
        // If ID exists, we should check if it's system.
        // For now, let's just create a NEW one if we are "editing" to avoid overwriting system templates.
        // Wait, if we are editing a custom one, we should update it.
        
        // Check if system template
        final current = await _db.getRecipeTemplateById(widget.templateId!);
        if (current != null && current['is_system_template'] == 1) {
           // Create copy
           templateId = await _db.createRecipeTemplate(templateData);
        } else {
           // Update existing
           await _db.updateRecipeTemplate(widget.templateId!, templateData);
           templateId = widget.templateId!;
           // Delete old phases to replace with new ones
           // This is a bit drastic but simple for now. 
           // Better would be to diff, but "replace all phases" is safer for consistency.
           // We need a deletePhasesForTemplate method or iterate delete.
           final oldPhases = await _db.getPhasesForTemplate(templateId);
           for (var p in oldPhases) {
             await _db.deleteRecipePhase(p['id']);
           }
        }
      } else {
        // Create new
        templateId = await _db.createRecipeTemplate(templateData);
      }

      // Insert Phases
      for (var phase in _phases) {
        phase['template_id'] = templateId;
        await _db.createRecipePhase(phase);
      }

      if (mounted) {
        Navigator.pop(context, templateId); // Return the template ID
      }
    } catch (e) {
      debugPrint('Error saving recipe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving recipe: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.templateId == null ? 'Create Custom Recipe' : 'Edit Recipe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveRecipe,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'GROWTH PHASES',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            '${_phases.fold(0, (sum, phase) => sum + (phase['duration_days'] as int? ?? 0))} days total',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._phases.asMap().entries.map((entry) => _buildPhaseCard(entry.key, entry.value)),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _addPhase,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withOpacity(0.02),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white.withOpacity(0.7)),
                              const SizedBox(width: 8),
                              Text(
                                'Add Phase',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: const Color(0xFF1E1E2C), // Dark card background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            VirtualKeyboardTextFormField(
              controller: _nameController,
              label: 'Recipe Name',
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
              items: _categories.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c.toUpperCase().replaceAll('_', ' ')),
              )).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 16),
            VirtualKeyboardTextFormField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseCard(int index, Map<String, dynamic> phase) {
    return Card(
      key: ObjectKey(phase),
      color: const Color(0xFF1E1E2C), // Dark card background
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          initiallyExpanded: false,
          trailing: const SizedBox.shrink(), // Hide default arrow
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase['phase_name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${phase['duration_days']} days',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                ),
                onPressed: () => _removePhase(index),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSummaryChip(Icons.wb_sunny, '${phase['light_hours_on']}/${phase['light_hours_off']}h', Colors.amber),
                  const SizedBox(width: 8),
                  _buildSummaryChip(Icons.thermostat, '${phase['target_temp_day']}°/${phase['target_temp_night']}°', Colors.redAccent),
                  const SizedBox(width: 8),
                  _buildSummaryChip(Icons.water_drop, '${phase['watering_frequency_hours']}h', Colors.cyan),
                  const SizedBox(width: 8),
                  _buildSummaryChip(Icons.air, '${phase['aeration_on_minutes']}/${phase['aeration_off_minutes']}m', Colors.purpleAccent),
                  const SizedBox(width: 8),
                  _buildSummaryChip(Icons.opacity, '${phase['target_humidity']}%', Colors.blueAccent),
                ],
              ),
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  _buildTextField(phase, 'phase_name', 'Phase Name'),
                  const SizedBox(height: 16),
                  _buildNumberField(phase, 'duration_days', 'Duration (Days)'),
                  const Divider(color: Colors.white10, height: 32),
                  
                  _buildSectionHeader('Lighting', Colors.amber),
                  Row(
                    children: [
                      Expanded(child: _buildNumberField(phase, 'light_hours_on', 'Hours ON')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildNumberField(phase, 'light_hours_off', 'Hours OFF')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(phase, 'light_intensity_percent', 'Intensity %'),
                  
                  const Divider(color: Colors.white10, height: 32),
                  _buildSectionHeader('Environment', Colors.blue),
                  Row(
                    children: [
                      Expanded(child: _buildNumberField(phase, 'target_temp_day', 'Day Temp (°C)', isDouble: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildNumberField(phase, 'target_temp_night', 'Night Temp (°C)', isDouble: true)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(phase, 'target_humidity', 'Humidity %', isDouble: true),
                  
                  const Divider(color: Colors.white10, height: 32),
                  _buildSectionHeader('Irrigation', Colors.cyan),
                  Row(
                    children: [
                      Expanded(child: _buildNumberField(phase, 'watering_frequency_hours', 'Freq (Hours)')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildNumberField(phase, 'watering_duration_minutes', 'Duration (Mins)')),
                    ],
                  ),
                  
                  const Divider(color: Colors.white10, height: 32),
                  _buildSectionHeader('Aeration', Colors.purpleAccent),
                  Row(
                    children: [
                      Expanded(child: _buildNumberField(phase, 'aeration_on_minutes', 'ON (Mins)')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildNumberField(phase, 'aeration_off_minutes', 'OFF (Mins)')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(Map<String, dynamic> map, String key, String label) {
    // We need a controller for VirtualKeyboardTextFormField
    // Since we are inside a list item, we can't easily maintain a controller in the state for each field
    // without a more complex structure.
    // However, VirtualKeyboardTextFormField requires a controller.
    // We can create a temporary controller with the initial value, but updates need to flow back.
    // Actually, VirtualKeyboardTextFormField takes a controller.
    // If we don't provide a controller, we can't use it easily with the current implementation.
    // Let's modify VirtualKeyboardTextFormField to accept initialValue if controller is not provided?
    // Or just create a controller here. But if we create it in build, it will be recreated on every rebuild, losing cursor position etc.
    // But here we are just editing values in a map.
    // A better approach for this dynamic list is to just use the map value.
    // But VirtualKeyboard requires a controller to interact with the keyboard.
    
    // Let's use a key to preserve state if possible, or just instantiate a controller.
    // Since this is a simple editor, maybe we can just use a controller initialized with the value.
    // But we need to update the map when it changes.
    
    final controller = TextEditingController(text: map[key]?.toString() ?? '');
    // We need to ensure the controller doesn't get disposed/recreated weirdly.
    // But since this is a stateless widget method, it's tricky.
    // Ideally _buildTextField should be a StatefulWidget.
    
    return _MapFieldWrapper(
      initialValue: map[key]?.toString() ?? '',
      label: label,
      onChanged: (v) => map[key] = v,
    );
  }

  Widget _buildNumberField(Map<String, dynamic> map, String key, String label, {bool isDouble = false}) {
    return _MapFieldWrapper(
      initialValue: map[key].toString(),
      label: label,
      keyboardType: TextInputType.number,
      onChanged: (v) {
        if (isDouble) {
          map[key] = double.tryParse(v) ?? 0.0;
        } else {
          map[key] = int.tryParse(v) ?? 0;
        }
      },
    );
  }
}

class _MapFieldWrapper extends StatefulWidget {
  final String initialValue;
  final String label;
  final TextInputType keyboardType;
  final Function(String) onChanged;

  const _MapFieldWrapper({
    required this.initialValue,
    required this.label,
    this.keyboardType = TextInputType.text,
    required this.onChanged,
  });

  @override
  State<_MapFieldWrapper> createState() => _MapFieldWrapperState();
}

class _MapFieldWrapperState extends State<_MapFieldWrapper> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VirtualKeyboardTextFormField(
      controller: _controller,
      label: widget.label,
      keyboardType: widget.keyboardType,
    );
  }
}
