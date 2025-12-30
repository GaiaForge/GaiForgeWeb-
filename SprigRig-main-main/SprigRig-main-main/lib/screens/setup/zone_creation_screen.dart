// lib/screens/setup/zone_creation_screen.dart
import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../models/grow.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';

class ZoneCreationScreen extends StatefulWidget {
  const ZoneCreationScreen({super.key});

  @override
  State<ZoneCreationScreen> createState() => _ZoneCreationScreenState();
}

class _ZoneCreationScreenState extends State<ZoneCreationScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final PageController _pageController = PageController();
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Data from previous screens
  String? _selectedGrowMethod;
  Map<String, dynamic>? _methodData;
  List<String> _defaultCards = [];

  // Current page
  int _currentPage = 0;

  // Form controllers
  final TextEditingController _growNameController = TextEditingController();
  final TextEditingController _zoneNameController = TextEditingController();
  final TextEditingController _plantNameController = TextEditingController();
  
  // Plant selection
  String? _selectedPlantCategory;
  final List<String> _plantCategories = [
    'Herbs',
    'Leafy Greens',
    'Tomatoes',
    'Peppers',
    'Cucumbers',
    'Strawberries',
    'Microgreens',
    'Flowers',
    'Other',
  ];

  // Zone configuration
  int _zoneCount = 1;
  final int _maxZones = 8;
  
  // Setup completion
  bool _isCreatingGrow = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _fadeController.forward();
    
    // Get data from previous screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _selectedGrowMethod = args['growMethod'] as String?;
          _methodData = args['methodData'] as Map<String, dynamic>?;
          
          // Extract default cards if method data exists
          if (_methodData != null) {
            final methodObject = _methodData!['methodData'];
            if (methodObject != null && methodObject.defaultCards != null) {
              _defaultCards = List<String>.from(methodObject.defaultCards);
            }
          }
        });
      }
    });

    // Set default names
    _growNameController.text = 'My Growing Project';
    _zoneNameController.text = 'Zone 1';
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    _growNameController.dispose();
    _zoneNameController.dispose();
    _plantNameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _createGrowAndFinishSetup();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool get _canContinueFromCurrentPage {
    switch (_currentPage) {
      case 0: // Grow details
        return _growNameController.text.trim().isNotEmpty &&
               _selectedPlantCategory != null;
      case 1: // Zone configuration
        return _zoneNameController.text.trim().isNotEmpty;
      case 2: // Review
        return true;
      default:
        return false;
    }
  }

  Future<void> _createGrowAndFinishSetup() async {
    setState(() {
      _isCreatingGrow = true;
    });

    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Create the grow first
      final growId = await _db.database.then((db) => db.insert('grows', {
        'plant_id': null, // We'll create plant later if needed
        'grow_mode_id': 1, // Default to first grow mode for now
        'name': _growNameController.text.trim(),
        'start_time': now,
        'status': 'active',
        'notes': 'Created via setup wizard with ${_selectedGrowMethod ?? 'unknown'} method',
        'created_at': now,
        'updated_at': now,
      }));

      // Create the zones
      for (int i = 0; i < _zoneCount; i++) {
        final zoneName = _zoneCount == 1 
            ? _zoneNameController.text.trim()
            : '${_zoneNameController.text.trim().replaceAll(RegExp(r'\d+$'), '')} ${i + 1}';
            
        await _db.createZone(growId, zoneName);
      }

      // Create basic plant entry if custom plant name provided
      if (_plantNameController.text.trim().isNotEmpty && _selectedPlantCategory != null) {
        await _db.database.then((db) => db.insert('plants', {
          'name': _plantNameController.text.trim(),
          'category': _selectedPlantCategory,
          'created_at': now,
          'updated_at': now,
        }));
      }

      // Mark setup as complete
      await _db.database.then((db) => db.insert('system_config', {
        'system_type': _selectedGrowMethod ?? 'soil',
        'facility_scale': 'home',
        'zone_count': _zoneCount,
        'zones': '',
        'hardware_requirements': '',
        'created_at': now,
        'updated_at': now,
      }));

      // Show success and navigate to home
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setup completed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to home dashboard
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }

    } catch (e) {
      setState(() {
        _isCreatingGrow = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete setup: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
              Color(0xFF0F172A), // slate-900
              Color(0xFF1E3A8A), // blue-900
              Color(0xFF1E293B), // slate-800
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildGrowDetailsPage(),
                      _buildZoneConfigPage(),
                      _buildReviewPage(),
                    ],
                  ),
                ),
                _buildBottomNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentPage > 0)
                IconButton(
                  onPressed: _isCreatingGrow ? null : _previousPage,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              const Expanded(
                child: Text(
                  'Create Your Growing Project',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepIndicator(1, true),   // Location ✓
              _buildStepLine(true),
              _buildStepIndicator(2, true),   // Grow Method ✓
              _buildStepLine(true),
              _buildStepIndicator(3, _currentPage >= 0), // Zone Creation (current)
              _buildStepLine(_currentPage >= 2),
              _buildStepIndicator(4, _currentPage >= 2), // Complete
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.green : Colors.grey.shade700,
        border: Border.all(
          color: isActive ? Colors.green : Colors.grey.shade600,
          width: 2,
        ),
      ),
      child: Center(
        child: isActive && step < 3
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                step.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Container(
      width: 40,
      height: 2,
      color: isCompleted ? Colors.green : Colors.grey.shade700,
    );
  }

  Widget _buildGrowDetailsPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Growing Project Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Project name
          _buildInputField(
            controller: _growNameController,
            label: 'Project Name',
            hint: 'e.g., Spring Herbs 2025',
            icon: Icons.eco,
          ),

          const SizedBox(height: 20),

          // Plant category selection
          const Text(
            'What are you growing?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _plantCategories.length,
              itemBuilder: (context, index) {
                final category = _plantCategories[index];
                final isSelected = _selectedPlantCategory == category;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlantCategory = category;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.green.withValues(alpha:0.2)
                          : Colors.grey.shade800.withValues(alpha:0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade700,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          color: isSelected ? Colors.green : Colors.grey.shade400,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.green : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Optional specific plant name
          _buildInputField(
            controller: _plantNameController,
            label: 'Specific Plant (Optional)',
            hint: 'e.g., Cherry Tomatoes, Basil',
            icon: Icons.local_florist,
          ),
        ],
      ),
    );
  }

  Widget _buildZoneConfigPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zone Configuration',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure your physical growing areas',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 32),

          // Zone name
          _buildInputField(
            controller: _zoneNameController,
            label: 'Zone Name',
            hint: 'e.g., Zone 1, Main Garden',
            icon: Icons.location_on,
          ),

          const SizedBox(height: 32),

          // Zone count selector
          const Text(
            'Number of Zones',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can add more zones later',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withValues(alpha:0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_zoneCount Zone${_zoneCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _zoneCount > 1 
                              ? () => setState(() => _zoneCount--)
                              : null,
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: _zoneCount > 1 ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                        IconButton(
                          onPressed: _zoneCount < _maxZones 
                              ? () => setState(() => _zoneCount++)
                              : null,
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: _zoneCount < _maxZones ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                if (_zoneCount > 1) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900.withValues(alpha:0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Zones will be named: ${_zoneNameController.text.trim().replaceAll(RegExp(r'\d+$'), '')} 1, 2, 3...',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          // Method reminder
          if (_selectedGrowMethod != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha:0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Using ${_selectedGrowMethod!.replaceAll('_', ' ').toUpperCase()} method with ${_defaultCards.length} recommended control cards',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review & Create',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review your configuration before creating your growing project',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),

          // Project summary
          _buildSummaryCard(),

          const SizedBox(height: 24),

          // What happens next
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withValues(alpha:0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.rocket_launch, color: Colors.blue, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'What happens next?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildNextStepItem('Your growing project will be created'),
                _buildNextStepItem('Zones will be set up with recommended control cards'),
                _buildNextStepItem('You\'ll be taken to the main dashboard'),
                _buildNextStepItem('Start configuring hardware and schedules'),
              ],
            ),
          ),

          const Spacer(),

          if (_isCreatingGrow)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Creating your growing project...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha:0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco, color: Colors.green, size: 24),
              SizedBox(width: 12),
              Text(
                'Project Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Project Name', _growNameController.text.trim()),
          _buildSummaryRow('Plant Category', _selectedPlantCategory ?? 'Not specified'),
          if (_plantNameController.text.trim().isNotEmpty)
            _buildSummaryRow('Specific Plant', _plantNameController.text.trim()),
          _buildSummaryRow('Growing Method', _selectedGrowMethod?.replaceAll('_', ' ').toUpperCase() ?? 'Unknown'),
          _buildSummaryRow('Number of Zones', _zoneCount.toString()),
          _buildSummaryRow('Zone Name${_zoneCount > 1 ? 's' : ''}', 
              _zoneCount == 1 
                  ? _zoneNameController.text.trim()
                  : '${_zoneNameController.text.trim().replaceAll(RegExp(r'\d+$'), '')} 1-$_zoneCount'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        VirtualKeyboardTextField(
          controller: controller,
          label: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey.shade400),
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'herbs':
        return Icons.local_florist;
      case 'leafy greens':
        return Icons.eco;
      case 'tomatoes':
        return Icons.circle;
      case 'peppers':
        return Icons.local_fire_department;
      case 'cucumbers':
        return Icons.nature;
      case 'strawberries':
        return Icons.favorite;
      case 'microgreens':
        return Icons.grass;
      case 'flowers':
        return Icons.local_florist;
      default:
        return Icons.agriculture;
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0 && !_isCreatingGrow)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentPage > 0 && !_isCreatingGrow) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isCreatingGrow 
                  ? null
                  : (_canContinueFromCurrentPage ? _nextPage : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isCreatingGrow
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_currentPage == 2 ? 'Create Project' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}