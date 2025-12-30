import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/modbus_service.dart';
import '../../widgets/common/app_background.dart';

class RelayTestScreen extends StatefulWidget {
  const RelayTestScreen({super.key});

  @override
  State<RelayTestScreen> createState() => _RelayTestScreenState();
}

class _RelayTestScreenState extends State<RelayTestScreen> {
  final ModbusService _modbus = ModbusService();
  
  // 8 Relays, default to false (OFF)
  List<bool> _relayStates = List.filled(8, false);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRelayStates();
  }

  Future<void> _loadRelayStates({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Assuming Slave Address 1 for the main relay board
      final states = await _modbus.getAllRelayStates(1);
      
      if (mounted) {
        setState(() {
          if (states.isNotEmpty) {
            // Ensure we have at least 8 states, pad if necessary (though service should return 8)
            if (states.length >= 8) {
              _relayStates = states.sublist(0, 8);
            } else {
              _relayStates = List.from(states)..addAll(List.filled(8 - states.length, false));
            }
          } else {
            // Silently fail or log if needed, but don't show error to user
            debugPrint('Failed to read relay states');
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setRelay(int index, bool newState) async {
    // Optimistic update for responsiveness
    setState(() {
      _relayStates[index] = newState;
    });

    try {
      final success = await _modbus.setRelay(index, newState);
      if (success) {
        // Read back actual state to confirm
        await _loadRelayStates(showLoading: false);
      } else {
        debugPrint('Failed to set Relay ${index + 1}');
        // Revert on failure
        await _loadRelayStates(showLoading: false);
      }
    } catch (e) {
      debugPrint('Error setting relay: $e');
      await _loadRelayStates(showLoading: false);
    }
  }

  Future<void> _setAllRelays(bool state) async {
    // Optimistic update
    setState(() {
      _relayStates = List.filled(8, state);
    });
    
    try {
      final success = await _modbus.controlAllRelays(state);
      // Always reload to get true state
      await _loadRelayStates(showLoading: false);
      
      if (!success) {
        debugPrint('Failed to set all relays');
      }
    } catch (e) {
      debugPrint('Error setting all relays: $e');
      if (mounted) await _loadRelayStates(showLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Relay Test', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadRelayStates,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // 4 columns
                        childAspectRatio: 1.1, // Slightly wider/shorter to fit better
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        return _RelayToggleTile(
                          index: index,
                          isOn: _relayStates[index],
                          onToggle: (newState) => _setRelay(index, newState),
                        );
                      },
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'All ON',
                      icon: Icons.flash_on,
                      color: Colors.green,
                      onPressed: _isLoading ? null : () => _setAllRelays(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      label: 'All OFF',
                      icon: Icons.flash_off,
                      color: Colors.redAccent,
                      onPressed: _isLoading ? null : () => _setAllRelays(false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 28),
          label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.2),
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 20),
            elevation: 0,
            side: BorderSide(color: color.withOpacity(0.5), width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}

class _RelayToggleTile extends StatefulWidget {
  final int index;
  final bool isOn;
  final ValueChanged<bool> onToggle;

  const _RelayToggleTile({
    required this.index,
    required this.isOn,
    required this.onToggle,
  });

  @override
  State<_RelayToggleTile> createState() => _RelayToggleTileState();
}

class _RelayToggleTileState extends State<_RelayToggleTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onToggle(!widget.isOn);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isOn ? Colors.amber : Colors.white;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: widget.isOn 
                    ? Colors.amber.withOpacity(0.15) 
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isOn 
                      ? Colors.amber.withOpacity(0.6) 
                      : Colors.white.withOpacity(0.1),
                  width: widget.isOn ? 2 : 1,
                ),
                boxShadow: widget.isOn
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8), // Reduced from 12
                    decoration: BoxDecoration(
                      color: widget.isOn ? Colors.amber : Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.power_settings_new,
                      color: widget.isOn ? Colors.black : Colors.white54,
                      size: 24, // Reduced from 32
                    ),
                  ),
                  const SizedBox(height: 8), // Reduced from 16
                  Text(
                    'RELAY ${widget.index + 1}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10, // Reduced from 12
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isOn ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: widget.isOn
                          ? [Shadow(color: Colors.amber.withOpacity(0.8), blurRadius: 8)]
                          : [],
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
}
