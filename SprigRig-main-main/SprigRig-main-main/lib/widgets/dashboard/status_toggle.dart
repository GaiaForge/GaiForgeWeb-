import 'package:flutter/material.dart';

class StatusToggle extends StatelessWidget {
  final bool isOn;
  final Color activeColor;
  final VoidCallback onToggle;

  const StatusToggle({
    super.key,
    required this.isOn,
    required this.activeColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isOn ? activeColor : Colors.grey.shade700,
          boxShadow: isOn ? [
            BoxShadow(
              color: activeColor.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ] : [],
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              left: isOn ? 30 : 2,
              top: 2,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
