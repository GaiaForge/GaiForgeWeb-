// lib/widgets/common/base_card.dart
import 'package:flutter/material.dart';

/// Base card component for consistent card styling throughout the app
class BaseCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isActive;
  final bool isDisabled;
  final double? elevation;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double? width;
  final double? height;

  const BaseCard({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.actions,
    this.padding,
    this.margin,
    this.onTap,
    this.isSelected = false,
    this.isActive = false,
    this.isDisabled = false,
    this.elevation,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: _getBorderColor(),
          width: isSelected || isActive ? 2 : 1,
        ),
        boxShadow: _getBoxShadow(),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                if (title != null || titleWidget != null || actions != null)
                  _buildHeader(),

                // Content
                if (title != null || titleWidget != null || actions != null)
                  const SizedBox(height: 12),

                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Title section
        Expanded(
          child: titleWidget ??
              (title != null
                  ? Text(
                      title!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDisabled ? Colors.grey.shade600 : Colors.white,
                      ),
                    )
                  : const SizedBox.shrink()),
        ),

        // Actions section
        if (actions != null && actions!.isNotEmpty) ...[
          const SizedBox(width: 8),
          Row(mainAxisSize: MainAxisSize.min, children: actions!),
        ],
      ],
    );
  }

  Color _getBackgroundColor() {
    if (backgroundColor != null) return backgroundColor!;
    
    if (isDisabled) {
      return Colors.grey.shade800.withValues(alpha:0.3);
    } else if (isSelected) {
      return Colors.green.withValues(alpha:0.1);
    } else if (isActive) {
      return Colors.blue.withValues(alpha:0.1);
    }
    
    return Colors.grey.shade800.withValues(alpha:0.6);
  }

  Color _getBorderColor() {
    if (borderColor != null) return borderColor!;
    
    if (isDisabled) {
      return Colors.grey.shade700.withValues(alpha:0.3);
    } else if (isSelected) {
      return Colors.green;
    } else if (isActive) {
      return Colors.blue;
    }
    
    return Colors.grey.shade700.withValues(alpha:0.5);
  }

  List<BoxShadow> _getBoxShadow() {
    if (isDisabled) return [];
    
    if (isSelected || isActive) {
      return [
        BoxShadow(
          color: (isSelected ? Colors.green : Colors.blue).withValues(alpha:0.3),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];
    }
    
    if (elevation != null && elevation! > 0) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha:0.1),
          blurRadius: elevation!,
          offset: Offset(0, elevation! / 2),
        ),
      ];
    }
    
    return [];
  }
}

/// Info card with icon and content
class InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? content;
  final IconData? icon;
  final Color? iconColor;
  final List<Widget>? actions;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const InfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.content,
    this.icon,
    this.iconColor,
    this.actions,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: onTap,
      margin: margin,
      child: Row(
        children: [
          // Icon section
          if (icon != null) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor ?? Colors.blue,
                    (iconColor ?? Colors.blue).withValues(alpha:0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
          ],

          // Content section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
                if (content != null) ...[const SizedBox(height: 8), content!],
              ],
            ),
          ),

          // Actions section
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Column(mainAxisSize: MainAxisSize.min, children: actions!),
          ],
        ],
      ),
    );
  }
}

/// Status card with colored status indicator
class StatusCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  final Widget? content;
  final IconData? statusIcon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const StatusCard({
    super.key,
    required this.title,
    required this.status,
    required this.statusColor,
    this.content,
    this.statusIcon,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: onTap,
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha:0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (statusIcon != null) ...[
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Content
          if (content != null) ...[const SizedBox(height: 12), content!],
        ],
      ),
    );
  }
}

/// Metric card for displaying values with units
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final Color? color;
  final String? subtitle;
  final Widget? trend;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.color,
    this.subtitle,
    this.trend,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Colors.blue;
    
    return BaseCard(
      onTap: onTap,
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                ),
              ),
              if (icon != null)
                Icon(icon, color: cardColor, size: 20),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Value and unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ],
          ),
          
          // Subtitle or trend
          if (subtitle != null || trend != null) ...[
            const SizedBox(height: 4),
            trend ?? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}