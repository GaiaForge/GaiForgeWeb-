import 'package:flutter/material.dart';
import '../models/timer.dart';

class TimerListItem extends StatelessWidget {
  final WateringTimer timer;
  final bool isActive;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TimerListItem({
    super.key,
    required this.timer,
    required this.isActive,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _getTimerGradient()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getTimerIcon(), size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTimerTitle(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timer.getDescription(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      timer.enabled
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: timer.enabled ? Colors.green : Colors.grey,
                    width: 1,
                  ),
                ),
                child: Text(
                  timer.enabled ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: timer.enabled ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Next run info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade700.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: isActive ? Colors.blue : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isActive
                        ? 'Currently running...'
                        : 'Next: ${timer.getFormattedNextRun()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.blue : Colors.grey.shade400,
                      fontWeight:
                          isActive ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                label: const Text('Edit', style: TextStyle(color: Colors.blue)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                label: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Get the appropriate icon based on timer type
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

  // Get gradient colors based on timer type
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

  // Get a descriptive title for the timer
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

  // Show a confirmation dialog before deleting
  Future<void> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey.shade800,
            title: const Text(
              'Delete Timer',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to delete this timer?',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(color: Colors.grey),
                ),
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
      onDelete();
    }
  }
}
