// lib/services/camera_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/camera.dart';
// import '../models/image_info.dart'; // Unused
import '../models/timelapse_image.dart';
import '../services/database_helper.dart';
import '../services/hardware_service.dart';
import '../services/interval_scheduler_service.dart';

/// CameraService handles camera operations including capture, timelapse, and management
class CameraService {
  static CameraService? _instance;
  static CameraService get instance => _instance ??= CameraService._internal();

  CameraService._internal();

  // Services
  final DatabaseHelper _db = DatabaseHelper();
  final HardwareService _hardware = HardwareService.instance;

  // State
  final Map<int, Timer> _timelapseTimers = {};
  bool _isInitialized = false;

  /// Initialize the camera service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Start any existing timelapse schedules
      await _startTimelapseSchedules();
      _isInitialized = true;
      debugPrint('CameraService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing CameraService: $e');
      rethrow;
    }
  }

  /// Dispose the camera service
  void dispose() {
    // Cancel all timelapse timers
    for (final timer in _timelapseTimers.values) {
      timer.cancel();
    }
    _timelapseTimers.clear();
    _isInitialized = false;
  }

  /// Capture an image from a specific camera
  Future<String> captureImage(int cameraId, int growId) async {
    try {
      final camera = await _db.getCamera(cameraId);
      if (camera == null) {
        throw Exception('Camera not found: $cameraId');
      }
      if (!camera.enabled) {
        throw Exception('Camera is disabled: $cameraId');
      }
      return await _hardware.captureImage(
        camera.id!,
        camera.cameraIndex,
        growId,
        camera.resolutionWidth,
        camera.resolutionHeight,
      );
    } catch (e) {
      throw Exception('Failed to capture image from camera $cameraId: $e');
    }
  }

  /// Start timelapse for a camera
  Future<void> startTimelapse(int cameraId, int growId) async {
    try {
      // Get camera details
      final camera = await _db.getCamera(cameraId);
      if (camera == null) {
        throw Exception('Camera not found: $cameraId');
      }

      if (!camera.enabled) {
        throw Exception('Camera is disabled: $cameraId');
      }

      // Cancel existing timer if running
      _timelapseTimers[cameraId]?.cancel();

      // Calculate interval in milliseconds
      final intervalMs = (camera.captureIntervalHours * 60 * 60 * 1000).round();

      // Start periodic timer
      _timelapseTimers[cameraId] = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (timer) async {
          try {
            // Check if we should only capture when lights are on
            if (camera.onlyWhenLightsOn) {
              // We need the zone ID to check lights.
              // Currently, we pass growId to captureImage, but we need zoneId for light check.
              // We can get the zone from the camera assignment.
              final assignment = await _db.getCameraAssignment(cameraId);
              if (assignment != null) {
                final isLightOn = await IntervalSchedulerService().isLightOnForZone(assignment.zoneId);
                if (!isLightOn) {
                  debugPrint('Skipping timelapse for camera $cameraId: Lights are OFF');
                  return;
                }
              }
            }

            await captureImage(cameraId, growId);
            debugPrint('Timelapse image captured for camera $cameraId');
          } catch (e) {
            debugPrint('Error capturing timelapse image: $e');
          }
        },
      );

      debugPrint('Timelapse started for camera $cameraId');
    } catch (e) {
      throw Exception('Failed to start timelapse for camera $cameraId: $e');
    }
  }

  /// Stop timelapse for a camera
  void stopTimelapse(int cameraId) {
    _timelapseTimers[cameraId]?.cancel();
    _timelapseTimers.remove(cameraId);
    debugPrint('Timelapse stopped for camera $cameraId');
  }

  /// Check if timelapse is running for a camera
  bool isTimelapseRunning(int cameraId) {
    return _timelapseTimers.containsKey(cameraId);
  }

  /// Get all cameras
  Future<List<Camera>> getCameras() async {
    return await _db.getCameras();
  }

  /// Get cameras for a specific zone
  Future<List<Camera>> getZoneCameras(int zoneId) async {
    final assignments = await _db.getZoneCameras(zoneId);
    final cameras = <Camera>[];
    for (final assignment in assignments) {
      final camera = await _db.getCamera(assignment.cameraId);
      if (camera != null) {
        cameras.add(camera);
      }
    }
    return cameras;
  }

  /// Add a new camera
  Future<int> addCamera(Camera camera) async {
    return await _db.addCamera(camera);
  }

  /// Assign camera to a zone
  Future<void> assignCameraToZone(int cameraId, int zoneId, String position) async {
    await _db.assignCameraToZone(cameraId, zoneId, position);
  }

  /// Update camera settings
  Future<void> updateCamera(Camera camera) async {
    await _db.updateCamera(camera);

    // Restart timelapse if it was running
    if (camera.id != null && _timelapseTimers.containsKey(camera.id)) {
      stopTimelapse(camera.id!);
      // Note: growId would need to be tracked separately for restart
      debugPrint('Camera ${camera.id} updated, timelapse needs manual restart');
    }
  }

  /// Delete a camera
  Future<void> deleteCamera(int cameraId) async {
    // Stop timelapse first
    stopTimelapse(cameraId);

    // Remove from database using helper to handle dependencies
    await _db.deleteCamera(cameraId);
  }

  /// Detect available cameras in the system
  Future<List<Map<String, dynamic>>> detectCameras() async {
    try {
      final result = await Process.run('python3', [
        'python/hardware/detect_cameras.py',
      ]);

      if (result.exitCode != 0) {
        throw Exception('Failed to detect cameras: ${result.stderr}');
      }

      final List<dynamic> jsonList = jsonDecode(result.stdout.toString().trim());
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error detecting cameras: $e');
      rethrow;
    }
  }

  /// Start all timelapse schedules for active cameras
  Future<void> _startTimelapseSchedules() async {
    try {
      final cameras = await getCameras();
      final activeGrows = await _db.getActiveGrows();

      if (activeGrows.isEmpty) {
        debugPrint('No active grows, skipping timelapse startup');
        return;
      }

      final primaryGrowId = activeGrows.first.id;

      for (final camera in cameras) {
        if (camera.enabled) {
          try {
            // If we have a grow, start timelapse
            if (primaryGrowId != null && camera.id != null) {
              await startTimelapse(camera.id!, primaryGrowId);
            }
          } catch (e) {
            debugPrint('Failed to start timelapse for camera ${camera.id}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error starting timelapse schedules: $e');
    }
  }
  /// Get statistics for a camera (photo count and storage used)
  Future<Map<String, dynamic>> getCameraStats(int cameraId, int growId) async {
    try {
      final dir = Directory('/home/sprigrig/SprigRig-main/media/images/grow_$growId');
      if (!await dir.exists()) {
        return {'count': 0, 'storageUsed': '0 MB'};
      }

      final allFiles = await dir.list().toList();

      // Filter for this camera's images (not thumbnails)
      final photoFiles = allFiles.where((f) =>
        f.path.contains('cam${cameraId}_') &&
        !f.path.contains('thumb_') &&
        f.path.endsWith('.jpg')
      ).toList();

      int totalBytes = 0;
      for (final file in photoFiles) {
        final stat = await file.stat();
        totalBytes += stat.size;
      }

      final photoCount = photoFiles.length;
      final storageMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);

      return {
        'count': photoCount,
        'storageUsed': '$storageMB MB',
      };
    } catch (e) {
      debugPrint('Error getting camera stats: $e');
      return {'count': 0, 'storageUsed': '0 MB'};
    }
  }

  Future<List<TimelapseImage>> getTimelapseImages(int cameraId, int growId, {DateTime? startDate, DateTime? endDate}) async {
    // Note: This path should match where HardwareService saves images
    final dir = Directory('/home/sprigrig/SprigRig-main/media/images/grow_$growId');
    if (!await dir.exists()) return [];

    final files = await dir.list().toList();
    final images = <TimelapseImage>[];

    // Regex to parse: cam3_20251207_121047.jpg
    final regex = RegExp(r'cam(\d+)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})\.jpg$');

    for (final file in files) {
      if (file.path.contains('thumb_')) continue;
      if (!file.path.endsWith('.jpg')) continue;

      final filename = path.basename(file.path);
      final match = regex.firstMatch(filename);
      
      if (match != null && int.parse(match.group(1)!) == cameraId) {
        final year = int.parse(match.group(2)!);
        final month = int.parse(match.group(3)!);
        final day = int.parse(match.group(4)!);
        final hour = int.parse(match.group(5)!);
        final minute = int.parse(match.group(6)!);
        final second = int.parse(match.group(7)!);
        
        final capturedAt = DateTime(year, month, day, hour, minute, second);

        if (startDate != null && capturedAt.isBefore(startDate)) continue;
        if (endDate != null && capturedAt.isAfter(endDate)) continue;

        final thumbnailPath = path.join(path.dirname(file.path), 'thumb_$filename');

        images.add(TimelapseImage(
          path: file.path,
          thumbnailPath: thumbnailPath,
          capturedAt: capturedAt,
          cameraId: cameraId,
        ));
      }
    }

    images.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    return images;
  }

  Future<void> exportTimelapse({
    required List<TimelapseImage> images,
    required String outputPath,
    required int fps,
    required int width,
    required int height,
    required Function(double) onProgress,
  }) async {
    if (images.isEmpty) return;

    // Create a temporary file list for ffmpeg
    final tempDir = Directory.systemTemp;
    final listFile = File('${tempDir.path}/timelapse_input_${DateTime.now().millisecondsSinceEpoch}.txt');
    
    try {
      final sink = listFile.openWrite();
      for (final image in images) {
        sink.writeln("file '${image.path}'");
        // Duration for each image (inverse of fps)
        // Actually for 'concat' demuxer with -r on input, we might just list files.
        // But to be safe and control duration per frame exactly:
        // sink.writeln("duration ${1/fps}"); 
        // Wait, standard ffmpeg concat usage for timelapse is just listing files and setting -r before -i
      }
      await sink.close();

      // Call python script
      final scriptPath = '/Users/gaiaforge/SprigRig-main/python/camera/export_timelapse.py';
      
      final process = await Process.start('python3', [
        scriptPath,
        '--input_list', listFile.path,
        '--output', outputPath,
        '--fps', fps.toString(),
        '--width', width.toString(),
        '--height', height.toString(),
      ]);

      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        debugPrint('FFMPEG: $line');
        if (line.startsWith('PROGRESS:')) {
          final progress = double.tryParse(line.substring(9)) ?? 0.0;
          onProgress(progress / 100.0);
        }
      });

      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        debugPrint('FFMPEG ERR: $line');
      });

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        throw Exception('FFmpeg failed with exit code $exitCode');
      }
    } finally {
      if (await listFile.exists()) {
        await listFile.delete();
      }
    }
  }

  Future<Map<String, dynamic>> getDiskUsage() async {
    try {
      // Use df to get disk usage of the media directory
      // -B1 for bytes
      final result = await Process.run('df', ['-B1', '/home/sprigrig/SprigRig-main/media']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().trim().split('\n');
        if (lines.length >= 2) {
          // Filesystem     1K-blocks    Used Available Use% Mounted on
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            final totalBytes = int.tryParse(parts[1]) ?? 0;
            final usedBytes = int.tryParse(parts[2]) ?? 0;
            final freeBytes = int.tryParse(parts[3]) ?? 0;
            
            return {
              'total': totalBytes,
              'used': usedBytes,
              'free': freeBytes,
              'percent': totalBytes > 0 ? (usedBytes / totalBytes) : 0.0,
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting disk usage: $e');
    }
    return {'total': 0, 'used': 0, 'free': 0, 'percent': 0.0};
  }

  Future<void> deleteImages(List<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        // Thumbnail path logic: /cam -> /thumb_cam
        final thumbPath = path.replaceFirst('/cam', '/thumb_cam');
        final thumbFile = File(thumbPath);

        if (await file.exists()) {
          await file.delete();
        }
        if (await thumbFile.exists()) {
          await thumbFile.delete();
        }
      } catch (e) {
        debugPrint('Error deleting image $path: $e');
      }
    }
  }

  Future<void> exportZip({
    required List<String> filePaths,
    required String outputPath,
    required Function(double) onProgress,
  }) async {
    if (filePaths.isEmpty) return;

    try {
      // Create a temporary file list for zip
      // zip -@ archive.zip < filelist.txt
      final tempDir = Directory.systemTemp;
      final listFile = File('${tempDir.path}/zip_input_${DateTime.now().millisecondsSinceEpoch}.txt');
      
      await listFile.writeAsString(filePaths.join('\n'));

      final process = await Process.start('zip', [
        '-@',
        outputPath,
      ]);
      
      // Pipe file list to stdin
      process.stdin.add(await listFile.readAsBytes());
      await process.stdin.close();

      // Monitor output? zip doesn't give easy progress percentage without parsing file count.
      // For now, just wait.
      
      final exitCode = await process.exitCode;
      
      if (await listFile.exists()) {
        await listFile.delete();
      }

      if (exitCode != 0) {
        throw Exception('Zip failed with exit code $exitCode');
      }
      
      onProgress(1.0);
    } catch (e) {
      debugPrint('Error exporting zip: $e');
      rethrow;
    }
  }
}
