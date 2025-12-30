import 'package:flutter/material.dart';
import '../base_control_card.dart';

class GuardianCard extends BaseControlCard {
  final String lastCheck;
  final String latestAdvice;
  final bool isMonitoring;
  final VoidCallback? onSettingsTap;

  const GuardianCard({
    super.key,
    required super.zoneId,
    this.lastCheck = 'Never',
    this.latestAdvice = 'No advice yet.',
    this.isMonitoring = false,
    this.onSettingsTap,
    super.isCompact = false,
    super.onTap,
    super.onDetailTap,
  }) : super(
          title: 'Guardian AI',
          icon: Icons.psychology,
          color: Colors.purple,
        );

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isMonitoring ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isMonitoring ? Colors.green : Colors.grey),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: isMonitoring ? Colors.green : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    isMonitoring ? 'Monitoring' : 'Paused',
                    style: TextStyle(color: isMonitoring ? Colors.green : Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text('Last Check: $lastCheck', style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: Colors.purpleAccent),
                  SizedBox(width: 4),
                  Text('Latest Insight', style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                latestAdvice,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  String getStatusText() {
    return isMonitoring ? 'Active' : 'Paused';
  }
}
