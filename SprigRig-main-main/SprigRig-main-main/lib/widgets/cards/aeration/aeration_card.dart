// lib/widgets/cards/aeration/aeration_card.dart
import 'package:flutter/material.dart';
import '../base_control_card.dart';

class AerationCard extends BaseControlCard {
  final bool isPumpOn;
  final String mode; // 'continuous' or 'timed'
  final String nextCycle; // e.g., "Always on", "Next: 2h 30m"
  final int pressure; // Air pressure percentage or level
  final VoidCallback? onToggle;
  final ValueChanged<String>? onModeChanged;

  const AerationCard({
    super.key,
    required super.zoneId,
    required this.isPumpOn,
    required this.mode,
    required this.nextCycle,
    required this.pressure,
    this.onToggle,
    this.onModeChanged,
    super.isCompact = false,
    super.onTap,
    super.onDetailTap,
  }) : super(
          title: 'Aeration',
          icon: Icons.air,
          color: Colors.lightBlue,
        );

  @override
  bool get hasDetailScreen => true; // Has detail screen

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status and pressure row
        Row(
          children: [
            Expanded(
              child: CardStatusIndicator(
                label: 'Pump Status',
                value: isPumpOn ? 'RUNNING' : 'OFF',
                color: isPumpOn ? Colors.green : Colors.grey,
                icon: isPumpOn ? Icons.air : Icons.stop_circle_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CardStatusIndicator(
                label: 'Air Pressure',
                value: '$pressure%',
                color: _getPressureColor(pressure),
                icon: Icons.speed,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Mode and next cycle info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPumpOn
                ? Colors.lightBlue.withValues(alpha:0.1)
                : Colors.grey.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPumpOn ? Colors.lightBlue : Colors.grey,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    mode == 'continuous' ? Icons.all_inclusive : Icons.schedule,
                    color: isPumpOn ? Colors.lightBlue : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode: ${mode == 'continuous' ? 'Continuous' : 'Timed'}',
                          style: TextStyle(
                            color: isPumpOn ? Colors.lightBlue : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nextCycle,
                          style: TextStyle(
                            color: isPumpOn ? Colors.lightBlue : Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Quick action buttons
        Row(
          children: [
            Expanded(
              child: CardActionButton(
                label: isPumpOn ? 'Turn Off' : 'Turn On',
                icon: isPumpOn ? Icons.stop : Icons.play_arrow,
                color: isPumpOn ? Colors.red : Colors.green,
                onPressed: onToggle,
                isSelected: isPumpOn,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CardActionButton(
                label: mode == 'continuous' ? 'Timed' : 'Continuous',
                icon: mode == 'continuous' ? Icons.schedule : Icons.all_inclusive,
                color: Colors.lightBlue,
                onPressed: () {
                  final newMode = mode == 'continuous' ? 'timed' : 'continuous';
                  onModeChanged?.call(newMode);
                },
                isSelected: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  String getStatusText() {
    if (isPumpOn) {
      return mode == 'continuous' ? 'ON • Continuous' : 'ON • Timed';
    } else {
      return 'OFF';
    }
  }

  @override
  Widget? buildDetailScreen(BuildContext context) {
    return AerationDetailScreen(
      zoneId: zoneId,
      isPumpOn: isPumpOn,
      mode: mode,
      nextCycle: nextCycle,
      pressure: pressure,
      onToggle: onToggle,
      onModeChanged: onModeChanged,
    );
  }

  Color _getPressureColor(int pressure) {
    if (pressure >= 80) return Colors.green;
    if (pressure >= 60) return Colors.yellow;
    if (pressure >= 40) return Colors.orange;
    return Colors.red;
  }
}

/// Simple aeration detail screen
class AerationDetailScreen extends StatefulWidget {
  final int zoneId;
  final bool isPumpOn;
  final String mode;
  final String nextCycle;
  final int pressure;
  final VoidCallback? onToggle;
  final ValueChanged<String>? onModeChanged;

  const AerationDetailScreen({
    super.key,
    required this.zoneId,
    required this.isPumpOn,
    required this.mode,
    required this.nextCycle,
    required this.pressure,
    this.onToggle,
    this.onModeChanged,
  });

  @override
  State<AerationDetailScreen> createState() => _AerationDetailScreenState();
}

class _AerationDetailScreenState extends State<AerationDetailScreen> {
  late bool _isPumpOn;
  late String _mode;

  @override
  void initState() {
    super.initState();
    _isPumpOn = widget.isPumpOn;
    _mode = widget.mode;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.lightBlue, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.air, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Aeration Control',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildModeCard(),
                  const SizedBox(height: 16),
                  _buildPressureCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha:0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Air Pump Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isPumpOn 
                      ? Colors.green.withValues(alpha:0.2)
                      : Colors.grey.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPumpOn ? Colors.green : Colors.grey,
                  ),
                ),
                child: Text(
                  _isPumpOn ? 'RUNNING' : 'OFF',
                  style: TextStyle(
                    color: _isPumpOn ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Large toggle button
          GestureDetector(
            onTap: () {
              setState(() {
                _isPumpOn = !_isPumpOn;
              });
              widget.onToggle?.call();
            },
            child: Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isPumpOn
                      ? [Colors.lightBlue, Colors.blue]
                      : [Colors.grey.shade700, Colors.grey.shade800],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isPumpOn ? [
                  BoxShadow(
                    color: Colors.lightBlue.withValues(alpha:0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ] : null,
              ),
              child: Icon(
                _isPumpOn ? Icons.air : Icons.stop_circle_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha:0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operation Mode',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModeButton('Continuous', 'continuous', Icons.all_inclusive),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeButton('Timed', 'timed', Icons.schedule),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _mode == 'continuous' 
                ? 'Pump runs continuously for maximum oxygenation'
                : 'Pump runs on scheduled intervals to save energy',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, String value, IconData icon) {
    final isSelected = _mode == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = value;
        });
        widget.onModeChanged?.call(value);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.lightBlue.withValues(alpha:0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.lightBlue : Colors.grey.shade600,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.lightBlue : Colors.grey.shade400,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.lightBlue : Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPressureCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha:0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Air Pressure Monitor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.speed,
                color: _getPressureColor(widget.pressure),
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.pressure}%',
                      style: TextStyle(
                        color: _getPressureColor(widget.pressure),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getPressureStatus(widget.pressure),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPressureColor(int pressure) {
    if (pressure >= 80) return Colors.green;
    if (pressure >= 60) return Colors.yellow;
    if (pressure >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getPressureStatus(int pressure) {
    if (pressure >= 80) return 'Optimal pressure';
    if (pressure >= 60) return 'Good pressure';
    if (pressure >= 40) return 'Low pressure';
    return 'Critical - check pump';
  }
}