import 'package:flutter/material.dart';
import '../../widgets/common/app_background.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _secondaryPulseController; // For interference pattern
  late AnimationController _flickerController;
  late Animation<double> _flickerAnimation;

  @override
  void initState() {
    super.initState();

    // Very slow, majestic rotation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // Primary breathing (Deep, slow)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Secondary breathing (Slightly faster to create interference/variation)
    _secondaryPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Flame Flicker (Erratic)
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Slower base flicker
    )..repeat(reverse: true);
    
    _flickerAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _flickerController,
        // BounceInOut creates a nice "wavering" flame effect
        curve: Curves.bounceInOut, 
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _secondaryPulseController.dispose();
    _flickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo Placeholder with Golden Ring
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _rotationController, 
                    _pulseController, 
                    _secondaryPulseController,
                    _flickerController
                  ]),
                  builder: (context, child) {
                    // Complex organic wave patterns
                    final pulse1 = Curves.easeInOutSine.transform(_pulseController.value);
                    final pulse2 = Curves.easeInOutQuad.transform(_secondaryPulseController.value);
                    
                    // Combine pulses for "varying pattern"
                    final combinedPulse = (pulse1 + pulse2) / 2;
                    final flicker = _flickerAnimation.value;
                    
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * 3.14159,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // Golden Ring Gradient
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFD700), // Gold
                              Color(0xFFFFA000), // Amber
                              Color(0xFFFFECB3), // Light Gold
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            // Layer 1: Core Sun Glow (Intense, pulsing)
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.6 * flicker),
                              blurRadius: 40 + (30 * pulse1), 
                              spreadRadius: 10 + (15 * pulse1),
                            ),
                            // Layer 2: Middle Morphing Halo (Interference pattern)
                            BoxShadow(
                              color: const Color(0xFFFFA000).withOpacity(0.4 * flicker),
                              blurRadius: 60 + (40 * combinedPulse),
                              spreadRadius: 20 + (25 * combinedPulse),
                            ),
                            // Layer 3: Outer Radiating Aura (Wide reach)
                            BoxShadow(
                              color: const Color(0xFFFFECB3).withOpacity(0.2 * flicker),
                              blurRadius: 100 + (60 * pulse2), // Radiates much further
                              spreadRadius: 40 + (30 * pulse2),
                            ),
                            // Inner Depth
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Transform.rotate(
                          // Counter-rotate the inner content so the icon stays upright
                          angle: -_rotationController.value * 2 * 3.14159,
                          child: Container(
                            margin: const EdgeInsets.all(4), // Ring thickness
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1A1A1A), // Dark background inside ring
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 100,
                                height: 100,
                                child: CustomPaint(
                                  painter: _RealisticLeafPainter(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                
                // Title
                const Text(
                  'SprigRig',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Subtitle
                Text(
                  'Advanced Grow Control',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 60),
                
                // Action Button - Forged Tool Style
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      // Outer Glow (Heat)
                      BoxShadow(
                        color: const Color(0xFFD97706).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                      // Drop Shadow
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/setup/zone-creation');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, // Transparent for gradient
                      shadowColor: Colors.transparent, // Handled by Container
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                          color: const Color(0xFFD97706).withOpacity(0.5), // Amber border
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF374151), // Grey 700
                            Color(0xFF111827), // Grey 900
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'GET STARTED',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Color(0xFFF3F4F6), // Grey 100
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Color(0xFFD97706), // Amber accent
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RealisticLeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final path = Path();

    // Leaf Shape (Teardrop/Organic)
    path.moveTo(size.width * 0.5, size.height * 0.1); // Top tip
    path.quadraticBezierTo(
      size.width * 0.9, size.height * 0.3, // Control point 1
      size.width * 0.5, size.height * 0.9 // Bottom tip
    );
    path.quadraticBezierTo(
      size.width * 0.1, size.height * 0.3, // Control point 2
      size.width * 0.5, size.height * 0.1 // Back to top
    );
    path.close();

    // Leaf Gradient (Realistic Green)
    paint.shader = const LinearGradient(
      colors: [
        Color(0xFF66BB6A), // Light Green
        Color(0xFF2E7D32), // Dark Green
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(path, paint);

    // Leaf Veins (Subtle)
    final veinPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final veinPath = Path();
    veinPath.moveTo(size.width * 0.5, size.height * 0.15);
    veinPath.lineTo(size.width * 0.5, size.height * 0.85);
    canvas.drawPath(veinPath, veinPaint);

    // Water Drop
    final dropPath = Path();
    // Position drop on the leaf
    final dropRect = Rect.fromCenter(
      center: Offset(size.width * 0.65, size.height * 0.55),
      width: 20,
      height: 25,
    );
    dropPath.addOval(dropRect);

    // Drop Gradient (Blue/Transparent)
    final dropPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Colors.white, // Highlight
          Color(0xFF4FC3F7), // Light Blue
          Color(0xFF0288D1), // Dark Blue
        ],
        stops: [0.1, 0.5, 1.0],
        center: Alignment(-0.3, -0.3), // Light source reflection
        radius: 0.8,
      ).createShader(dropRect);

    // Drop Shadow for depth
    canvas.drawShadow(dropPath, Colors.black.withOpacity(0.3), 4, true);
    
    canvas.drawPath(dropPath, dropPaint);

    // Specular Highlight on Drop (Crisp white dot)
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.9);
    canvas.drawCircle(
      Offset(size.width * 0.65 - 3, size.height * 0.55 - 5), 
      3, 
      highlightPaint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
