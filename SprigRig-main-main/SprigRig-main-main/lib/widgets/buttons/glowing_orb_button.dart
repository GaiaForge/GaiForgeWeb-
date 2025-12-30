import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A stunning glowing orb button that looks ethereal and inviting.
/// Perfect for important call-to-action buttons that should feel magical.
class GlowingOrbButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final double size;

  const GlowingOrbButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add,
    this.size = 120,
  });

  @override
  State<GlowingOrbButton> createState() => _GlowingOrbButtonState();
}

class _GlowingOrbButtonState extends State<GlowingOrbButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Pulsating glow animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Floating/levitating animation
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Slow rotation for particle effect
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _floatAnimation, _rotateController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              widget.onPressed();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedScale(
              scale: _isPressed ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The orb with glow layers
                  SizedBox(
                    width: widget.size * 1.8,
                    height: widget.size * 1.8,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring - rotating particles (darker green)
                        Transform.rotate(
                          angle: _rotateController.value * 2 * math.pi,
                          child: CustomPaint(
                            size: Size(widget.size * 1.6, widget.size * 1.6),
                            painter: _ParticleRingPainter(
                              progress: _rotateController.value,
                              opacity: _pulseAnimation.value * 0.4,
                            ),
                          ),
                        ),
                        
                        // Outer glow layer 3 (largest, most diffuse - forest green)
                        Container(
                          width: widget.size * 1.5,
                          height: widget.size * 1.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF166534).withOpacity(0.2 * _pulseAnimation.value),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),

                        // Outer glow layer 2 (dark emerald)
                        Container(
                          width: widget.size * 1.3,
                          height: widget.size * 1.3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF15803D).withOpacity(0.25 * _pulseAnimation.value),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),

                        // Outer glow layer 1 (subtle amber accent)
                        Container(
                          width: widget.size * 1.15,
                          height: widget.size * 1.15,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF78350F).withOpacity(0.12 * _pulseAnimation.value),
                                blurRadius: 25,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),

                        // Main orb body - organic seed pod with translucent layers
                        Container(
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Multi-layer gradient for organic depth
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF4D7C0F).withOpacity(0.7),  // Lime-green center (translucent)
                                const Color(0xFF3F6212).withOpacity(0.75), // Olive green
                                const Color(0xFF365314).withOpacity(0.8),  // Dark lime
                                const Color(0xFF1A2E05).withOpacity(0.85), // Deep forest
                                const Color(0xFF14532D).withOpacity(0.9),  // Darkest edge
                              ],
                              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                              center: const Alignment(-0.2, -0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF166534).withOpacity(0.4 * _pulseAnimation.value),
                                blurRadius: 25,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: const Color(0xFF0F0F0F).withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Organic texture overlay - subtle veins
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: const Alignment(-1, -1),
                                    end: const Alignment(1, 1),
                                    colors: [
                                      Colors.white.withOpacity(0.08),
                                      Colors.transparent,
                                      const Color(0xFF1A2E05).withOpacity(0.15),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                              // Inner highlight (top-left shine - subtle)
                              Positioned(
                                top: widget.size * 0.12,
                                left: widget.size * 0.18,
                                child: Container(
                                  width: widget.size * 0.28,
                                  height: widget.size * 0.12,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.35),
                                        Colors.white.withOpacity(0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),
                              // Secondary highlight for depth
                              Positioned(
                                top: widget.size * 0.25,
                                left: widget.size * 0.25,
                                child: Container(
                                  width: widget.size * 0.15,
                                  height: widget.size * 0.08,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF84CC16).withOpacity(0.2),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                              ),
                              // Icon in center (seed symbol)
                              Center(
                                child: Icon(
                                  widget.icon,
                                  size: widget.size * 0.35,
                                  color: const Color(0xFFA3E635).withOpacity(0.85),
                                  shadows: [
                                    Shadow(
                                      color: const Color(0xFF0F0F0F).withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Label with subtle glow
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF166534).withOpacity(0.5 * _pulseAnimation.value),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for the rotating particle ring around the orb
class _ParticleRingPainter extends CustomPainter {
  final double progress;
  final double opacity;

  _ParticleRingPainter({required this.progress, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw glowing particles around the ring (organic darker green)
    const particleCount = 10;
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final particleRadius = 2.5 + (math.sin(progress * 2 * math.pi + i) * 1.2);
      
      final x = center.dx + radius * 0.85 * math.cos(angle);
      final y = center.dy + radius * 0.85 * math.sin(angle);

      // Particle glow (dark emerald)
      final glowPaint = Paint()
        ..color = const Color(0xFF166534).withOpacity(opacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(x, y), particleRadius + 3, glowPaint);

      // Particle core (muted lime green, translucent)
      final corePaint = Paint()
        ..color = const Color(0xFF84CC16).withOpacity(opacity * 0.7);
      canvas.drawCircle(Offset(x, y), particleRadius, corePaint);
    }
  }

  @override
  bool shouldRepaint(_ParticleRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.opacity != opacity;
}
