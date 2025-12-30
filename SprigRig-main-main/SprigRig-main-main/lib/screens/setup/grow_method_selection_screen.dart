// lib/screens/setup/grow_method_selection_screen.dart
import 'package:flutter/material.dart';

class GrowMethodSelectionScreen extends StatefulWidget {
  const GrowMethodSelectionScreen({super.key});

  @override
  State<GrowMethodSelectionScreen> createState() =>
      _GrowMethodSelectionScreenState();
}

class _GrowMethodSelectionScreenState extends State<GrowMethodSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _listController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _listAnimation;

  String? _selectedMethod;

  final List<GrowMethod> _growMethods = [
    GrowMethod(
      id: 'soil',
      name: 'Soil Growing',
      description: 'Traditional soil-based growing with natural nutrients and organic matter.',
      icon: Icons.grass,
      color: Colors.brown,
      difficulty: 'Beginner',
      features: [
        'Natural nutrient cycling',
        'Forgiving for beginners',
        'Lower maintenance',
        'Organic growing option',
      ],
      defaultCards: ['grow_info', 'sensor', 'irrigation', 'camera'],
    ),
    GrowMethod(
      id: 'hydroponic',
      name: 'Hydroponic',
      description: 'Soilless growing using nutrient-rich water solutions.',
      icon: Icons.water_drop,
      color: Colors.blue,
      difficulty: 'Intermediate',
      features: [
        'Faster growth rates',
        'Higher yields',
        'Precise nutrient control',
        'Water efficient',
      ],
      defaultCards: ['grow_info', 'sensor', 'lighting', 'irrigation', 'ventilation', 'camera'],
    ),
    GrowMethod(
      id: 'ebb_flow',
      name: 'Ebb and Flow',
      description: 'Flood and drain system that periodically floods the grow bed.',
      icon: Icons.waves,
      color: Colors.cyan,
      difficulty: 'Intermediate',
      features: [
        'Good root oxygenation',
        'Automated watering',
        'Scalable system',
        'Root zone flexibility',
      ],
      defaultCards: ['grow_info', 'sensor', 'lighting', 'irrigation', 'ventilation', 'camera'],
    ),
    GrowMethod(
      id: 'drip_irrigation',
      name: 'Drip Irrigation',
      description: 'Precise water and nutrient delivery through drip emitters.',
      icon: Icons.opacity,
      color: Colors.lightBlue,
      difficulty: 'Beginner',
      features: [
        'Water conservation',
        'Precise delivery',
        'Low maintenance',
        'Suitable for any medium',
      ],
      defaultCards: ['grow_info', 'sensor', 'irrigation', 'camera'],
    ),
    GrowMethod(
      id: 'nft',
      name: 'NFT (Nutrient Film Technique)',
      description: 'Continuous shallow stream of nutrient solution flows past roots.',
      icon: Icons.timeline,
      color: Colors.teal,
      difficulty: 'Advanced',
      features: [
        'Maximum oxygenation',
        'Minimal growing medium',
        'Continuous nutrient flow',
        'Space efficient',
      ],
      defaultCards: ['grow_info', 'sensor', 'lighting', 'irrigation', 'ventilation', 'climate', 'camera'],
    ),
    GrowMethod(
      id: 'aeroponics',
      name: 'Aeroponics',
      description: 'Roots are suspended in air and misted with nutrient solution.',
      icon: Icons.cloud,
      color: Colors.purple,
      difficulty: 'Advanced',
      features: [
        'Fastest growth rates',
        'Maximum oxygenation',
        'Minimal water usage',
        'Easy root inspection',
      ],
      defaultCards: ['grow_info', 'sensor', 'lighting', 'irrigation', 'ventilation', 'climate', 'camera'],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _listController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _listAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _listController, curve: Curves.easeOut));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _listController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _onMethodSelected(String methodId) {
    setState(() {
      _selectedMethod = methodId;
    });
  }

  void _onContinue() {
    if (_selectedMethod != null) {
      // Navigate to zone creation with selected method
      Navigator.pushNamed(
        context,
        '/setup/zone-creation',
        arguments: {
          'growMethod': _selectedMethod,
          'methodData': _growMethods.firstWhere((m) => m.id == _selectedMethod),
        },
      );
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showMethodInfo(GrowMethod method) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [method.color, method.color.withValues(alpha:0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(method.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  method.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Difficulty badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(method.difficulty),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  method.difficulty,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                method.description,
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // Features
              const Text(
                'Key Features:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...method.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Default cards info
              const Text(
                'Recommended Cards:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: method.defaultCards.map((cardId) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha:0.3)),
                    ),
                    child: Text(
                      _getCardDisplayName(cardId),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _onMethodSelected(method.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: method.color,
                foregroundColor: Colors.white,
              ),
              child: const Text('Select This Method'),
            ),
          ],
        );
      },
    );
  }

  String _getCardDisplayName(String cardId) {
    switch (cardId) {
      case 'grow_info':
        return 'Grow Info';
      case 'sensor':
        return 'Sensors';
      case 'lighting':
        return 'Lighting';
      case 'irrigation':
        return 'Irrigation';
      case 'ventilation':
        return 'Ventilation';
      case 'climate':
        return 'Climate';
      case 'camera':
        return 'Camera';
      default:
        return cardId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
          child: Column(
            children: [
              // Header
              _buildHeader(),
              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        // Title and description
                        _buildTitleSection(),
                        const SizedBox(height: 32),
                        // Grow methods grid
                        Expanded(child: _buildMethodsGrid()),
                        // Continue button
                        _buildContinueButton(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          const Expanded(
            child: Text(
              'Setup Wizard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        // Step indicator (Step 3 of 4)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepIndicator(1, true),  // Location ✓
            _buildStepLine(true),
            _buildStepIndicator(2, true),  // Grow Method (current)
            _buildStepLine(false),
            _buildStepIndicator(3, false), // Zone Creation
            _buildStepLine(false),
            _buildStepIndicator(4, false), // Complete
          ],
        ),
        const SizedBox(height: 32),
        // Title
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.green, Colors.teal],
          ).createShader(bounds),
          child: const Text(
            'Choose Your Growing Method',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        // Description
        Text(
          'This influences which control cards will be recommended for your zones.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade300,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
        child: isActive
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                step.toString(),
                style: TextStyle(
                  color: Colors.grey.shade400,
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

  Widget _buildMethodsGrid() {
    return AnimatedBuilder(
      animation: _listAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _listAnimation.value)),
          child: Opacity(
            opacity: _listAnimation.value,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _growMethods.length,
              itemBuilder: (context, index) {
                final method = _growMethods[index];
                final isSelected = _selectedMethod == method.id;

                return GestureDetector(
                  onTap: () => _onMethodSelected(method.id),
                  onLongPress: () => _showMethodInfo(method),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800.withValues(alpha:0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.green
                            : Colors.grey.shade700.withValues(alpha:0.5),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.green.withValues(alpha:0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon and difficulty
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [method.color, method.color.withValues(alpha:0.7)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(method.icon, color: Colors.white, size: 24),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor(method.difficulty).withValues(alpha:0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getDifficultyColor(method.difficulty).withValues(alpha:0.5),
                                ),
                              ),
                              child: Text(
                                method.difficulty,
                                style: TextStyle(
                                  color: _getDifficultyColor(method.difficulty),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Method name
                        Text(
                          method.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Description
                        Expanded(
                          child: Text(
                            method.description,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Cards count
                        Row(
                          children: [
                            Icon(
                              Icons.dashboard_outlined,
                              color: Colors.grey.shade500,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${method.defaultCards.length} control cards',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey.shade500,
                              size: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = _selectedMethod != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled ? _onContinue : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? Colors.green : Colors.grey.shade700,
          foregroundColor: Colors.white,
          elevation: isEnabled ? 8 : 0,
          shadowColor: Colors.green.withValues(alpha:0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Continue Setup',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              size: 20,
              color: isEnabled ? Colors.white : Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}

class GrowMethod {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String difficulty;
  final List<String> features;
  final List<String> defaultCards; // NEW: Recommended cards for this method

  GrowMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.difficulty,
    required this.features,
    required this.defaultCards,
  });
}