import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../models/zone.dart';
import '../../models/grow.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';

class ZoneCreateEditScreen extends StatefulWidget {
  final Zone? zone;
  final List<Grow> grows;

  const ZoneCreateEditScreen({
    super.key,
    this.zone,
    required this.grows,
  });

  @override
  State<ZoneCreateEditScreen> createState() => _ZoneCreateEditScreenState();
}

class _ZoneCreateEditScreenState extends State<ZoneCreateEditScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  int? _selectedGrowId;
  bool _enabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.zone != null) {
      // Editing existing zone
      _nameController.text = widget.zone!.name;
      _selectedGrowId = widget.zone!.growId;
      _enabled = widget.zone!.enabled;
    } else {
      // Creating new zone - default to first grow if available
      if (widget.grows.isNotEmpty) {
        _selectedGrowId = widget.grows.first.id;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveZone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.zone != null) {
        // Update existing zone
        await _db.updateZone(
          widget.zone!.id,
          _nameController.text.trim(),
          _enabled ? 1 : 0,
          growId: _selectedGrowId,
        );
      } else {
        // Create new zone
        await _db.createZone(_selectedGrowId, _nameController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.zone != null 
                  ? 'Zone updated successfully'
                  : 'Zone created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save zone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E3A8A),
              Color(0xFF1E293B),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              widget.zone != null ? 'Edit Zone' : 'Create Zone',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone name
            VirtualKeyboardTextFormField(
              controller: _nameController,
              label: 'Zone Name',
              hintText: 'e.g., Main Garden, Zone A',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Zone name is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Growing project selection
            const Text(
              'Growing Project',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _selectedGrowId,
                  hint: Text(
                    'Select growing project',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  isExpanded: true,
                  dropdownColor: Colors.grey.shade800,
                  style: const TextStyle(color: Colors.white),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No project (standalone zone)'),
                    ),
                    ...widget.grows.map((grow) {
                      return DropdownMenuItem<int?>(
                        value: grow.id,
                        child: Text(grow.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGrowId = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Enabled switch
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zone Enabled',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Enable this zone for automation and control',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _enabled,
                  onChanged: (value) {
                    setState(() {
                      _enabled = value;
                    });
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),

            const Spacer(),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF334155), // Charcoal slate
                      Color(0xFF1E3A5F), // Dark blue
                      Color(0xFF1A2744), // Deep navy
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A5F).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: const Color(0xFF000000).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _saveZone,
                    borderRadius: BorderRadius.circular(35),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xFFE2E8F0),
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.eco_outlined,
                                  color: const Color(0xFF94A3B8),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Save Zone',
                                  style: TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.0,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
