import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../models/camera.dart';
import '../../services/camera_service.dart';
import '../../widgets/cards/camera/camera_detail_screen.dart';

class CameraGridScreen extends StatefulWidget {
  final Zone zone;

  const CameraGridScreen({super.key, required this.zone});

  @override
  State<CameraGridScreen> createState() => _CameraGridScreenState();
}

class _CameraGridScreenState extends State<CameraGridScreen> {
  final CameraService _cameraService = CameraService.instance;
  List<Camera> _cameras = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    setState(() => _isLoading = true);
    try {
      final cameras = await _cameraService.getCameras();
      setState(() {
        _cameras = cameras;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading cameras: $e');
      setState(() => _isLoading = false);
    }
  }



  Future<void> _navigateToDetail(Camera camera) async {
    final cameraId = camera.id;
    if (cameraId == null) return;

    final isRunning = _cameraService.isTimelapseRunning(cameraId);
    
    // Fetch real stats
    final stats = await _cameraService.getCameraStats(cameraId, widget.zone.id!);
    
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: CameraDetailScreen(
            zoneId: widget.zone.id!,
            cameraId: cameraId,
            cameraIndex: camera.cameraIndex,
            isCameraActive: camera.enabled,
            isTimelapseRunning: isRunning,
            timelapseInterval: '${camera.captureIntervalHours}h',
            totalPhotos: stats['count'] as int? ?? 0,
            storageUsed: stats['storageUsed'],
            nextCapture: 'Pending',
            resolution: '${camera.resolutionWidth}x${camera.resolutionHeight}',
            cameraModel: camera.model,
            initialIntervalHours: camera.captureIntervalHours.toDouble(),
            onlyWhenLightsOn: camera.onlyWhenLightsOn,
            onIntervalChanged: (hours) async {
              final updatedCamera = Camera(
                id: cameraId,
                name: camera.name,
                devicePath: camera.devicePath,
                cameraIndex: camera.cameraIndex,
                model: camera.model,
                resolutionWidth: camera.resolutionWidth,
                resolutionHeight: camera.resolutionHeight,
                captureIntervalHours: hours.toInt(),
                enabled: camera.enabled,
                onlyWhenLightsOn: camera.onlyWhenLightsOn,
                createdAt: camera.createdAt,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              );
              await _cameraService.updateCamera(updatedCamera);
              _loadCameras();
            },
            onToggleCamera: () async {
              final updatedCamera = Camera(
                id: cameraId,
                name: camera.name,
                devicePath: camera.devicePath,
                cameraIndex: camera.cameraIndex,
                model: camera.model,
                resolutionWidth: camera.resolutionWidth,
                resolutionHeight: camera.resolutionHeight,
                captureIntervalHours: camera.captureIntervalHours,
                enabled: !camera.enabled,
                onlyWhenLightsOn: camera.onlyWhenLightsOn,
                createdAt: camera.createdAt,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              );
              await _cameraService.updateCamera(updatedCamera);
              _loadCameras(); // Refresh grid state
            },
            onStartTimelapse: () async {
              await _cameraService.startTimelapse(cameraId, widget.zone.id!);
              _loadCameras();
            },
            onStopTimelapse: () {
              _cameraService.stopTimelapse(cameraId);
              _loadCameras();
            },
            onTakePhoto: () async {
              return await _cameraService.captureImage(cameraId, widget.zone.id!);
            },
            onToggleOnlyWhenLightsOn: (value) async {
               final updatedCamera = Camera(
                id: cameraId,
                name: camera.name,
                devicePath: camera.devicePath,
                cameraIndex: camera.cameraIndex,
                model: camera.model,
                resolutionWidth: camera.resolutionWidth,
                resolutionHeight: camera.resolutionHeight,
                captureIntervalHours: camera.captureIntervalHours,
                enabled: camera.enabled,
                onlyWhenLightsOn: value,
                createdAt: camera.createdAt,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              );
              await _cameraService.updateCamera(updatedCamera);
              _loadCameras();
            },
          ),
        ),
      ),
    ).then((_) => _loadCameras());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Camera Monitor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF006064), // Cyan 900
              Color(0xFF00BCD4), // Cyan 500
              Color(0xFF0288D1), // Light Blue 700
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _cameras.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _cameras.length,
                      itemBuilder: (context, index) {
                        final camera = _cameras[index];
                        return _buildCameraCard(camera);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildCameraCard(Camera camera) {
    return GestureDetector(
      onTap: () => _navigateToDetail(camera),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: camera.enabled ? Colors.cyanAccent.withOpacity(0.5) : Colors.white.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera Preview Placeholder
              Container(
                color: Colors.black54,
                child: Center(
                  child: Icon(
                    Icons.videocam,
                    color: camera.enabled ? Colors.white70 : Colors.white24,
                    size: 48,
                  ),
                ),
              ),
              
              // Overlay Info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        camera.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: camera.enabled ? Colors.greenAccent : Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            camera.enabled ? 'ONLINE' : 'OFFLINE',
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
              ),
              
              // Expand Icon
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.open_in_full,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No cameras configured',
            style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}
