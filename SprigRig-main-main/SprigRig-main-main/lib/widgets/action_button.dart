// lib/widgets/action_button.dart
import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final bool isLoading;
  final bool isDisabled;
  final EdgeInsetsGeometry? padding;
  final double? width;

  const ActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.isLoading = false,
    this.isDisabled = false,
    this.padding,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = !isDisabled && !isLoading && onPressed != null;

    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          gradient: isEnabled ? _getGradient() : null,
          color: isEnabled ? null : Colors.grey.shade700,
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isEnabled && isPrimary
                  ? [
                    BoxShadow(
                      color: _getPrimaryColor().withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  padding ??
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getTextColor(),
                        ),
                      ),
                    ),
                    if (icon != null || label.isNotEmpty)
                      const SizedBox(width: 8),
                  ] else if (icon != null) ...[
                    Icon(icon, size: 18, color: _getTextColor()),
                    if (label.isNotEmpty) const SizedBox(width: 8),
                  ],
                  if (label.isNotEmpty)
                    Text(
                      label,
                      style: TextStyle(
                        color: _getTextColor(),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient? _getGradient() {
    if (isDestructive) {
      return const LinearGradient(colors: [Colors.red, Color(0xFFDC2626)]);
    } else if (isPrimary) {
      return const LinearGradient(colors: [Colors.green, Colors.teal]);
    } else {
      return LinearGradient(
        colors: [Colors.grey.shade600, Colors.grey.shade700],
      );
    }
  }

  Color _getPrimaryColor() {
    if (isDestructive) {
      return Colors.red;
    } else if (isPrimary) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  Color _getTextColor() {
    if (!isDisabled && !isLoading && onPressed != null) {
      return Colors.white;
    } else {
      return Colors.grey.shade400;
    }
  }
}
