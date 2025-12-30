import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/guardian/guardian_status.dart';
import '../../models/guardian/guardian_alert.dart';
import '../../services/guardian/guardian_service.dart';

class GuardianTile extends StatefulWidget {
  final int zoneId;
  final VoidCallback onTap;

  const GuardianTile({
    required this.zoneId,
    required this.onTap,
    super.key,
  });

  @override
  State<GuardianTile> createState() => _GuardianTileState();
}

class _GuardianTileState extends State<GuardianTile> {
  GuardianStatus? _status;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    // Refresh every 5 minutes
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadStatus(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await GuardianService().getZoneStatus(widget.zoneId);
      if (mounted) {
        setState(() {
          _status = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading Guardian status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingTile();
    }

    if (_status == null) {
      return _buildErrorTile();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: _getStatusGradient(_status!.overallStatus),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor(_status!.overallStatus).withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.shield, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Guardian',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildStatusBadge(_status!.overallStatus),
              ],
            ),

            const SizedBox(height: 12),

            // Summary
            Text(
              _status!.summary,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Trend indicators
            _buildTrendRow(_status!.trends),

            // Alert (if any)
            if (_status!.alerts.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildAlertPreview(_status!.alerts.first),
            ],

            const SizedBox(height: 12),

            // Footer
            Row(
              children: [
                Text(
                  'Last analysis: ${_formatTimeAgo(_status!.lastAnalysis)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      'Ask Guardian',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingTile() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorTile() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: const Center(
        child: Text(
          'Guardian Unavailable',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    String label = status[0].toUpperCase() + status.substring(1);
    IconData icon = Icons.check_circle;

    if (status == 'warning') icon = Icons.warning;
    if (status == 'critical') icon = Icons.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 14, color: color),
        ],
      ),
    );
  }

  Widget _buildTrendRow(Map<String, String> trends) {
    if (trends.isEmpty) return const SizedBox.shrink();
    
    return Row(
      children: [
        Text(
          'Trends: ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: trends.entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMetricName(e.key),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _getTrendIcon(e.value),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }
  
  String _formatMetricName(String key) {
    switch (key) {
      case 'temperature': return 'Temp';
      case 'humidity': return 'Hum';
      default: return key[0].toUpperCase() + key.substring(1);
    }
  }

  Widget _getTrendIcon(String trend) {
    switch (trend) {
      case 'rising':
        return const Icon(Icons.trending_up, size: 14, color: Colors.orangeAccent);
      case 'falling':
        return const Icon(Icons.trending_down, size: 14, color: Colors.blueAccent);
      default:
        return const Icon(Icons.trending_flat, size: 14, color: Colors.greenAccent);
    }
  }

  Widget _buildAlertPreview(GuardianAlert alert) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getAlertColor(alert.severity).withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getAlertIcon(alert.severity),
            size: 16,
            color: _getAlertColor(alert.severity),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alert.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'healthy':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  LinearGradient _getStatusGradient(String status) {
    final color = _getStatusColor(status);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.3),
        color.withOpacity(0.1),
      ],
    );
  }
  
  Color _getAlertColor(String severity) {
    switch (severity) {
      case 'critical': return Colors.red;
      case 'warning': return Colors.orange;
      case 'info': return Colors.blue;
      default: return Colors.grey;
    }
  }
  
  IconData _getAlertIcon(String severity) {
    switch (severity) {
      case 'critical': return Icons.error_outline;
      case 'warning': return Icons.warning_amber_rounded;
      case 'info': return Icons.info_outline;
      default: return Icons.notifications_none;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}
