// lib/widgets/cards/irrigation/irrigation_card.dart
import 'package:flutter/material.dart';
import '../base_control_card.dart';
import 'irrigation_detail_screen.dart';

class IrrigationCard extends BaseControlCard {
  final bool isWatering;
  final int soilMoisture;
  final String duration;
  final String nextWatering;
  final String mode; // 'manual', 'automatic', 'moisture-based'
  final VoidCallback? onToggle;
  final ValueChanged<String>? onDurationChanged;
  final ValueChanged<String>? onModeChanged;

  const IrrigationCard({
    super.key,
    required super.zoneId,
    required this.isWatering,
    required this.soilMoisture,
    required this.duration,
    required this.nextWatering,
    required this.mode,
    this.onToggle,
    this.onDurationChanged,
    this.onModeChanged,
    super.isCompact = false,
    super.onTap,
    super.onDetailTap,
  }) : super(
          title: 'Irrigation',
          icon: Icons.water_drop,
          color: Colors.blue,
        );

  @override
  bool get hasDetailScreen => true; // Has detail screen

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status and moisture row
        Row(
          children: [
            Expanded(
              child: CardStatusIndicator(
                label: 'Status',
                value: isWatering ? 'WATERING' : 'READY',
                color: isWatering ? Colors.green : Colors.grey,
                icon: isWatering ? Icons.water : Icons.water_drop_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CardStatusIndicator(
                label: 'Soil Moisture',
                value: '$soilMoisture%',
                color: _getMoistureColor(soilMoisture),
                icon: Icons.opacity,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Mode and schedule info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isWatering
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isWatering ? Colors.blue : Colors.grey,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _getModeIcon(mode),
                    color: isWatering ? Colors.blue : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getModeDisplayName(mode),
                      style: TextStyle(
                        color: isWatering ? Colors.blue : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    duration,
                    style: TextStyle(
                      color: isWatering ? Colors.blue : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (nextWatering.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.grey.shade400,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      nextWatering,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const Spacer(),

        // Quick action buttons
        Row(
          children: [
            Expanded(
              child: CardActionButton(
                label: isWatering ? 'Stop' : 'Start',
                icon: isWatering ? Icons.stop : Icons.play_arrow,
                color: isWatering ? Colors.red : Colors.blue,
                onPressed: onToggle,
                isSelected: false,
              ),
            ),
            const SizedBox(width: 8),
            CardActionButton(
              label: 'Quick',
              icon: Icons.flash_on,
              color: Colors.orange,
              onPressed: () {
                // Quick 30-second watering
                debugPrint('Quick watering triggered');
              },
              isSelected: false,
            ),
          ],
        ),
      ],
    );
  }

  @override
  String getStatusText() {
    if (isWatering) {
      return 'Watering • $duration';
    } else {
      return 'Moisture: $soilMoisture%';
    }
  }

  @override
  Widget? buildDetailScreen(BuildContext context) {
    return IrrigationDetailScreen(
      zoneId: zoneId,
      isRunning: isWatering,
      soilMoisture: soilMoisture,
      wateringDuration: duration,
      schedule: nextWatering,
      mode: mode,
      onToggle: onToggle,
      onDurationChanged: onDurationChanged,
      onModeChanged: onModeChanged,
    );
  }

  Color _getMoistureColor(int moisture) {
    if (moisture >= 60) return Colors.green;
    if (moisture >= 40) return Colors.yellow;
    if (moisture >= 20) return Colors.orange;
    return Colors.red;
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'manual': return Icons.touch_app;
      case 'automatic': return Icons.schedule;
      case 'moisture-based': return Icons.water_drop;
      default: return Icons.settings;
    }
  }

  String _getModeDisplayName(String mode) {
    switch (mode) {
      case 'manual': return 'Manual';
      case 'automatic': return 'Scheduled';
      case 'moisture-based': return 'Smart';
      default: return mode;
    }
  }
}

