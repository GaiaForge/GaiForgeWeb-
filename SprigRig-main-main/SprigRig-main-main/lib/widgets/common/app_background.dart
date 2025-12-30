import 'dart:math';
import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/blue_gradient_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        // Dark Overlay (Subtle)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.0), // Lighten left side
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),

        // Content
        child,
      ],
    );
  }
}

class _ForgedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60); // Soft smoke

    final random = Random(42); 

    // Draw subtle "heat" or "smoke" patches
    for (int i = 0; i < 4; i++) {
      // Warm glow (Forge heat) or Cool shadow (Metal)
      paint.color = i.isEven 
          ? const Color(0xFFD97706).withOpacity(0.03) // Amber/Gold (Heat)
          : const Color(0xFF60A5FA).withOpacity(0.02); // Blue (Steel reflection)

      final path = Path();
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      
      path.moveTo(startX, startY);
      
      // Create organic smoke shapes
      for (int j = 0; j < 4; j++) {
        path.quadraticBezierTo(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        );
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    // Draw "scratches" or "brushed metal" lines
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.03);

    for (int i = 0; i < 5; i++) {
      final path = Path();
      double y = random.nextDouble() * size.height;
      path.moveTo(0, y);
      path.lineTo(size.width, y + (random.nextDouble() - 0.5) * 100); // Slight angle
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
