import 'package:flutter/material.dart';
import 'dart:math' as math;

class GaiaSensorEye extends StatefulWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isActive;
  final double size;
  
  // New fields for Setpoint/Range display
  final double? setpoint;
  final double? min;
  final double? max;
  final bool showSetpoint;
  final bool showRange;

  const GaiaSensorEye({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.isActive = true,
    this.size = 160,
    this.setpoint,
    this.min,
    this.max,
    this.showSetpoint = false,
    this.showRange = false,
  });

  @override
  State<GaiaSensorEye> createState() => _GaiaSensorEyeState();
}

class _GaiaSensorEyeState extends State<GaiaSensorEye> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(widget.isActive ? 0.2 + (_controller.value * 0.2) : 0.05),
                      blurRadius: 20 + (_controller.value * 10),
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),

          // Main Lens Body with Lensing Effect
          Container(
            width: widget.size * 0.9,
            height: widget.size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.grey.shade900,
                  Colors.black,
                ],
                stops: const [0.2, 1.0], // Adjusted for depth
              ),
              border: Border.all(
                color: widget.color.withOpacity(widget.isActive ? 0.5 : 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
                // Inner glow for depth
                BoxShadow(
                  color: widget.color.withOpacity(widget.isActive ? 0.1 : 0.0),
                  blurRadius: 20,
                  spreadRadius: -10,
                ),
              ],
            ),
          ),

          // Lensing Overlay (Glass reflection)
          Container(
            width: widget.size * 0.9,
            height: widget.size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                ],
                stops: const [0.0, 0.4, 0.6, 1.0],
              ),
            ),
          ),

          // Inner "Iris" Gradient
          Container(
            width: widget.size * 0.85,
            height: widget.size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withOpacity(widget.isActive ? 0.2 : 0.05),
                  Colors.transparent,
                ],
                center: Alignment.center,
                radius: 0.8,
              ),
            ),
          ),

          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon moved up slightly
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Icon(
                  widget.icon,
                  color: widget.color.withOpacity(widget.isActive ? 0.9 : 0.4),
                  size: 28,
                ),
              ),
              
              // Value and Unit
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start, // Align unit to top
                children: [
                  Text(
                    widget.value,
                    style: TextStyle(
                      color: Colors.white.withOpacity(widget.isActive ? 1.0 : 0.6),
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                      shadows: widget.isActive ? [
                        Shadow(
                          color: widget.color.withOpacity(0.6),
                          blurRadius: 12,
                        ),
                      ] : null,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(top: 6), // Push unit down slightly
                    child: Text(
                      widget.unit,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Label
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  color: widget.color.withOpacity(widget.isActive ? 0.8 : 0.4),
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Setpoint / Range Display
              if (widget.showSetpoint && widget.setpoint != null)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.color.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    'SP: ${widget.setpoint}',
                    style: TextStyle(
                      color: widget.color.withOpacity(1.0),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              if (widget.showRange && widget.min != null && widget.max != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.min} - ${widget.max}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          // Decorative Rim Highlights (Enhanced Glass effect)
          Positioned(
            top: widget.size * 0.12,
            left: widget.size * 0.25,
            child: Container(
              width: widget.size * 0.2,
              height: widget.size * 0.1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.all(Radius.elliptical(widget.size * 0.2, widget.size * 0.1)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
