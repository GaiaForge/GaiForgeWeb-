import 'package:flutter/material.dart';
import '../base_control_card.dart';

class FertigationCard extends BaseControlCard {
  final double currentPh;
  final double currentEc;
  final double targetPh;
  final double targetEc;
  final String status; // 'Dosing', 'Idle', 'Error'
  final double? reservoirLevel;
  final VoidCallback? onSettingsTap;

  const FertigationCard({
    super.key,
    required super.zoneId,
    this.currentPh = 0.0,
    this.currentEc = 0.0,
    this.targetPh = 6.0,
    this.targetEc = 1.5,
    this.status = 'Idle',
    this.reservoirLevel,
    this.onSettingsTap,
    super.isCompact = false,
    super.onTap,
    super.onDetailTap,
  }) : super(
          title: 'Fertigation',
          icon: Icons.science,
          color: Colors.teal,
        );

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetric('pH', currentPh, targetPh, Colors.purpleAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetric('EC', currentEc, targetEc, Colors.tealAccent),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (reservoirLevel != null) ...[
          Row(
            children: [
              const Icon(Icons.water_drop, size: 14, color: Colors.blueAccent),
              const SizedBox(width: 4),
              Text('Reservoir: ${(reservoirLevel! * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              Text(status, style: TextStyle(color: _getStatusColor(), fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: reservoirLevel,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
            minHeight: 4,
          ),
        ] else
          Align(
            alignment: Alignment.centerRight,
            child: Text(status, style: TextStyle(color: _getStatusColor(), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildMetric(String label, double current, double target, Color color) {
    // Determine if out of range (tolerance: pH +/- 0.5, EC +/- 0.3)
    double tolerance = label == 'pH' ? 0.5 : 0.3;
    bool isOutOfRange = (current - target).abs() > tolerance;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isOutOfRange ? Colors.red.withOpacity(0.2) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOutOfRange ? Colors.redAccent : color.withOpacity(0.3),
          width: isOutOfRange ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: isOutOfRange ? Colors.redAccent : color, fontSize: 12, fontWeight: FontWeight.bold)),
              if (isOutOfRange)
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
            ],
          ),
          const SizedBox(height: 4),
          Text(current.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Target: $target', style: TextStyle(color: isOutOfRange ? Colors.redAccent.withOpacity(0.8) : Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'dosing': return Colors.greenAccent;
      case 'error': return Colors.redAccent;
      default: return Colors.white54;
    }
  }

  @override
  String getStatusText() {
    return 'pH: $currentPh | EC: $currentEc';
  }
}
