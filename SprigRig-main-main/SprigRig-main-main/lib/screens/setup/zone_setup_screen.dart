import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../models/grow.dart';
import '../../services/database_helper.dart';
import '../../widgets/backgrounds/animated_wheat_field.dart';
import 'grow_type_selection_screen.dart';
import '../zones/zone_create_edit_screen.dart';
import 'zone_configuration_screen.dart';
import '../dashboard/zone_dashboard_screen.dart';
import '../settings/settings_screen.dart';

class ZoneSetupScreen extends StatefulWidget {
  const ZoneSetupScreen({super.key});

  @override
  State<ZoneSetupScreen> createState() => _ZoneSetupScreenState();
}

class _ZoneSetupScreenState extends State<ZoneSetupScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Zone> _zones = [];
  List<Grow> _grows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    setState(() => _isLoading = true);
    final zones = await _databaseHelper.getZones();
    final grows = await _databaseHelper.getGrows();
    setState(() {
      _zones = zones;
      _grows = grows;
      _isLoading = false;
    });
  }

  Future<void> _addZone() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ZoneCreateEditScreen(grows: _grows),
      ),
    );
    await _loadZones();
  }

  Future<void> _editZone(Zone zone) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ZoneCreateEditScreen(zone: zone, grows: _grows),
      ),
    );
    await _loadZones();
  }

  Future<void> _deleteZone(Zone zone) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Zone?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${zone.name}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _databaseHelper.deleteZone(zone.id!); 
      await _loadZones();
    }
  }

  Future<void> _navigateToSetup(Zone zone) async {
    // If grow method is already configured, skip selection and go to configuration
    if (zone.growMethod.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ZoneConfigurationScreen(zone: zone),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GrowTypeSelectionScreen(zone: zone),
        ),
      );
    }
    await _loadZones();
  }

  void _navigateToDashboard(Zone zone) async {
    // Enforce grow method selection
    if (zone.growMethod.isEmpty) {
      if (!mounted) return;
      
      // Directly navigate without SnackBar
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GrowTypeSelectionScreen(zone: zone),
        ),
      );
      
      // Reload zone to check if method was selected
      await _loadZones();
      return;
    }

    // Ensure setup is marked as complete when entering the dashboard
    await _databaseHelper.completeSetup();
    
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ZoneDashboardScreen(zone: zone),
      ),
    );
  }

  String _formatGrowMethod(String method) {
    if (method.isEmpty) return 'Not configured';
    return method.split('_').map((word) => 
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
  }

  Future<void> _showGrowMethodInfo(String growMethod) async {
    if (growMethod.isEmpty) return;

    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'grow_modes',
      columns: ['description'],
      where: 'name = ?',
      whereArgs: [growMethod],
    );

    if (!mounted) return;

    final description = result.isNotEmpty 
        ? result.first['description'] as String? 
        : 'No description available for this grow method.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatGrowMethod(growMethod),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          description ?? 'No description available.',
          style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _zones.isEmpty
          ? AnimatedWheatField(
              child: SafeArea(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF4ADE80)))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 80),
                          
                          // Subtitle text (centered)
                          Text(
                            'Create your first zone to start cultivating',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          // Hovering Create Zone button (centered)
                          Center(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 800),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, (1 - value) * 20),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: _HoveringButton(
                                onPressed: _addZone,
                                label: 'Create Zone',
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            )
          : AnimatedWheatField(
              child: SafeArea(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF4ADE80)))
                    : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _zones.length,
                      itemBuilder: (context, index) {
                        final zone = _zones[index];
                        if (!zone.enabled) return const SizedBox.shrink();
                        
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
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(20),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.eco, color: Colors.green),
                                  ),
                                  title: Text(
                                    zone.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                    subtitle: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => _showGrowMethodInfo(zone.growMethod),
                                          child: Icon(Icons.info_outline, size: 16, color: Colors.white.withOpacity(0.5)),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatGrowMethod(zone.growMethod),
                                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                        ),
                                      ],
                                    ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.white70),
                                        onPressed: () => _editZone(zone),
                                        tooltip: 'Edit Zone Details',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.settings, color: Colors.white70),
                                        onPressed: () => _navigateToSetup(zone),
                                        tooltip: 'Configure Zone',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: Colors.white.withOpacity(0.3)),
                                        onPressed: () => _deleteZone(zone),
                                        tooltip: 'Delete Zone',
                                      ),
                                      const Icon(Icons.chevron_right, color: Colors.white54),
                                    ],
                                  ),
                                  onTap: () => _navigateToDashboard(zone),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ),
      floatingActionButton: _zones.isNotEmpty
          ? FloatingActionButton(
              heroTag: 'add',
              onPressed: _addZone,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

/// A beautiful hovering button with subtle float animation and glow
class _HoveringButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;

  const _HoveringButton({
    required this.onPressed,
    required this.label,
  });

  @override
  State<_HoveringButton> createState() => _HoveringButtonState();
}

class _HoveringButtonState extends State<_HoveringButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              widget.onPressed();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedScale(
              scale: _isPressed ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.eco_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0), // Light gray
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                        fontStyle: FontStyle.italic, // Organic feel
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
