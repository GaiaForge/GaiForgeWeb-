import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/app_background.dart';
import '../dashboard/zone_dashboard_screen.dart';
import 'camera_setup_screen.dart';
import '../hubs/hub_network_screen.dart';
import '../crops/crop_management_screen.dart';
import 'fertigation_setup_screen.dart';
import 'guardian_setup_screen.dart';

class ZoneConfigurationScreen extends StatefulWidget {
  final Zone zone;

  const ZoneConfigurationScreen({super.key, required this.zone});

  @override
  State<ZoneConfigurationScreen> createState() => _ZoneConfigurationScreenState();
}

class _ZoneConfigurationScreenState extends State<ZoneConfigurationScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = true;
  String _growModeName = '';
  late Zone _currentZone;
  
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  bool _hasAssignedCameras = false;
  bool _hasSeedlingMat = false;

  @override
  void initState() {
    super.initState();
    _currentZone = widget.zone;
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _loadGrowInfo();
      await _checkAssignedCameras();
      await _checkSeedlingMat();
    } catch (e) {
      debugPrint('Error loading zone configuration data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkAssignedCameras() async {
    if (_currentZone.id != null) {
      final cameras = await _databaseHelper.getZoneCameras(_currentZone.id!);
      setState(() {
        _hasAssignedCameras = cameras.isNotEmpty;
      });
    }
  }

  Future<void> _checkSeedlingMat() async {
    if (_currentZone.id != null) {
      final settings = await _databaseHelper.getSeedlingMatSettings(_currentZone.id!);
      setState(() {
        _hasSeedlingMat = settings != null && settings['enabled'] == 1;
      });
    }
  }

  Future<void> _loadGrowInfo() async {
    if (_currentZone.growId != null) {
      final grow = await _databaseHelper.getGrow(_currentZone.growId!);
      if (grow != null && grow.growModeId != null) {
        final modeName = await _databaseHelper.getGrowModeName(grow.growModeId!);
        if (modeName != null) {
          setState(() {
            // Capitalize first letter
            _growModeName = modeName[0].toUpperCase() + modeName.substring(1);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _toggleFeature(String category) async {
    bool newStatus = false;
    
    switch (category) {
      case 'Irrigation':
        newStatus = !_currentZone.hasIrrigation;
        await _databaseHelper.updateZone(_currentZone.id, _currentZone.name, _currentZone.enabled ? 1 : 0, hasIrrigation: newStatus);
        break;
      case 'Lighting':
        newStatus = !_currentZone.hasLighting;
        await _databaseHelper.updateZone(_currentZone.id, _currentZone.name, _currentZone.enabled ? 1 : 0, hasLighting: newStatus);
        break;
      case 'HVAC':
        newStatus = !_currentZone.hasHvac;
        await _databaseHelper.updateZone(_currentZone.id, _currentZone.name, _currentZone.enabled ? 1 : 0, hasHvac: newStatus);
        break;
      case 'Aeration':
        newStatus = !_currentZone.hasAeration;
        await _databaseHelper.updateZone(_currentZone.id, _currentZone.name, _currentZone.enabled ? 1 : 0, hasAeration: newStatus);
        break;
      case 'Cameras':
        newStatus = !_currentZone.hasCameras;
        await _databaseHelper.updateZone(_currentZone.id, _currentZone.name, _currentZone.enabled ? 1 : 0, hasCameras: newStatus);
        break;
      case 'Seedling Mat':
        newStatus = !_hasSeedlingMat;
        // Get existing settings or create default
        final existing = await _databaseHelper.getSeedlingMatSettings(_currentZone.id!);
        final settings = existing ?? {
          'zone_id': _currentZone.id,
          'mode': 'manual',
          'target_temp': 24.0,
          'auto_off_enabled': 0,
          'auto_off_days': 14,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        };
        settings['enabled'] = newStatus ? 1 : 0;
        settings['updated_at'] = DateTime.now().millisecondsSinceEpoch;
        await _databaseHelper.saveSeedlingMatSettings(settings);
        setState(() => _hasSeedlingMat = newStatus);
        return; // Return early as this doesn't update _currentZone
      case 'Fertigation':
        newStatus = !_currentZone.hasFertigation;
        await _databaseHelper.updateZone(_currentZone.id, _currentZone.name, _currentZone.enabled ? 1 : 0, hasFertigation: newStatus);
        break;
      case 'Guardian':
        newStatus = !_currentZone.hasGuardian;
        await _databaseHelper.updateZone(_currentZone.id, _currentZone.name, _currentZone.enabled ? 1 : 0, hasGuardian: newStatus);
        break;
    }

    setState(() {
      _currentZone = _currentZone.copyWith(
        hasIrrigation: category == 'Irrigation' ? newStatus : null,
        hasLighting: category == 'Lighting' ? newStatus : null,
        hasHvac: category == 'HVAC' ? newStatus : null,
        hasAeration: category == 'Aeration' ? newStatus : null,
        hasCameras: category == 'Cameras' ? newStatus : null,
        hasFertigation: category == 'Fertigation' ? newStatus : null,
        hasGuardian: category == 'Guardian' ? newStatus : null,
      );
    });
  }

  Future<void> _saveAndFinish() async {
    // Always navigate to Zone Dashboard
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ZoneDashboardScreen(zone: _currentZone),
      ),
    );
  }

  bool get _shouldShowAeration {
    final mode = _growModeName.toLowerCase();
    return mode.contains('hydro') || 
           mode.contains('aero') || 
           mode.contains('dwc') || 
           mode.contains('nft') || 
           mode.contains('drip') ||
           mode.contains('ebb');
  }

  LinearGradient _getCategoryGradient(String category, bool isEnabled) {
    if (!isEnabled) {
      return LinearGradient(
        colors: [Colors.grey.shade800, Colors.grey.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    switch (category) {
      case 'Irrigation':
        return const LinearGradient(
          colors: [Color(0xFF0288D1), Color(0xFF29B6F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Lighting':
        return const LinearGradient(
          colors: [Color(0xFFF57F17), Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Sensing':
        return const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFFBA68C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'HVAC':
        return const LinearGradient(
          colors: [Color(0xFF455A64), Color(0xFF90A4AE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Aeration':
        return const LinearGradient(
          colors: [Color(0xFF00ACC1), Color(0xFF4DD0E1)], // Cyan
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Cameras':
        return const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)], // Indigo 900 to Indigo 600
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Sensor Hubs':
        return const LinearGradient(
          colors: [Color(0xFF263238), Color(0xFF455A64)], // Blue Grey
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Crop Management':
        return const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)], // Green
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Seedling Mat':
        return const LinearGradient(
          colors: [Color(0xFFD84315), Color(0xFFFF7043)], // Deep Orange
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Fertigation':
        return const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF4DB6AC)], // Teal
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Guardian':
        return const LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFFAB47BC)], // Purple
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Colors.grey, Colors.blueGrey],
        );
    }
  }

  Color _getCategoryColor(String category) {
    // Extract primary color from gradient
    final gradient = _getCategoryGradient(category, true);
    return gradient.colors.first;
  }
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Irrigation': return Icons.water_drop;
      case 'Lighting': return Icons.light_mode;
      case 'Sensing': return Icons.sensors;
      case 'HVAC': return Icons.wind_power;
      case 'Aeration': return Icons.air;

      case 'Cameras': return Icons.camera_alt;
      case 'Sensor Hubs': return Icons.hub;
      case 'Crop Management': return Icons.eco;
      case 'Seedling Mat': return Icons.grid_on;
      case 'Fertigation': return Icons.science;
      case 'Guardian': return Icons.security;
      default: return Icons.settings;
    }
  }

  LinearGradient _getGrowModeGradient(String modeName) {
    final mode = modeName.toLowerCase();
    if (mode.contains('soil')) {
      return const LinearGradient(
        colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (mode.contains('hydro')) {
      return const LinearGradient(
        colors: [Color(0xFF0277BD), Color(0xFF4FC3F7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (mode.contains('aero')) {
      return const LinearGradient(
        colors: [Color(0xFF455A64), Color(0xFF90A4AE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (mode.contains('drip')) {
      return const LinearGradient(
        colors: [Color(0xFF00695C), Color(0xFF4DB6AC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (mode.contains('ebb')) {
      return const LinearGradient(
        colors: [Color(0xFF1565C0), Color(0xFF64B5F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (mode.contains('nft')) {
      return const LinearGradient(
        colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF37474F), Color(0xFF78909C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  IconData _getGrowModeIcon(String modeName) {
    final mode = modeName.toLowerCase();
    if (mode.contains('soil')) return Icons.grass;
    if (mode.contains('hydro')) return Icons.water_drop;
    if (mode.contains('aero')) return Icons.air;
    if (mode.contains('drip')) return Icons.opacity;
    if (mode.contains('ebb')) return Icons.waves;
    if (mode.contains('nft')) return Icons.linear_scale;
    return Icons.eco;
  }

  Widget _buildCategoryTile(BuildContext context, String category) {
    bool isEnabled = false;
    switch (category) {
      case 'Irrigation': isEnabled = _currentZone.hasIrrigation; break;
      case 'Lighting': isEnabled = _currentZone.hasLighting; break;
      case 'HVAC': isEnabled = _currentZone.hasHvac; break;
      case 'Aeration': isEnabled = _currentZone.hasAeration; break;
      case 'Aeration': isEnabled = _currentZone.hasAeration; break;
      case 'Cameras': isEnabled = _hasAssignedCameras; break;
      case 'Seedling Mat': isEnabled = _hasSeedlingMat; break;
      case 'Fertigation': isEnabled = _currentZone.hasFertigation; break;
      case 'Guardian': isEnabled = _currentZone.hasGuardian; break;

      case 'Sensing': isEnabled = true; break; // Always enabled
      case 'Sensor Hubs': isEnabled = true; break; // Always enabled
      case 'Crop Management': isEnabled = true; break; // Always enabled
    }
    
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (category == 'Sensing') return; // Sensing is always on
          
          if (category == 'Cameras') {
            // Navigate to Camera Setup instead of just toggling
            await Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => CameraSetupScreen(zone: _currentZone))
            );
            // Refresh zone data on return in case enabled state changed inside setup
             final updatedZone = await _databaseHelper.getZone(_currentZone.id!);
             if (updatedZone != null) {
               setState(() => _currentZone = updatedZone);
             }
             await _checkAssignedCameras();
             return;

          }

          if (category == 'Sensor Hubs') {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HubNetworkScreen()),
            );
            return;
          }

          if (category == 'Crop Management') {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CropManagementScreen(zone: _currentZone)),
            );
            return;
          }

          if (category == 'Fertigation') {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FertigationSetupScreen(zone: _currentZone)),
            );
            // Refresh zone
             final updatedZone = await _databaseHelper.getZone(_currentZone.id!);
             if (updatedZone != null) {
               setState(() => _currentZone = updatedZone);
             }
            return;
          }

          if (category == 'Guardian') {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GuardianSetupScreen(zone: _currentZone)),
            );
            // Refresh zone
             final updatedZone = await _databaseHelper.getZone(_currentZone.id!);
             if (updatedZone != null) {
               setState(() => _currentZone = updatedZone);
             }
            return;
          }

          _toggleFeature(category);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isEnabled 
                    ? _getCategoryColor(category).withOpacity(0.2) 
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isEnabled 
                      ? _getCategoryColor(category).withOpacity(0.6) 
                      : Colors.white.withOpacity(0.1),
                  width: isEnabled ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: _getCategoryGradient(category, isEnabled),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: isEnabled ? Colors.white : Colors.white54,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    category,
                    style: TextStyle(
                      color: isEnabled ? Colors.white.withOpacity(0.9) : Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (isEnabled)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Irrigation', 'Lighting', 'Sensing', 'HVAC', 'Cameras', 'Sensor Hubs', 'Crop Management', 'Seedling Mat', 'Fertigation', 'Guardian'];
    if (_shouldShowAeration) {
      categories.insert(4, 'Aeration'); // Insert before Cameras
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leadingWidth: 80,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_growModeName.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _getGrowModeGradient(_growModeName),
                  border: Border.all(color: Colors.white24),
                ),
                child: Icon(
                  _getGrowModeIcon(_growModeName),
                  size: 16,
                  color: Colors.white,
                ),
              ),
            Column(
              children: [
                Text(
                  'Configure ${widget.zone.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_growModeName.isNotEmpty)
                  Text(
                    '$_growModeName Configuration',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4 + (_glowAnimation.value * 0.4)),
                      blurRadius: 10 + (_glowAnimation.value * 10),
                      spreadRadius: 1 + (_glowAnimation.value * 2),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: _saveAndFinish,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    backgroundColor: Colors.blue.withOpacity(0.2),
                  ),
                  child: Text(
                    'Enter Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.blueAccent,
                          blurRadius: 10 + (_glowAnimation.value * 10),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              if (_growModeName.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 20, 16, 0), // Reduced top margin from 100 to 20
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: _getGrowModeGradient(_growModeName),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getGrowModeIcon(_growModeName),
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _growModeName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Grow Configuration',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildCategoryTile(context, categories[0]),
                            const SizedBox(width: 16),
                            _buildCategoryTile(context, categories[1]),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildCategoryTile(context, categories[2]),
                            const SizedBox(width: 16),
                            _buildCategoryTile(context, categories[3]),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_shouldShowAeration) ...[
                          Row(
                            children: [
                              _buildCategoryTile(context, categories[4]),
                              const SizedBox(width: 16),
                              _buildCategoryTile(context, categories[5]), // Cameras
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildCategoryTile(context, categories[6]), // Sensor Hubs
                              const SizedBox(width: 16),
                              _buildCategoryTile(context, categories[7]), // Crop Management
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildCategoryTile(context, categories[8]), // Seedling Mat
                              const SizedBox(width: 16),
                              _buildCategoryTile(context, categories[9]), // Fertigation
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildCategoryTile(context, categories[10]), // Guardian
                              const SizedBox(width: 16),
                              const Spacer(),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              _buildCategoryTile(context, categories[4]), // Cameras
                              const SizedBox(width: 16),
                              _buildCategoryTile(context, categories[5]), // Sensor Hubs
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildCategoryTile(context, categories[6]), // Crop Management
                              const SizedBox(width: 16),
                              _buildCategoryTile(context, categories[7]), // Seedling Mat
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildCategoryTile(context, categories[8]), // Fertigation
                              const SizedBox(width: 16),
                              _buildCategoryTile(context, categories[9]), // Guardian
                            ],
                          ),
                        ],
                        const SizedBox(height: 80), // Bottom padding
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
}
