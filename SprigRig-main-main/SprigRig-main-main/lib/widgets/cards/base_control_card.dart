// lib/widgets/cards/base_control_card.dart
import 'package:flutter/material.dart';
import '../common/base_card.dart';

/// Base class for all zone control cards
abstract class BaseControlCard extends StatelessWidget {
  final int zoneId;
  final String title;
  final IconData icon;
  final Color color;
  final bool isCompact;
  final VoidCallback? onTap;
  final VoidCallback? onDetailTap;

  const BaseControlCard({
    super.key,
    required this.zoneId,
    required this.title,
    required this.icon,
    required this.color,
    this.isCompact = false,
    this.onTap,
    this.onDetailTap,
  });

  /// Build the main content for this card
  Widget buildContent(BuildContext context);

  /// Build the status text shown in compact mode
  String getStatusText();

  /// Build the detail screen widget (optional)
  Widget? buildDetailScreen(BuildContext context) => null;

  /// Whether this card has detailed controls
  bool get hasDetailScreen => false; // Default: no detail screen

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard(context);
    } else {
      return _buildFullCard(context);
    }
  }

  Widget _buildCompactCard(BuildContext context) {
    return BaseCard(
      onTap: onTap ?? (hasDetailScreen ? onDetailTap : null),
      margin: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              if (hasDetailScreen)
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 12,
                ),
            ],
          ),
          
          const Spacer(),
          
          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 2),
          
          // Status
          Text(
            getStatusText(),
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard(BuildContext context) {
    return BaseCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildCardHeader(context),
          
          const SizedBox(height: 16),
          
          // Main content
          Expanded(
            child: buildContent(context),
          ),
          
          // Footer with actions
          if (hasDetailScreen) _buildCardFooter(context),
        ],
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (hasDetailScreen)
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey.shade400,
            size: 16,
          ),
      ],
    );
  }

  Widget _buildCardFooter(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 1,
          color: Colors.grey.shade700.withValues(alpha:0.3),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onDetailTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'View Details',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.open_in_new,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Simple control card for basic on/off controls
class SimpleControlCard extends BaseControlCard {
  final bool isEnabled;
  final bool isActive;
  final VoidCallback? onToggle;

  const SimpleControlCard({
    super.key,
    required super.zoneId,
    required super.title,
    required super.icon,
    required super.color,
    required this.isEnabled,
    required this.isActive,
    this.onToggle,
    super.isCompact = false,
    super.onTap,
    super.onDetailTap,
  });

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withValues(alpha:0.2)
                : isEnabled
                    ? Colors.blue.withValues(alpha:0.2)
                    : Colors.grey.withValues(alpha:0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? Colors.green
                  : isEnabled
                      ? Colors.blue
                      : Colors.grey,
              width: 1,
            ),
          ),
          child: Text(
            isActive ? 'RUNNING' : isEnabled ? 'READY' : 'DISABLED',
            style: TextStyle(
              color: isActive
                  ? Colors.green
                  : isEnabled
                      ? Colors.blue
                      : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        const Spacer(),
        
        // Toggle button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isEnabled ? onToggle : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isActive ? 'Stop' : 'Start',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  @override
  String getStatusText() {
    return isActive ? 'Running' : isEnabled ? 'Ready' : 'Disabled';
  }
}

/// Status indicator widget for cards
class CardStatusIndicator extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const CardStatusIndicator({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Quick action button for cards
class CardActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isSelected;

  const CardActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha:0.2)
              : Colors.grey.shade800.withValues(alpha:0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade600,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade400,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}