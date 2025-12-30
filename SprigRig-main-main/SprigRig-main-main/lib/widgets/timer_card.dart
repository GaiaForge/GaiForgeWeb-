// lib/widgets/timer_card.dart
import 'package:flutter/material.dart';
import '../models/timer.dart';

class TimerCard extends StatelessWidget {
  final WateringTimer timer;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggle;

  const TimerCard({
    super.key,
    required this.timer,
    this.isActive = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isActive ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.green : Colors.transparent,
          width: isActive ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Timer type icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: _getTimerGradient()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getTimerIcon(), color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),

                  // Timer info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTimerTitle(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timer.getDescription(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status and toggle
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getStatusColor()),
                        ),
                        child: Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(),
                          ),
                        ),
                      ),
                      if (onToggle != null) ...[
                        const SizedBox(height: 8),
                        Switch(
                          value: timer.enabled,
                          onChanged: (_) => onToggle?.call(),
                          activeColor: Colors.green,
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Next run info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: isActive ? Colors.blue : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isActive
                            ? 'Currently running...'
                            : 'Next: ${timer.getFormattedNextRun()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.blue : Colors.grey.shade600,
                          fontWeight:
                              isActive ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                      ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getTimerTitle() {
    switch (timer.type) {
      case 'interval':
        return 'Interval Timer';
      case 'sunrise':
        return 'Sunrise Timer';
      case 'sunset':
        return 'Sunset Timer';
      case 'time':
        return 'Scheduled Timer';
      default:
        return 'Watering Timer';
    }
  }

  IconData _getTimerIcon() {
    switch (timer.type) {
      case 'interval':
        return Icons.loop;
      case 'sunrise':
        return Icons.wb_sunny;
      case 'sunset':
        return Icons.nightlight_round;
      case 'time':
        return Icons.access_time;
      default:
        return Icons.timer;
    }
  }

  List<Color> _getTimerGradient() {
    switch (timer.type) {
      case 'interval':
        return [Colors.blue.shade400, Colors.cyan.shade500];
      case 'sunrise':
        return [Colors.orange.shade400, Colors.yellow.shade500];
      case 'sunset':
        return [Colors.purple.shade400, Colors.indigo.shade500];
      case 'time':
        return [Colors.green.shade400, Colors.teal.shade500];
      default:
        return [Colors.grey.shade400, Colors.grey.shade600];
    }
  }

  String _getStatusText() {
    if (isActive) return 'ACTIVE';
    if (timer.enabled) return 'ENABLED';
    return 'DISABLED';
  }

  Color _getStatusColor() {
    if (isActive) return Colors.blue;
    if (timer.enabled) return Colors.green;
    return Colors.grey;
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Timer'),
            content: const Text('Are you sure you want to delete this timer?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('DELETE'),
              ),
            ],
          ),
    );

    if (result == true) {
      onDelete?.call();
    }
  }
}
