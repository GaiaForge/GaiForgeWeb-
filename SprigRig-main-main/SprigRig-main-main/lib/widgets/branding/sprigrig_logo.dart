import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A beautiful custom painted SprigRig logo featuring a sprout with 
/// sunlight rays shining through chlorophyll leaves.
class SprigRigLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const SprigRigLogo({
    super.key,
    this.size = 200,
    this.animate = true,
  });

  @override
  State<SprigRigLogo> createState() => _SprigRigLogoState();
}

class _SprigRigLogoState extends State<SprigRigLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _SprigRigLogoPainter(
            animationValue: widget.animate ? _controller.value : 0.5,
          ),
        );
      },
    );
  }
}

class _SprigRigLogoPainter extends CustomPainter {
  final double animationValue;

  _SprigRigLogoPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 200; // Base design on 200x200

    // Draw background glow/sun
    _drawSunGlow(canvas, center, scale);

    // Draw sun rays
    _drawSunRays(canvas, center, scale);

    // Draw soil/ground
    _drawSoil(canvas, center, size, scale);

    // Draw sprout stem
    _drawSproutStem(canvas, center, scale);

    // Draw leaves with chlorophyll glow
    _drawLeaves(canvas, center, scale);
  }

  void _drawSunGlow(Canvas canvas, Offset center, double scale) {
    final sunCenter = Offset(center.dx, center.dy - 30 * scale);
    final glowOpacity = 0.2 + (animationValue * 0.15);

    // Outer glow
    final outerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFBBF24).withOpacity(glowOpacity),
          const Color(0xFFF59E0B).withOpacity(glowOpacity * 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 80 * scale));
    canvas.drawCircle(sunCenter, 80 * scale, outerGlow);

    // Inner sun core
    final sunCore = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFEF3C7).withOpacity(0.9),
          const Color(0xFFFBBF24).withOpacity(0.7),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 25 * scale));
    canvas.drawCircle(sunCenter, 25 * scale, sunCore);
  }

  void _drawSunRays(Canvas canvas, Offset center, double scale) {
    final sunCenter = Offset(center.dx, center.dy - 30 * scale);
    final rayOpacity = 0.15 + (animationValue * 0.1);

    final rayPaint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(rayOpacity)
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * scale);

    // Draw multiple rays emanating down and outward
    for (int i = 0; i < 7; i++) {
      final angle = (i - 3) * 0.2 + math.pi / 2; // Fan out from top
      final startOffset = 30 * scale;
      final endOffset = 70 * scale + (animationValue * 10 * scale);

      final start = Offset(
        sunCenter.dx + startOffset * math.cos(angle),
        sunCenter.dy + startOffset * math.sin(angle),
      );
      final end = Offset(
        sunCenter.dx + endOffset * math.cos(angle),
        sunCenter.dy + endOffset * math.sin(angle),
      );

      canvas.drawLine(start, end, rayPaint);
    }
  }

  void _drawSoil(Canvas canvas, Offset center, Size size, double scale) {
    final soilTop = center.dy + 40 * scale;
    
    // Soil gradient
    final soilPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF5D4037),
          const Color(0xFF3E2723),
        ],
      ).createShader(Rect.fromLTWH(0, soilTop, size.width, size.height - soilTop));

    // Draw curved soil surface
    final soilPath = Path();
    soilPath.moveTo(0, soilTop + 10 * scale);
    soilPath.quadraticBezierTo(
      center.dx, soilTop - 5 * scale,
      size.width, soilTop + 10 * scale,
    );
    soilPath.lineTo(size.width, size.height);
    soilPath.lineTo(0, size.height);
    soilPath.close();

    canvas.drawPath(soilPath, soilPaint);

    // Add soil highlight
    final highlightPaint = Paint()
      ..color = const Color(0xFF8D6E63).withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * scale);
    
    final highlightPath = Path();
    highlightPath.moveTo(center.dx - 30 * scale, soilTop + 5 * scale);
    highlightPath.quadraticBezierTo(
      center.dx, soilTop - 8 * scale,
      center.dx + 30 * scale, soilTop + 5 * scale,
    );
    canvas.drawPath(highlightPath, highlightPaint);
  }

  void _drawSproutStem(Canvas canvas, Offset center, double scale) {
    final stemBase = Offset(center.dx, center.dy + 35 * scale);
    final stemTop = Offset(center.dx + 5 * scale, center.dy - 10 * scale);

    // Stem shadow/glow
    final stemGlow = Paint()
      ..color = const Color(0xFF22C55E).withOpacity(0.3)
      ..strokeWidth = 8 * scale
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale);

    final stemPath = Path();
    stemPath.moveTo(stemBase.dx, stemBase.dy);
    stemPath.quadraticBezierTo(
      center.dx - 3 * scale, center.dy + 10 * scale,
      stemTop.dx, stemTop.dy,
    );
    canvas.drawPath(stemPath, stemGlow);

    // Main stem
    final stemPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF15803D),
          const Color(0xFF22C55E),
          const Color(0xFF4ADE80),
        ],
      ).createShader(Rect.fromPoints(stemBase, stemTop))
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(stemPath, stemPaint);
  }

  void _drawLeaves(Canvas canvas, Offset center, double scale) {
    final leafBase = Offset(center.dx + 3 * scale, center.dy - 5 * scale);
    final chlorophyllGlow = 0.3 + (animationValue * 0.2);

    // Left leaf
    _drawLeaf(
      canvas,
      leafBase,
      -0.6, // angle
      30 * scale, // length
      15 * scale, // width
      scale,
      chlorophyllGlow,
    );

    // Right leaf
    _drawLeaf(
      canvas,
      leafBase,
      0.4, // angle
      35 * scale, // length
      18 * scale, // width
      scale,
      chlorophyllGlow,
    );

    // Small emerging leaf at top
    _drawLeaf(
      canvas,
      Offset(leafBase.dx + 2 * scale, leafBase.dy - 8 * scale),
      0.1,
      15 * scale,
      8 * scale,
      scale,
      chlorophyllGlow * 1.2,
    );
  }

  void _drawLeaf(
    Canvas canvas,
    Offset base,
    double angle,
    double length,
    double width,
    double scale,
    double glowIntensity,
  ) {
    final tipX = base.dx + length * math.cos(angle - math.pi / 2);
    final tipY = base.dy + length * math.sin(angle - math.pi / 2);
    final tip = Offset(tipX, tipY);

    // Calculate control points for leaf curve
    final midPoint = Offset((base.dx + tip.dx) / 2, (base.dy + tip.dy) / 2);
    final perpAngle = angle;
    final ctrl1 = Offset(
      midPoint.dx + width * math.cos(perpAngle),
      midPoint.dy + width * math.sin(perpAngle),
    );
    final ctrl2 = Offset(
      midPoint.dx - width * math.cos(perpAngle),
      midPoint.dy - width * math.sin(perpAngle),
    );

    // Chlorophyll glow effect
    final glowPaint = Paint()
      ..color = const Color(0xFF4ADE80).withOpacity(glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale);

    final leafPath = Path();
    leafPath.moveTo(base.dx, base.dy);
    leafPath.quadraticBezierTo(ctrl1.dx, ctrl1.dy, tip.dx, tip.dy);
    leafPath.quadraticBezierTo(ctrl2.dx, ctrl2.dy, base.dx, base.dy);
    leafPath.close();

    canvas.drawPath(leafPath, glowPaint);

    // Main leaf fill with gradient
    final leafPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF15803D),
          const Color(0xFF22C55E),
          const Color(0xFF86EFAC),
        ],
      ).createShader(Rect.fromPoints(base, tip));

    canvas.drawPath(leafPath, leafPaint);

    // Leaf vein
    final veinPaint = Paint()
      ..color = const Color(0xFF166534).withOpacity(0.4)
      ..strokeWidth = 1 * scale
      ..style = PaintingStyle.stroke;

    final veinPath = Path();
    veinPath.moveTo(base.dx, base.dy);
    veinPath.lineTo(tip.dx, tip.dy);
    canvas.drawPath(veinPath, veinPaint);

    // Sun ray through leaf (translucent highlight)
    final sunHighlight = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-1, -1),
        end: const Alignment(1, 1),
        colors: [
          const Color(0xFFFBBF24).withOpacity(0.2 * glowIntensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromPoints(base, tip));

    canvas.drawPath(leafPath, sunHighlight);
  }

  @override
  bool shouldRepaint(_SprigRigLogoPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
