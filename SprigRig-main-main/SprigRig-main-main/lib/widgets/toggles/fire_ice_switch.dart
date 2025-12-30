import 'package:flutter/material.dart';

class FireIceSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const FireIceSwitch({
    super.key, 
    required this.value, 
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 64,
        height: 34,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: value
                ? [Colors.orange.shade400, Colors.deepOrange.shade700] // Fire
                : [Colors.cyan.shade900, Colors.blue.shade900], // Ice
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: value ? Colors.orange.withOpacity(0.5) : Colors.cyan.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),

          ],
          border: Border.all(
            color: value ? Colors.orangeAccent.withOpacity(0.5) : Colors.cyanAccent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              left: value ? 32 : 2,
              top: 1,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: value ? Colors.orange.withOpacity(0.6) : Colors.cyan.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      value ? Icons.local_fire_department_rounded : Icons.ac_unit_rounded,
                      key: ValueKey(value),
                      size: 18,
                      color: value ? Colors.deepOrange : Colors.cyan.shade700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
