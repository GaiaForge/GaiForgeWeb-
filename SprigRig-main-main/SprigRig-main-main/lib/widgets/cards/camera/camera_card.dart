// lib/widgets/cards/camera/camera_card.dart
import 'package:flutter/material.dart';
import '../base_control_card.dart';
import 'camera_detail_screen.dart';

class CameraCard extends BaseControlCard {
  final int cameraId; // Added
  final int cameraIndex;
  final bool isCameraActive;
  final bool isTimelapseRunning;
  final String timelapseInterval;
  final int totalPhotos;
  final String storageUsed;
  final String nextCapture;
  final String resolution;
  final String cameraModel;
  final double initialIntervalHours;
  final bool onlyWhenLightsOn;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onStartTimelapse;
  final VoidCallback? onStopTimelapse;
  final Future<String?> Function()? onTakePhoto;
  final ValueChanged<double>? onIntervalChanged;
  final ValueChanged<String>? onResolutionChanged;
  final ValueChanged<bool>? onToggleOnlyWhenLightsOn;

  const CameraCard({
    super.key,
    required super.zoneId,
    required this.cameraId, // Added
    required this.cameraIndex,
    required this.isCameraActive,
    required this.isTimelapseRunning,
    required this.timelapseInterval,
    required this.totalPhotos,
    required this.storageUsed,
    required this.nextCapture,
    required this.resolution,
    required this.cameraModel,
    required this.initialIntervalHours,
    required this.onlyWhenLightsOn,
    this.onToggleCamera,
    this.onStartTimelapse,
    this.onStopTimelapse,
    this.onTakePhoto,
    this.onIntervalChanged,
    this.onResolutionChanged,
    this.onToggleOnlyWhenLightsOn,
    super.isCompact = false,
    super.onTap,
    super.onDetailTap,
  }) : super(
          title: 'Camera',
          icon: Icons.camera_alt,
          color: Colors.pink,
        );

  @override
  bool get hasDetailScreen => true; // Has detail screen

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status and photos row
        Row(
          children: [
            Expanded(
              child: CardStatusIndicator(
                label: 'Camera',
                value: isCameraActive ? 'ONLINE' : 'OFFLINE',
                color: isCameraActive ? Colors.green : Colors.grey,
                icon: isCameraActive ? Icons.videocam : Icons.videocam_off,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CardStatusIndicator(
                label: 'Photos',
                value: totalPhotos.toString(),
                color: _getPhotoCountColor(totalPhotos),
                icon: Icons.photo_library,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Time-lapse status and storage info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isTimelapseRunning
                ? Colors.pink.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isTimelapseRunning ? Colors.pink : Colors.grey,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    isTimelapseRunning ? Icons.fiber_manual_record : Icons.stop_circle_outlined,
                    color: isTimelapseRunning ? Colors.red : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isTimelapseRunning ? 'Recording • $timelapseInterval' : 'Time-lapse Stopped',
                      style: TextStyle(
                        color: isTimelapseRunning ? Colors.pink : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    storageUsed,
                    style: TextStyle(
                      color: _getStorageColor(storageUsed),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (isTimelapseRunning) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.grey.shade400,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Next: $nextCapture',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const Spacer(),

        // Quick action buttons
        Row(
          children: [
            Expanded(
              child: CardActionButton(
                label: isTimelapseRunning ? 'Stop' : 'Record',
                icon: isTimelapseRunning ? Icons.stop : Icons.play_arrow,
                color: isTimelapseRunning ? Colors.red : Colors.pink,
                onPressed: isCameraActive ? () {
                  if (isTimelapseRunning) {
                    onStopTimelapse?.call();
                  } else {
                    onStartTimelapse?.call();
                  }
                } : null,
                isSelected: false,
              ),
            ),
            const SizedBox(width: 8),
            CardActionButton(
              label: 'Capture',
              icon: Icons.camera,
              color: Colors.blue,
              onPressed: isCameraActive ? () => onTakePhoto?.call() : null,
              isSelected: false,
            ),
          ],
        ),
      ],
    );
  }

  @override
  String getStatusText() {
    if (!isCameraActive) {
      return 'Offline';
    } else if (isTimelapseRunning) {
      return 'Recording • $totalPhotos photos';
    } else {
      return 'Online • $totalPhotos photos';
    }
  }

  @override
  Widget? buildDetailScreen(BuildContext context) {
    return CameraDetailScreen(
      zoneId: zoneId,
      cameraId: cameraId,
      cameraIndex: cameraIndex,
      isCameraActive: isCameraActive,
      isTimelapseRunning: isTimelapseRunning,
      timelapseInterval: timelapseInterval,
      totalPhotos: totalPhotos,
      storageUsed: storageUsed,
      nextCapture: nextCapture,
      resolution: resolution,
      cameraModel: cameraModel,
      initialIntervalHours: initialIntervalHours,
      onlyWhenLightsOn: onlyWhenLightsOn,
      onToggleCamera: onToggleCamera,
      onStartTimelapse: onStartTimelapse,
      onStopTimelapse: onStopTimelapse,
      onTakePhoto: onTakePhoto,
      onIntervalChanged: onIntervalChanged,
      onResolutionChanged: onResolutionChanged,
      onToggleOnlyWhenLightsOn: onToggleOnlyWhenLightsOn,
    );
  }

  // Helper methods
  Color _getPhotoCountColor(int count) {
    if (count == 0) return Colors.grey;
    if (count < 50) return Colors.blue;
    if (count < 200) return Colors.green;
    if (count < 500) return Colors.orange;
    return Colors.red;
  }

  Color _getStorageColor(String storage) {
    // Simple storage color logic based on text
    if (storage.contains('GB')) {
      final value = double.tryParse(storage.split(' ')[0]) ?? 0;
      if (value < 1.0) return Colors.green;
      if (value < 3.0) return Colors.yellow;
      if (value < 5.0) return Colors.orange;
      return Colors.red;
    }
    return Colors.blue; // For MB values
  }
}

