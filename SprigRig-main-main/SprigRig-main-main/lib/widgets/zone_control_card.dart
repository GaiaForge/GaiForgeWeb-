import 'package:flutter/material.dart';
import '../models/zone.dart';

class ZoneControlCard extends StatelessWidget {
  final Zone zone;
  final bool isActive;
  final VoidCallback onToggle;

  const ZoneControlCard({
    super.key,
    required this.zone,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: zone.enabled ? onToggle : null,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isActive
                    ? Colors.green.withValues(alpha: 0.6)
                    : zone.enabled
                    ? Colors.grey.shade700.withValues(alpha: 0.5)
                    : Colors.grey.shade600.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with gradient background
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isActive
                          ? [Colors.green.shade400, Colors.blue.shade500]
                          : zone.enabled
                          ? [Colors.blue.shade300, Colors.cyan.shade400]
                          : [Colors.grey.shade500, Colors.grey.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow:
                    isActive
                        ? [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ]
                        : null,
              ),
              child: Icon(
                isActive ? Icons.opacity : Icons.opacity_outlined,
                size: 24,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            // Zone name
            Text(
              zone.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: zone.enabled ? Colors.white : Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),

            const SizedBox(height: 6),

            // Status text with colored background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusBackgroundColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(), width: 1),
              ),
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Toggle switch (only if enabled)
            if (zone.enabled)
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 44,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment:
                        isActive ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              )
            else
              // Disabled indicator
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.block, size: 14, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    if (isActive) return 'Active';
    if (zone.enabled) return 'Ready';
    return 'Disabled';
  }

  Color _getStatusColor() {
    if (isActive) return Colors.green;
    if (zone.enabled) return Colors.blue;
    return Colors.grey;
  }

  Color _getStatusBackgroundColor() {
    if (isActive) return Colors.green;
    if (zone.enabled) return Colors.blue;
    return Colors.grey;
  }
}
