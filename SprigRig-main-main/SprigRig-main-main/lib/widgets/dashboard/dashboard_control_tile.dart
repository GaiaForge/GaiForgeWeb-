import 'dart:ui';
import 'package:flutter/material.dart';

class DashboardControlTile extends StatefulWidget {
  final Widget statusIcon;          // Existing animated icon
  final String title;               // "Lighting", "Irrigation", etc.
  final bool isActive;              // Current on/off state
  final Color activeColor;          // Theme color when active
  final VoidCallback? onToggle;      // Toggle callback
  final VoidCallback onTap;         // Navigate to settings
  final Widget content;             // Flexible content area
  final Widget? actionButton;       // Optional "Run Now" button
  final String? statusText;         // "Astral Mode", "2/4 cycles", etc.

  const DashboardControlTile({
    super.key,
    required this.statusIcon,
    required this.title,
    required this.isActive,
    required this.activeColor,
    this.onToggle,
    required this.onTap,
    required this.content,
    this.actionButton,
    this.statusText,
  });

  @override
  State<DashboardControlTile> createState() => _DashboardControlTileState();
}

class _DashboardControlTileState extends State<DashboardControlTile> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _scaleController.forward(),
      onExit: (_) => _scaleController.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) => _scaleController.reverse(),
        onTapCancel: () => _scaleController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isActive 
                      ? widget.activeColor.withOpacity(0.1) 
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(widget.isActive ? 0.2 : 0.1),
                  ),
                  boxShadow: widget.isActive ? [
                    BoxShadow(
                      color: widget.activeColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 0,
                    )
                  ] : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        widget.statusIcon,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (widget.statusText != null)
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: widget.isActive ? widget.activeColor : Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.statusText!,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        // Custom Toggle would go here, passing callback
                        // For now using a placeholder or we can implement StatusToggle next and use it here if we import it.
                        // But the design says "Toggle" is part of header.
                        // The user provided StatusToggle code separately. 
                        // I will assume the parent passes the toggle or I should use StatusToggle here.
                        // The snippet shows `[Toggle]` in the header.
                        // I'll implement StatusToggle separately and the user can use it in the parent or I can import it here.
                        // Given the snippet structure, it seems generic.
                        // I'll add a placeholder for the toggle action which is `onToggle`.
                        if (widget.onToggle != null)
                          GestureDetector(
                            onTap: widget.onToggle,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 48,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: widget.isActive ? widget.activeColor : Colors.grey.shade700,
                              ),
                              child: Stack(
                                children: [
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutBack,
                                    left: widget.isActive ? 22 : 2,
                                    top: 2,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Content
                    widget.content,
                    
                    // Actions
                    if (widget.actionButton != null) ...[
                      const SizedBox(height: 12),
                      widget.actionButton!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
