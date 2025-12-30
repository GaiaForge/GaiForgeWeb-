import 'dart:math' as math;
import 'package:flutter/material.dart';

class ReservoirTankWidget extends StatefulWidget {
  final double levelPercent; // 0.0 to 1.0
  final double? targetPercent; // 0.0 to 1.0, optional
  final double height;
  final double width;
  final Color waterColor;
  final Color tankColor;

  const ReservoirTankWidget({
    super.key,
    required this.levelPercent,
    this.targetPercent,
    this.height = 200,
    this.width = 120,
    this.waterColor = Colors.blue,
    this.tankColor = Colors.white24,
  });

  @override
  State<ReservoirTankWidget> createState() => _ReservoirTankWidgetState();
}

class _ReservoirTankWidgetState extends State<ReservoirTankWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Tank Container
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white54, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: widget.tankColor,
            ),
          ),
          
          // Water Animation
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WaterPainter(
                    animationValue: _controller.value,
                    levelPercent: widget.levelPercent,
                    color: widget.waterColor,
                  ),
                  size: Size(widget.width, widget.height),
                );
              },
            ),
          ),

          // Target Level Line
          if (widget.targetPercent != null)
            Positioned(
              bottom: widget.height * widget.targetPercent!,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                color: Colors.greenAccent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.arrow_right, color: Colors.greenAccent, size: 16),
                    Expanded(child: Container(color: Colors.greenAccent.withOpacity(0.5), height: 1)),
                    const Icon(Icons.arrow_left, color: Colors.greenAccent, size: 16),
                  ],
                ),
              ),
            ),

          // Percentage Text
          Positioned(
            bottom: (widget.height * widget.levelPercent).clamp(20.0, widget.height - 30.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(widget.levelPercent * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double animationValue;
  final double levelPercent;
  final Color color;

  _WaterPainter({
    required this.animationValue,
    required this.levelPercent,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waterHeight = size.height * levelPercent;
    final baseHeight = size.height - waterHeight;

    path.moveTo(0, baseHeight);

    // Draw waves
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        baseHeight +
            math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * 5,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
    
    // Draw lighter top layer for depth
    final topPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;
      
    final topPath = Path();
    topPath.moveTo(0, baseHeight);
    for (double i = 0; i <= size.width; i++) {
      topPath.lineTo(
        i,
        baseHeight +
            math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi) + math.pi) * 5,
      );
    }
    topPath.lineTo(size.width, size.height);
    topPath.lineTo(0, size.height);
    topPath.close();
    
    canvas.drawPath(topPath, topPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.levelPercent != levelPercent;
  }
}
