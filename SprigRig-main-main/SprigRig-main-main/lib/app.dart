// lib/app.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'; // Import for PointerDeviceKind

// Import screens - organized by function
import 'screens/setup/welcome_screen.dart';
import 'screens/setup/location_setup_screen.dart';
import 'screens/setup/grow_method_selection_screen.dart';
import 'screens/setup/zone_creation_screen.dart'; // Keeping old one for reference if needed, but we used ZoneSetupScreen
import 'screens/setup/zone_setup_screen.dart';
import 'screens/main/zone_router_screen.dart';
import 'screens/setup/zone_setup_screen.dart';

import 'screens/home/zone_control_screen.dart'; // Existing zone control screen

// Import services
import 'services/database_helper.dart';
import 'services/timer_manager.dart';
import 'services/hardware_service.dart';
import 'services/astral_service.dart';
import 'services/camera_service.dart';
import 'services/env_control_service.dart';
import 'services/interval_scheduler_service.dart';

/// Main application widget for SprigRig
class SprigRigApp extends StatefulWidget {
  const SprigRigApp({super.key});

  @override
  State<SprigRigApp> createState() => _SprigRigAppState();
}

class _SprigRigAppState extends State<SprigRigApp> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isInitialized = false;
  bool _isFirstRun = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// Initialize all required services
  Future<void> _initializeServices() async {
    try {
      // Initialize database first
      await _databaseHelper.database;

      // Check if setup is complete (system config exists)
      final systemConfig = await _databaseHelper.getSystemConfig();
      _isFirstRun = systemConfig == null;

      if (kDebugMode) {
        debugPrint('System configured: ${systemConfig != null}');
        debugPrint('First run: $_isFirstRun');
      }

      if (!_isFirstRun) {
        // System is configured - initialize all services
        try {
          await TimerManager.instance.initialize();
          await HardwareService.instance.initialize();
          
          // Initialize Environmental Control Service
          await EnvironmentalControlService.instance.initialize();
          
          // Only initialize astral service if location is configured
          final locationSettings = await _databaseHelper.getLocationSettings();
          if (locationSettings != null) {
            await AstralService.instance.initialize();
          } else {
            debugPrint('Warning: No location settings found - astral service not initialized');
          }

          // Initialize camera service
          await CameraService.instance.initialize();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Warning: Some services failed to initialize: $e');
          }
          // Don't fail completely if optional services fail
        }

        // Initialize Interval Scheduler Service (independent of other services)
        try {
          await IntervalSchedulerService().initialize();
        } catch (e) {
          debugPrint('IntervalSchedulerService failed: $e');
        }
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Critical error during initialization: $e');
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'Error initializing app: $e';
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: CustomScrollBehavior(), // Apply custom scroll behavior
      title: 'SprigRig',
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          elevation: 2,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      
      // Home route - show appropriate screen based on initialization state
      home: !_isInitialized
          ? const _LoadingScreen()
          : _errorMessage.isNotEmpty
              ? _ErrorScreen(message: _errorMessage)
              : _isFirstRun
                  ? const WelcomeScreen()
                  : const ZoneRouterScreen(), // Smart routing based on zones

      // Define clean routes for the new zone-first architecture
      routes: {
        // Main app routes (zone-focused)
        '/home': (context) => const ZoneRouterScreen(),
        '/zones/selection': (context) => const ZoneSetupScreen(),
        
        // Zone control routes (will be dynamic later)
        '/zones': (context) => const ZoneControlScreen(), // Legacy compatibility
        
        // Setup flow routes (clean, step-by-step)
        '/setup/welcome': (context) => const WelcomeScreen(),
        '/setup/location': (context) => const LocationSetupScreen(),
        '/setup/grow-method': (context) => const GrowMethodSelectionScreen(),
        '/setup/zone-creation': (context) => const ZoneSetupScreen(),
      },

      // Handle unknown routes gracefully
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Page Not Found'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Route "${settings.name}" not found',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                      icon: const Icon(Icons.home),
                      label: const Text('Return to Home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },

      // Global error handling
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}

/// Loading screen shown during initialization
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // slate-900
              Color(0xFF1E3A8A), // blue-900
              Color(0xFF1E293B), // slate-800
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco, size: 80, color: Colors.green),
              SizedBox(height: 24),
              Text(
                'SprigRig',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 16),
              Text(
                'Initializing intelligent growing system...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error screen shown when initialization fails - featuring SprigRig branding
class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Beautiful gradient background with nature tones
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F172A), // Deep night sky
                  Color(0xFF1E3A5F), // Twilight blue
                  Color(0xFF1A3330), // Forest green hint
                  Color(0xFF0F172A), // Back to dark
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          
          // Subtle sun glow at top
          Positioned(
            top: -50,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 1.0,
                  colors: [
                    const Color(0xFFFBBF24).withOpacity(0.08),
                    const Color(0xFFF59E0B).withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SprigRig Logo (the sprout with sunlight)
                  // Using custom painted logo
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CustomPaint(
                      painter: _SprigRigErrorLogoPainter(),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // SprigRig title with gradient
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF4ADE80), Color(0xFFFBBF24)],
                    ).createShader(bounds),
                    child: const Text(
                      'SprigRig',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 1,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Error message card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber.shade400,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Retry button with glow
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/');
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple painted logo for error screen (lightweight version)
class _SprigRigErrorLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 150;

    // Sun glow
    final sunCenter = Offset(center.dx, center.dy - 25 * scale);
    final sunGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFBBF24).withOpacity(0.4),
          const Color(0xFFF59E0B).withOpacity(0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 50 * scale));
    canvas.drawCircle(sunCenter, 50 * scale, sunGlow);

    // Sun rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.25)
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      final angle = (i - 2) * 0.25 + 3.14159 / 2;
      final start = Offset(
        sunCenter.dx + 20 * scale * cos(angle),
        sunCenter.dy + 20 * scale * sin(angle),
      );
      final end = Offset(
        sunCenter.dx + 50 * scale * cos(angle),
        sunCenter.dy + 50 * scale * sin(angle),
      );
      canvas.drawLine(start, end, rayPaint);
    }

    // Soil
    final soilPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
      ).createShader(Rect.fromLTWH(0, center.dy + 30 * scale, size.width, 40 * scale));
    
    final soilPath = Path();
    soilPath.moveTo(center.dx - 50 * scale, center.dy + 35 * scale);
    soilPath.quadraticBezierTo(center.dx, center.dy + 28 * scale, center.dx + 50 * scale, center.dy + 35 * scale);
    soilPath.lineTo(center.dx + 50 * scale, size.height);
    soilPath.lineTo(center.dx - 50 * scale, size.height);
    soilPath.close();
    canvas.drawPath(soilPath, soilPaint);

    // Sprout stem
    final stemPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xFF15803D), Color(0xFF22C55E), Color(0xFF4ADE80)],
      ).createShader(Rect.fromLTWH(center.dx - 5, center.dy - 20 * scale, 10, 60 * scale))
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stemPath = Path();
    stemPath.moveTo(center.dx, center.dy + 30 * scale);
    stemPath.quadraticBezierTo(center.dx - 2 * scale, center.dy, center.dx + 3 * scale, center.dy - 15 * scale);
    canvas.drawPath(stemPath, stemPaint);

    // Leaves with chlorophyll glow
    _drawLeaf(canvas, Offset(center.dx + 2 * scale, center.dy - 10 * scale), -0.5, 25 * scale, 12 * scale, scale);
    _drawLeaf(canvas, Offset(center.dx + 2 * scale, center.dy - 10 * scale), 0.4, 28 * scale, 14 * scale, scale);
    _drawLeaf(canvas, Offset(center.dx + 3 * scale, center.dy - 18 * scale), 0.1, 12 * scale, 6 * scale, scale);
  }

  void _drawLeaf(Canvas canvas, Offset base, double angle, double length, double width, double scale) {
    final tipX = base.dx + length * cos(angle - 3.14159 / 2);
    final tipY = base.dy + length * sin(angle - 3.14159 / 2);
    final tip = Offset(tipX, tipY);
    final mid = Offset((base.dx + tip.dx) / 2, (base.dy + tip.dy) / 2);

    final ctrl1 = Offset(mid.dx + width * cos(angle), mid.dy + width * sin(angle));
    final ctrl2 = Offset(mid.dx - width * cos(angle), mid.dy - width * sin(angle));

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF4ADE80).withOpacity(0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scale);

    final leafPath = Path();
    leafPath.moveTo(base.dx, base.dy);
    leafPath.quadraticBezierTo(ctrl1.dx, ctrl1.dy, tip.dx, tip.dy);
    leafPath.quadraticBezierTo(ctrl2.dx, ctrl2.dy, base.dx, base.dy);
    leafPath.close();

    canvas.drawPath(leafPath, glowPaint);

    // Fill
    final leafPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [const Color(0xFF15803D), const Color(0xFF22C55E), const Color(0xFF86EFAC)],
      ).createShader(Rect.fromPoints(base, tip));

    canvas.drawPath(leafPath, leafPaint);
  }

  double cos(double angle) => math.cos(angle);
  double sin(double angle) => math.sin(angle);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom ScrollBehavior to enable drag scrolling on desktop/web
class CustomScrollBehavior extends MaterialScrollBehavior {
  const CustomScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}