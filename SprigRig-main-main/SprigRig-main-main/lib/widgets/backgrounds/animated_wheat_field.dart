import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A beautiful animated wheat field background with sunset and gentle wind animation.
/// Creates a serene, nature-themed backdrop for the zone overview screen.
class AnimatedWheatField extends StatefulWidget {
  final Widget child;
  
  const AnimatedWheatField({super.key, required this.child});

  @override
  State<AnimatedWheatField> createState() => _AnimatedWheatFieldState();
}

class _AnimatedWheatFieldState extends State<AnimatedWheatField>
    with TickerProviderStateMixin {
  late AnimationController _windController;
  late AnimationController _sunController;

  @override
  void initState() {
    super.initState();
    _windController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    // Slow sun setting animation (very subtle movement)
    _sunController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _windController.dispose();
    _sunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_windController, _sunController]),
      builder: (context, child) {
        // Sun position (slowly descends behind mountains)
        final sunOffset = _sunController.value * 15; // 0 to 15 pixels
        
        return Stack(
          children: [
            // Natural dusk sky gradient - beautiful sunset colors
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0B1026), // Deep night blue at top
                    Color(0xFF1A1B3A), // Dark indigo
                    Color(0xFF2E2A52), // Soft purple
                    Color(0xFF4A3B5C), // Lavender dusk
                    Color(0xFF6B4E60), // Dusty rose
                    Color(0xFF9D6B6B), // Warm mauve
                    Color(0xFFD4A574), // Soft peach
                    Color(0xFFE8C49A), // Golden peach horizon
                    Color(0xFF2A3828), // Forest green base
                  ],
                  stops: [0.0, 0.1, 0.2, 0.32, 0.44, 0.56, 0.68, 0.78, 1.0],
                ),
              ),
            ),

            // Warm horizon glow
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFFFFB366).withOpacity(0.25), // Warm orange
                      const Color(0xFFE8A87C).withOpacity(0.15), // Soft coral
                      const Color(0xFFD4A574).withOpacity(0.08), // Peach
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Animated setting sun (slowly sinking behind mountains)
            Positioned(
              bottom: 100 - sunOffset, // Sun slowly descends
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFE4B5).withOpacity(0.95), // Pale golden center
                        const Color(0xFFFFD180).withOpacity(0.7),  // Soft amber
                        const Color(0xFFFFB366).withOpacity(0.4),  // Warm orange
                        const Color(0xFFE88B4D).withOpacity(0.15), // Coral fade
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD180).withOpacity(0.4),
                        blurRadius: 50,
                        spreadRadius: 30,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFFB366).withOpacity(0.2),
                        blurRadius: 80,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Soft pink/lavender atmospheric haze
            Positioned(
              bottom: 70 - sunOffset / 2,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.6),
                    radius: 1.2,
                    colors: [
                      const Color(0xFFE8C49A).withOpacity(0.12), // Warm peach
                      const Color(0xFFD4A0A0).withOpacity(0.06), // Soft pink
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Mountain silhouette layer
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(double.infinity, 150),
                painter: _MountainSilhouettePainter(),
              ),
            ),

            // Animated wheat field
            CustomPaint(
              painter: _WheatFieldPainter(
                windProgress: _windController.value,
              ),
              size: Size.infinite,
            ),

            // Content
            widget.child,
          ],
        );
      },
    );
  }
}

/// Custom painter that draws animated wheat stalks
class _WheatFieldPainter extends CustomPainter {
  final double windProgress;
  final math.Random _random = math.Random(42); // Fixed seed for consistent wheat positions

  _WheatFieldPainter({required this.windProgress});

  @override
  void paint(Canvas canvas, Size size) {
    // Only draw in bottom portion
    final fieldTop = size.height * 0.6;
    final fieldHeight = size.height - fieldTop;

    // Draw multiple layers for depth
    _drawWheatLayer(canvas, size, fieldTop, fieldHeight, 0.3, 0.4, 8);  // Back layer
    _drawWheatLayer(canvas, size, fieldTop, fieldHeight, 0.5, 0.6, 12); // Middle layer
    _drawWheatLayer(canvas, size, fieldTop, fieldHeight, 0.7, 0.8, 16); // Front layer
  }

  void _drawWheatLayer(
    Canvas canvas,
    Size size,
    double fieldTop,
    double fieldHeight,
    double opacity,
    double heightFactor,
    int density,
  ) {
    final spacing = size.width / density;

    for (int i = 0; i < density + 2; i++) {
      final baseX = (i - 1) * spacing + _random.nextDouble() * spacing * 0.5;
      final stalkHeight = fieldHeight * (0.3 + _random.nextDouble() * 0.4) * heightFactor;
      
      // Calculate wind sway using sine wave - more sway (12px), consistent speed
      final phase = i * 0.25 + windProgress * 2 * math.pi;
      final sway = math.sin(phase) * 12 * heightFactor;
      
      _drawWheatStalk(
        canvas,
        Offset(baseX, size.height),
        stalkHeight,
        sway,
        opacity,
      );
    }
  }

  void _drawWheatStalk(
    Canvas canvas,
    Offset base,
    double height,
    double sway,
    double opacity,
  ) {
    // Wheat stalk colors
    final stalkColor = Color.lerp(
      const Color(0xFF8B7355),
      const Color(0xFFD4A574),
      _random.nextDouble(),
    )!.withOpacity(opacity * 0.6);

    final grainColor = Color.lerp(
      const Color(0xFFDEB887),
      const Color(0xFFF5DEB3),
      _random.nextDouble(),
    )!.withOpacity(opacity);

    // Draw curved stalk
    final stalkPaint = Paint()
      ..color = stalkColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final stalkPath = Path();
    stalkPath.moveTo(base.dx, base.dy);

    // Create natural curve with wind sway
    final controlPoint1 = Offset(base.dx + sway * 0.3, base.dy - height * 0.5);
    final controlPoint2 = Offset(base.dx + sway * 0.8, base.dy - height * 0.8);
    final endPoint = Offset(base.dx + sway, base.dy - height);

    stalkPath.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      endPoint.dx, endPoint.dy,
    );

    canvas.drawPath(stalkPath, stalkPaint);

    // Draw wheat head (grain cluster)
    _drawWheatHead(canvas, endPoint, sway * 0.1, grainColor, height * 0.15);
  }

  void _drawWheatHead(
    Canvas canvas,
    Offset position,
    double tilt,
    Color color,
    double size,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw oval grain clusters
    final grainCount = 4 + _random.nextInt(3);
    for (int i = 0; i < grainCount; i++) {
      final yOffset = i * size * 0.25;
      final xOffset = math.sin(i * 0.5) * size * 0.15 + tilt;
      final grainSize = size * (0.12 - i * 0.015);

      canvas.save();
      canvas.translate(position.dx + xOffset, position.dy + yOffset);
      canvas.rotate(tilt * 0.1);
      
      // Draw elongated grain
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: grainSize,
        height: grainSize * 2.5,
      );
      canvas.drawOval(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_WheatFieldPainter oldDelegate) =>
      oldDelegate.windProgress != windProgress;
}

/// Custom painter that draws mountain silhouettes against the sunset
class _MountainSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Back mountain layer (lighter, more distant)
    _drawMountainRange(
      canvas, size,
      color: const Color(0xFF1A1A2E).withOpacity(0.7),
      heightFactor: 0.6,
      peakPositions: [0.1, 0.35, 0.6, 0.85],
      peakHeights: [0.5, 0.8, 0.6, 0.4],
    );

    // Front mountain layer (darker, closer)
    _drawMountainRange(
      canvas, size,
      color: const Color(0xFF0F0F1A).withOpacity(0.9),
      heightFactor: 0.4,
      peakPositions: [0.0, 0.25, 0.5, 0.75, 1.0],
      peakHeights: [0.3, 0.6, 0.45, 0.7, 0.35],
    );
  }

  void _drawMountainRange(
    Canvas canvas,
    Size size, {
    required Color color,
    required double heightFactor,
    required List<double> peakPositions,
    required List<double> peakHeights,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (int i = 0; i < peakPositions.length; i++) {
      final peakX = size.width * peakPositions[i];
      final peakY = size.height * (1 - peakHeights[i] * heightFactor);
      
      if (i == 0) {
        path.lineTo(peakX, peakY);
      } else {
        // Create smooth peaks with quadratic curves
        final prevX = size.width * peakPositions[i - 1];
        final midX = (prevX + peakX) / 2;
        path.quadraticBezierTo(midX, size.height * 0.9, peakX, peakY);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A simpler, more subtle nature background for overlays
class SubtleNatureGlow extends StatelessWidget {
  final Widget child;
  
  const SubtleNatureGlow({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            ),
          ),
        ),
        
        // Subtle green glow in corner
        Positioned(
          bottom: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF22C55E).withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Subtle golden glow on other side
        Positioned(
          top: -50,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFBBF24).withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }
}
