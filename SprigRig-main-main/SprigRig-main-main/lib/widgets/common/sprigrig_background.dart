import 'package:flutter/material.dart';

class SprigrigBackground extends StatelessWidget {
  final Widget child;
  final Color primaryColor;

  const SprigrigBackground({
    super.key, 
    required this.child,
    this.primaryColor = Colors.teal,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Deep organic base
        // Gradient Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/blue_gradient_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        // Primary Color Overlay (Subtle tint)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.1), // Lighten top-left
                  const Color(0xFF020617).withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
        
        // Subtle organic overlay (Sprigrig's Gaze)
        Positioned.fill(
          child: CustomPaint(
            painter: _SprigrigPainter(primaryColor),
          ),
        ),

        child,
      ],
    );
  }
}

class _SprigrigPainter extends CustomPainter {
  final Color color;
  _SprigrigPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.05)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    // Draw some organic "life" shapes
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 100, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 150, paint);
    
    // "Gaze" arc
    final arcPaint = Paint()
      ..color = color.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      
    canvas.drawArc(
      Rect.fromCenter(center: Offset(size.width/2, size.height/2), width: size.width * 0.8, height: size.width * 0.8),
      0, 3.14, false, arcPaint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
