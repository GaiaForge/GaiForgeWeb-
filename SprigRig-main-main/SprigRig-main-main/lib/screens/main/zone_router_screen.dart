// lib/screens/main/zone_router_screen.dart
import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../models/grow.dart';
import '../../models/zone.dart';

/// Smart router that determines where to send users based on their zones
class ZoneRouterScreen extends StatefulWidget {
  const ZoneRouterScreen({super.key});

  @override
  State<ZoneRouterScreen> createState() => _ZoneRouterScreenState();
}

class _ZoneRouterScreenState extends State<ZoneRouterScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _determineRoute();
  }

  Future<void> _determineRoute() async {
    try {
      // Get active grows and their zones
      final activeGrows = await _db.getActiveGrows();
      
      if (activeGrows.isEmpty) {
        // No active grows - back to setup
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/setup/welcome');
        }
        return;
      }

      // Get zones for the first active grow (or all zones if multiple grows)
      List<Zone> zones;
      if (activeGrows.length == 1) {
        zones = await _db.getZones(growId: activeGrows.first.id);
      } else {
        zones = await _db.getZones(); // All zones across grows
      }

      if (zones.isEmpty) {
        // Active grow but no zones - shouldn't happen, but handle gracefully
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/zones/management');
        }
        return;
      }

      // Always show zone selection screen (Welcome Screen)
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/zones/selection');
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading zones: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
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
        child: Center(
          child: _errorMessage != null
              ? _buildErrorView()
              : _buildLoadingView(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.eco, size: 80, color: Colors.green),
        SizedBox(height: 24),
        Text(
          'SprigRig',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
        SizedBox(height: 16),
        Text(
          'Loading your growing zones...',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading Error',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  _determineRoute();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/zones/management');
                },
                icon: const Icon(Icons.settings),
                label: const Text('Manage Zones'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}