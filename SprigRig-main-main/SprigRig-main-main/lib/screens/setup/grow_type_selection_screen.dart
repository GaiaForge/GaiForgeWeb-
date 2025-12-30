import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/app_background.dart';
import 'zone_configuration_screen.dart';

class GrowTypeSelectionScreen extends StatefulWidget {
  final Zone zone;

  const GrowTypeSelectionScreen({super.key, required this.zone});

  @override
  State<GrowTypeSelectionScreen> createState() => _GrowTypeSelectionScreenState();
}

class _GrowTypeSelectionScreenState extends State<GrowTypeSelectionScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _growModes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGrowModes();
  }

  Future<void> _loadGrowModes() async {
    final db = await _databaseHelper.database;
    final modes = await db.query('grow_modes');
    setState(() {
      _growModes = modes;
      _isLoading = false;
    });
  }

  Future<void> _selectGrowType(int modeId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    final db = await _databaseHelper.database;
    final growId = await db.insert('grows', {
      'grow_mode_id': modeId,
      'name': 'New Grow',
      'start_time': now,
      'status': 'active',
      'created_at': now,
      'updated_at': now,
    });

    final selectedMode = _growModes.firstWhere((m) => m['id'] == modeId);
    final modeName = selectedMode['name'] as String;

    await _databaseHelper.updateZone(
      widget.zone.id!,
      widget.zone.name,
      widget.zone.enabled ? 1 : 0,
      growId: growId,
      growMethod: modeName,
    );

    // Fetch the updated zone to ensure next screen has correct data
    final updatedZone = await _databaseHelper.getZone(widget.zone.id!);

    if (mounted && updatedZone != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ZoneConfigurationScreen(zone: updatedZone),
        ),
      );
    }
  }

  // Helper to get gradient for each mode
  LinearGradient _getModeGradient(String modeName) {
    switch (modeName.toLowerCase()) {
      case 'soil':
        return const LinearGradient(
          colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'hydroponic':
        return const LinearGradient(
          colors: [Color(0xFF0277BD), Color(0xFF4FC3F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'aeroponic':
        return const LinearGradient(
          colors: [Color(0xFF455A64), Color(0xFF90A4AE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'drip':
        return const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF4DB6AC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'ebb_and_flow':
        return const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'nft':
        return const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF37474F), Color(0xFF78909C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _getModeIcon(String modeName) {
    switch (modeName.toLowerCase()) {
      case 'soil': return Icons.grass;
      case 'hydroponic': return Icons.water_drop;
      case 'aeroponic': return Icons.air;
      case 'drip': return Icons.opacity;
      case 'ebb_and_flow': return Icons.waves;
      case 'nft': return Icons.linear_scale;
      default: return Icons.eco;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Select Grow Method'),
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
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: _growModes.length,
                        itemBuilder: (context, index) {
                          final mode = _growModes[index];
                          final modeName = mode['name'].toString();
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => _selectGrowType(mode['id'] as int),
                                    borderRadius: BorderRadius.circular(20),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // "Image" section (Gradient + Icon)
                                          Container(
                                            width: 100,
                                            decoration: BoxDecoration(
                                              gradient: _getModeGradient(modeName),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                _getModeIcon(modeName),
                                                color: Colors.white.withOpacity(0.9),
                                                size: 40,
                                              ),
                                            ),
                                          ),
                                          // Content section
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    modeName.toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                  if (mode['description'] != null) ...[
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      mode['description'],
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.7),
                                                        fontSize: 14,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Arrow
                                          Padding(
                                            padding: const EdgeInsets.only(right: 16),
                                            child: Icon(
                                              Icons.chevron_right,
                                              color: Colors.white.withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
