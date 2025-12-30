import 'package:flutter/material.dart';

class CycleProgressDots extends StatelessWidget {
  final int completed;
  final int total;
  final Color activeColor;

  const CycleProgressDots({
    super.key,
    required this.completed,
    required this.total,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (index) {
        final isCompleted = index < completed;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? activeColor : Colors.transparent,
            border: Border.all(
              color: isCompleted ? activeColor : Colors.white24,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}
