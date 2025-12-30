// lib/widgets/control_button.dart
import 'package:flutter/material.dart';

class ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final String? subtitle;
  final Widget? badge;
  final Color? activeColor;
  final Color? inactiveColor;
  final double? size;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ControlButton({
    super.key,
    required this.label,
    required this.icon,
    this.isActive = false,
    this.isEnabled = true,
    this.onPressed,
    this.onLongPress,
    this.subtitle,
    this.badge,
    this.activeColor,
    this.inactiveColor,
    this.size,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = size ?? 80.0;
    final effectiveActiveColor = activeColor ?? Colors.green;
    final effectiveInactiveColor = inactiveColor ?? Colors.grey.shade600;

    return Container(
      margin: margin ?? const EdgeInsets.all(4),
      child: Stack(
        children: [
          SizedBox(
            width: buttonSize,
            height: buttonSize + 20,
            child: Column(
              children: [
                Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    gradient:
                        isEnabled && isActive
                            ? LinearGradient(
                              colors: [
                                effectiveActiveColor,
                                effectiveActiveColor.withValues(alpha: 0.8),
                              ],
                            )
                            : null,
                    color:
                        isEnabled && isActive
                            ? null
                            : isEnabled
                            ? Colors.grey.shade800.withValues(alpha: 0.6)
                            : Colors.grey.shade800.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(buttonSize / 2),
                    border: Border.all(
                      color:
                          isEnabled && isActive
                              ? effectiveActiveColor.withValues(alpha: 0.6)
                              : isEnabled
                              ? Colors.grey.shade700.withValues(alpha: 0.5)
                              : Colors.grey.shade700.withValues(alpha: 0.3),
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow:
                        isEnabled && isActive
                            ? [
                              BoxShadow(
                                color: effectiveActiveColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 12,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ]
                            : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isEnabled ? onPressed : null,
                      onLongPress: isEnabled ? onLongPress : null,
                      borderRadius: BorderRadius.circular(buttonSize / 2),
                      child: Center(
                        child: Icon(
                          icon,
                          size: buttonSize * 0.4,
                          color:
                              isEnabled && isActive
                                  ? Colors.white
                                  : isEnabled
                                  ? Colors.grey.shade400
                                  : effectiveInactiveColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isEnabled ? Colors.white : effectiveInactiveColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (badge != null) Positioned(top: 0, right: 8, child: badge!),
        ],
      ),
    );
  }
}
