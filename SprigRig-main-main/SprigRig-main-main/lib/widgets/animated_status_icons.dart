import 'package:flutter/material.dart';
import 'dart:math' as math;

// -----------------------------------------------------------------------------
// Fan Status Icon (Rotation + Wind)
// -----------------------------------------------------------------------------
class FanStatusIcon extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double size;

  const FanStatusIcon({
    super.key,
    required this.isActive,
    required this.color,
    this.size = 24,
  });

  @override
  State<FanStatusIcon> createState() => _FanStatusIconState();
}

class _FanStatusIconState extends State<FanStatusIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(FanStatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Wind Simulation (Behind)
        if (widget.isActive)
          Positioned.fill(
            child: CustomPaint(
              painter: _WindPainter(color: widget.color.withOpacity(0.3), animation: _controller),
            ),
          ),
        
        // Rotating Fan
        RotationTransition(
          turns: _controller,
          child: Icon(
            Icons.cyclone, // Use cyclone or fan icon
            color: widget.isActive ? widget.color : Colors.white38,
            size: widget.size,
          ),
        ),
      ],
    );
  }
}

class _WindPainter extends CustomPainter {
  final Color color;
  final Animation<double> animation;

  _WindPainter({required this.color, required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final random = math.Random(42); // Fixed seed for consistent "random" lines
    
    // Draw moving wind lines
    for (int i = 0; i < 5; i++) {
      final y = random.nextDouble() * size.height;
      final speed = 0.5 + random.nextDouble();
      final offset = (animation.value * speed * size.width * 2) % (size.width + 20) - 10;
      
      // Draw line segments
      canvas.drawLine(
        Offset(offset, y),
        Offset(offset + 10, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------
// Light Status Icon (Flickering Flame / Radiating Glow)
// -----------------------------------------------------------------------------
class LightStatusIcon extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double size;

  const LightStatusIcon({
    super.key,
    required this.isActive,
    required this.color,
    this.size = 24,
  });

  @override
  State<LightStatusIcon> createState() => _LightStatusIconState();
}

class _LightStatusIconState extends State<LightStatusIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(LightStatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
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
        // Random flicker effect combined with smooth pulse
        final flicker = widget.isActive ? (0.8 + 0.2 * math.sin(_controller.value * math.pi * 2) + (math.Random().nextDouble() * 0.1)) : 0.0;
        
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: widget.isActive ? [
              BoxShadow(
                color: widget.color.withOpacity(0.6 * flicker),
                blurRadius: 10 + (5 * flicker),
                spreadRadius: 2 + (2 * flicker),
              ),
              BoxShadow(
                color: Colors.orange.withOpacity(0.3 * flicker), // Warm core
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ] : null,
          ),
          child: Icon(
            Icons.lightbulb,
            color: widget.isActive ? widget.color.withOpacity(0.9 + (0.1 * flicker).clamp(0.0, 0.1)) : Colors.white38,
            size: widget.size,
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Irrigation Status Icon (Organic Water Droplet)
// -----------------------------------------------------------------------------
class IrrigationStatusIcon extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double size;

  const IrrigationStatusIcon({
    super.key,
    required this.isActive,
    required this.color,
    this.size = 24,
  });

  @override
  State<IrrigationStatusIcon> createState() => _IrrigationStatusIconState();
}

class _IrrigationStatusIconState extends State<IrrigationStatusIcon> with TickerProviderStateMixin {
  late AnimationController _wobbleController;
  late AnimationController _dripController;

  @override
  void initState() {
    super.initState();
    // Slow organic wobble
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    
    // Drip cycle
    _dripController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    if (widget.isActive) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _wobbleController.repeat(reverse: true);
    // Delay drip slightly to desync
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && widget.isActive) _dripController.repeat();
    });
  }

  void _stopAnimations() {
    _wobbleController.stop();
    _dripController.stop();
  }

  @override
  void didUpdateWidget(IrrigationStatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _dripController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size * 1.6, // Extra height for drip
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Static/Inactive State
          if (!widget.isActive)
            Padding(
              padding: EdgeInsets.only(top: widget.size * 0.1),
              child: Icon(
                Icons.water_drop,
                color: Colors.white38,
                size: widget.size,
              ),
            ),

          // Active Animated State
          if (widget.isActive)
            CustomPaint(
              size: Size(widget.size, widget.size * 1.6),
              painter: _WaterDropletPainter(
                color: widget.color,
                wobbleAnim: _wobbleController,
                dripAnim: _dripController,
              ),
            ),
        ],
      ),
    );
  }
}

class _WaterDropletPainter extends CustomPainter {
  final Color color;
  final Animation<double> wobbleAnim;
  final Animation<double> dripAnim;

  _WaterDropletPainter({
    required this.color,
    required this.wobbleAnim,
    required this.dripAnim,
  }) : super(repaint: Listenable.merge([wobbleAnim, dripAnim]));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.width; // Base droplet height
    final centerX = w / 2;
    final centerY = h / 2 + (h * 0.1);

    // --- 1. Organic Wobble Calculation ---
    final t = wobbleAnim.value;
    final wobbleX = math.sin(t * math.pi * 2) * (w * 0.05);
    final wobbleY = math.cos(t * math.pi * 2) * (h * 0.05);

    // --- 2. Drip Cycle Logic ---
    final d = dripAnim.value;
    double dripY = 0;
    double dripScale = 0;
    double mainBodyStretch = 0;
    double rippleRadius = 0;
    double rippleOpacity = 0;

    if (d < 0.45) {
      // Accumulate & Elongate: Bulge at bottom significantly
      // Use quadratic ease-in to make it stretch faster at the end of this phase
      final progress = d / 0.45;
      final curve = progress * progress; 
      mainBodyStretch = curve * (h * 0.6); // Increased stretch factor for elongation
    } else if (d < 0.6) {
      // Detach & Snap Back
      final progress = (d - 0.45) / 0.15;
      
      // Main body snaps back up elastically
      mainBodyStretch = (h * 0.6) * (1.0 - math.pow(progress, 0.5)); 
      
      // Drip starts near the tip of the max stretch and falls
      final startY = centerY + (h * 0.5) + (h * 0.5); 
      dripY = startY + (progress * (h * 0.6));
      dripScale = 1.0 - (progress * 0.1);
    } else if (d < 0.85) {
      // Fall & Splash
      final progress = (d - 0.6) / 0.25;
      final startY = centerY + (h * 0.5) + (h * 1.1);
      dripY = startY + (progress * (h * 0.8));
      dripScale = 0.9 - (progress * 0.9); // Shrink as it falls/splashes
      
      // Ripple starts
      rippleRadius = progress * w;
      rippleOpacity = 1.0 - progress;
    } else {
      // Rebound / Idle
      final progress = (d - 0.85) / 0.15;
      // Slight bounce of main body
      mainBodyStretch = math.sin(progress * math.pi) * -(h * 0.08);
    }

    // --- Define Gradient Paint ---
    final rect = Rect.fromLTWH(0, 0, w, size.height);
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.6), // Top-left highlight
      radius: 1.0,
      colors: [
        Colors.white.withOpacity(0.8),      // Bright highlight
        color.withOpacity(0.6),             // Transparent body
        color.withOpacity(0.9),             // Darker edge
      ],
      stops: const [0.0, 0.3, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    // --- 3. Draw Main Droplet ---
    final path = Path();
    path.moveTo(centerX, 0); // Top tip
    
    // Right curve
    path.cubicTo(
      centerX + (w * 0.5) + wobbleX, centerY - (h * 0.2), 
      centerX + (w * 0.5) - wobbleX, centerY + (h * 0.5) + mainBodyStretch, 
      centerX, centerY + (h * 0.5) + mainBodyStretch 
    );

    // Left curve
    path.cubicTo(
      centerX - (w * 0.5) - wobbleX, centerY + (h * 0.5) + mainBodyStretch, 
      centerX - (w * 0.5) + wobbleX, centerY - (h * 0.2), 
      centerX, 0 
    );
    path.close();

    canvas.drawPath(path, paint);

    // --- 4. Draw Detached Drip ---
    if (d >= 0.4 && d < 0.8) {
      // Use simpler paint for small drip to avoid complex gradient issues on small shapes
      final dripPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.fill;
        
      canvas.drawCircle(
        Offset(centerX, dripY),
        (w * 0.15) * dripScale,
        dripPaint,
      );
    }

    // --- 5. Draw Ripple ---
    if (rippleRadius > 0) {
      final ripplePaint = Paint()
        ..color = color.withOpacity(rippleOpacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, size.height - 5),
          width: rippleRadius * 1.5,
          height: rippleRadius * 0.5,
        ),
        ripplePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaterDropletPainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------
// Aeration Status Icon (Rising Bubbles)
// -----------------------------------------------------------------------------
class AerationStatusIcon extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double size;

  const AerationStatusIcon({
    super.key,
    required this.isActive,
    required this.color,
    this.size = 24,
  });

  @override
  State<AerationStatusIcon> createState() => _AerationStatusIconState();
}

class _AerationStatusIconState extends State<AerationStatusIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(AerationStatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Bubbles Animation
        if (widget.isActive)
          Positioned.fill(
            child: CustomPaint(
              painter: _BubblesPainter(color: widget.color.withOpacity(0.6), animation: _controller),
            ),
          ),
        
        // Base Icon
        Icon(
          Icons.bubble_chart,
          color: widget.isActive ? widget.color : Colors.white38,
          size: widget.size,
        ),
      ],
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final Color color;
  final Animation<double> animation;

  _BubblesPainter({required this.color, required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed
    
    // Draw multiple rising bubbles
    for (int i = 0; i < 6; i++) {
      final speed = 0.5 + random.nextDouble() * 0.5;
      final startX = random.nextDouble() * size.width;
      final bubbleSize = 2.0 + random.nextDouble() * 3.0;
      
      // Calculate position based on animation loop
      // Offset by random amount so they don't all start at bottom together
      final loopOffset = random.nextDouble(); 
      final progress = (animation.value * speed + loopOffset) % 1.0;
      
      final y = size.height - (progress * size.height);
      
      // Add sine wave wobble to X
      final wobble = math.sin(progress * math.pi * 4) * 3.0;
      final x = startX + wobble;
      
      // Fade out near top
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = color.withOpacity(opacity * 0.8);

      canvas.drawCircle(Offset(x, y), bubbleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------
// Seedling Mat Status Icon (Radiating Warmth)
// -----------------------------------------------------------------------------
class SeedlingMatStatusIcon extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double size;

  const SeedlingMatStatusIcon({
    super.key,
    required this.isActive,
    required this.color,
    this.size = 24,
  });

  @override
  State<SeedlingMatStatusIcon> createState() => _SeedlingMatStatusIconState();
}

class _SeedlingMatStatusIconState extends State<SeedlingMatStatusIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(SeedlingMatStatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Heat Waves Animation
        if (widget.isActive)
          Positioned.fill(
            child: CustomPaint(
              painter: _HeatWavesPainter(color: widget.color.withOpacity(0.6), animation: _controller),
            ),
          ),
        
        // Base Icon
        Icon(
          Icons.grid_on, // Mat-like icon
          color: widget.isActive ? widget.color : Colors.white38,
          size: widget.size,
        ),
      ],
    );
  }
}

class _HeatWavesPainter extends CustomPainter {
  final Color color;
  final Animation<double> animation;

  _HeatWavesPainter({required this.color, required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final random = math.Random(42); // Fixed seed
    
    // Draw multiple rising heat waves
    for (int i = 0; i < 3; i++) {
      final speed = 0.8 + random.nextDouble() * 0.4;
      final startX = (size.width * 0.2) + (random.nextDouble() * size.width * 0.6);
      
      // Calculate position based on animation loop
      final loopOffset = random.nextDouble(); 
      final progress = (animation.value * speed + loopOffset) % 1.0;
      
      final y = size.height - (progress * size.height * 0.8);
      
      // Draw a small wavy line segment
      final path = Path();
      final waveHeight = 10.0;
      final waveWidth = 4.0;
      
      path.moveTo(startX, y);
      path.quadraticBezierTo(
        startX + waveWidth, y - (waveHeight * 0.25), 
        startX, y - (waveHeight * 0.5)
      );
      path.quadraticBezierTo(
        startX - waveWidth, y - (waveHeight * 0.75), 
        startX, y - waveHeight
      );

      // Fade out near top
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = color.withOpacity(opacity * 0.8);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
