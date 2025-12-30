import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/app_background.dart';
import 'recipe_detail_screen.dart';
import 'recipe_editor_screen.dart';

class RecipeSelectionScreen extends StatefulWidget {
  final Zone zone;

  const RecipeSelectionScreen({super.key, required this.zone});

  @override
  State<RecipeSelectionScreen> createState() => _RecipeSelectionScreenState();
}

class _RecipeSelectionScreenState extends State<RecipeSelectionScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;
  List<Map<String, dynamic>> _templates = [];
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'cannabis',
    'tomatoes',
    'leafy_greens',
    'herbs',
    'strawberries',
    'peppers',
    'microgreens',
    'cucumbers',
    'custom'
  ];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final allTemplates = await _db.getAllRecipeTemplates();
      if (_selectedCategory == 'All') {
        _templates = allTemplates;
      } else {
        _templates = allTemplates.where((t) => t['category'] == _selectedCategory).toList();
      }
    } catch (e) {
      debugPrint('Error loading templates: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCategory(String category) {
    return category.split('_').map((word) => 
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Select Recipe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RecipeEditorScreen(zone: widget.zone)),
          );
          _loadTemplates(); // Refresh list
        },
        label: const Text('Create Custom'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Category Dropdown
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(_formatCategory(category)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                          _loadTemplates();
                        });
                      }
                    },
                  ),
                ),
              ),

              // Template List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _templates.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.white.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  'No templates found for ${_formatCategory(_selectedCategory)}',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Bottom padding for FAB
                            itemCount: _templates.length,
                            itemBuilder: (context, index) {
                              final template = _templates[index];
                              return _buildTemplateCard(template);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    return Card(
      color: const Color(0xFF1E1E2C), // Dark card background
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(
                zone: widget.zone,
                templateId: template['id'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      template['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatCategory(template['category']),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                template['description'] ?? 'No description',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    '${template['total_cycle_days']} days',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.layers, size: 16, color: Colors.white54),
                  const SizedBox(width: 4),
                  // We could query phases count here if needed, but keeping it simple
                  const Text(
                    'View Phases',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
