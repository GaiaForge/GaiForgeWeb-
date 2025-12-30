import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/camera.dart';
import '../../models/timelapse_image.dart';
import '../../services/camera_service.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/cards/glass_card.dart';
import 'full_image_viewer_screen.dart';

class MediaManagementScreen extends StatefulWidget {
  final int cameraId;
  final int growId;

  const MediaManagementScreen({
    super.key,
    required this.cameraId,
    required this.growId,
  });

  @override
  State<MediaManagementScreen> createState() => _MediaManagementScreenState();
}

class _MediaManagementScreenState extends State<MediaManagementScreen> {
  bool _isLoading = true;
  Camera? _camera;
  List<TimelapseImage> _images = [];
  Map<String, dynamic> _diskUsage = {};
  
  // Selection
  final Set<String> _selectedPaths = {};
  bool _isSelectionMode = false;

  // Auto-Cleanup Settings
  bool _autoCleanupEnabled = false;
  int _retentionDays = 30;
  int _maxPhotos = 10000;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch camera to get settings
      // We need a method in CameraService or DatabaseHelper to get camera by ID.
      // DatabaseHelper has getCameras() but not getCamera(id).
      // Let's assume we can filter from getCameras for now or add getCamera.
      // Actually CameraService has _cameras list but it might not be exposed.
      // Let's use DatabaseHelper directly or add a method.
      // For now, let's iterate getCameras since it's likely small.
      final cameras = await DatabaseHelper().getCameras();
      final camera = cameras.firstWhere((c) => c.id == widget.cameraId);
      
      final images = await CameraService.instance.getTimelapseImages(
        widget.cameraId,
        widget.growId,
      );
      final diskUsage = await CameraService.instance.getDiskUsage();
      
      if (mounted) {
        setState(() {
          _camera = camera;
          _autoCleanupEnabled = camera.autoCleanupEnabled;
          _retentionDays = camera.retentionDays ?? 30;
          _maxPhotos = camera.maxPhotos ?? 10000;
          
          _images = images;
          _diskUsage = diskUsage;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading media data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_camera == null) return;
    
    final updatedCamera = Camera(
      id: _camera!.id,
      name: _camera!.name,
      devicePath: _camera!.devicePath,
      cameraIndex: _camera!.cameraIndex,
      model: _camera!.model,
      resolutionWidth: _camera!.resolutionWidth,
      resolutionHeight: _camera!.resolutionHeight,
      captureIntervalHours: _camera!.captureIntervalHours,
      enabled: _camera!.enabled,
      onlyWhenLightsOn: _camera!.onlyWhenLightsOn,
      autoCleanupEnabled: _autoCleanupEnabled,
      retentionDays: _retentionDays,
      maxPhotos: _maxPhotos,
      createdAt: _camera!.createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    await CameraService.instance.updateCamera(updatedCamera);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _exportZip() async {
    if (_selectedPaths.isEmpty) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      ),
    );

    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final outputPath = '/home/sprigrig/SprigRig-main/media/export_${_camera?.name ?? 'camera'}_$timestamp.zip';

      await CameraService.instance.exportZip(
        filePaths: _selectedPaths.toList(),
        outputPath: outputPath,
        onProgress: (progress) {},
      );

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export saved to: $outputPath'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isSelectionMode = false;
          _selectedPaths.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showVideoExportDialog() async {
    if (_selectedPaths.isEmpty) return;

    int selectedFps = 24;
    String selectedResolution = '1920x1080';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Export Video', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create video from ${_selectedPaths.length} selected photos.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              
              // FPS Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Frame Rate:', style: TextStyle(color: Colors.white)),
                  DropdownButton<int>(
                    value: selectedFps,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white),
                    items: [10, 15, 24, 30].map((fps) {
                      return DropdownMenuItem(
                        value: fps,
                        child: Text('$fps FPS'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedFps = value);
                    },
                  ),
                ],
              ),
              
              // Resolution Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Resolution:', style: TextStyle(color: Colors.white)),
                  DropdownButton<String>(
                    value: selectedResolution,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white),
                    items: ['1920x1080', '1280x720', '640x480'].map((res) {
                      return DropdownMenuItem(
                        value: res,
                        child: Text(res),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedResolution = value);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
              child: const Text('EXPORT', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );

      try {
        // Sort selected images by date
        final selectedImages = _images.where((img) => _selectedPaths.contains(img.path)).toList();
        selectedImages.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));

        final parts = selectedResolution.split('x');
        final width = int.parse(parts[0]);
        final height = int.parse(parts[1]);

        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final outputPath = '/home/sprigrig/SprigRig-main/media/video_${_camera?.name ?? 'camera'}_$timestamp.mp4';

        await CameraService.instance.exportTimelapse(
          images: selectedImages,
          outputPath: outputPath,
          fps: selectedFps,
          width: width,
          height: height,
          onProgress: (progress) {},
        );

        if (mounted) {
          Navigator.pop(context); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video saved to: $outputPath'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isSelectionMode = false;
            _selectedPaths.clear();
          });
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
        if (_selectedPaths.isEmpty) _isSelectionMode = false;
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _isSelectionMode = true;
      _selectedPaths.addAll(_images.map((img) => img.path));
    });
  }
  void _deselectAll() {
    setState(() {
      _isSelectionMode = false;
      _selectedPaths.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedPaths.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Photos', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${_selectedPaths.length} photos? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
      );

      try {
        await CameraService.instance.deleteImages(_selectedPaths.toList());
        
        if (mounted) {
          Navigator.pop(context); // Close loading
          setState(() {
            _images.removeWhere((img) => _selectedPaths.contains(img.path));
            _selectedPaths.clear();
            _isSelectionMode = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photos deleted'), backgroundColor: Colors.green),
          );
          _loadData(); // Refresh stats
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting photos: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _selectByDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _isSelectionMode = true;
        _selectedPaths.clear();
        for (var img in _images) {
          if (img.capturedAt.isAfter(picked.start.subtract(const Duration(seconds: 1))) && 
              img.capturedAt.isBefore(picked.end.add(const Duration(days: 1)))) {
            _selectedPaths.add(img.path);
          }
        }
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes > 0) ? (bytes.toString().length - 1) ~/ 3 : 0; // Simplified log10
    // Better implementation
    if (bytes < 1024) return "$bytes B";
    double num = bytes.toDouble();
    int suffixIndex = 0;
    while (num >= 1024 && suffixIndex < suffixes.length - 1) {
      num /= 1024;
      suffixIndex++;
    }
    return '${num.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final totalSpace = _diskUsage['total'] as int? ?? 0;
    final usedSpace = _diskUsage['used'] as int? ?? 0;
    final freeSpace = _diskUsage['free'] as int? ?? 0;
    final percentUsed = _diskUsage['percent'] as double? ?? 0.0;
    final isStorageWarning = percentUsed > 0.8;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(_isSelectionMode ? '${_selectedPaths.length} Selected' : 'MEDIA MANAGEMENT', 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (_isSelectionMode) ...[
              IconButton(
                icon: const Icon(Icons.select_all, color: Colors.white),
                tooltip: 'Select All',
                onPressed: _selectAll,
              ),
              IconButton(
                icon: const Icon(Icons.deselect, color: Colors.white),
                tooltip: 'Deselect All',
                onPressed: _deselectAll,
              ),
              IconButton(
                icon: const Icon(Icons.archive, color: Colors.white),
                tooltip: 'Export ZIP',
                onPressed: _exportZip,
              ),
              IconButton(
                icon: const Icon(Icons.movie, color: Colors.white),
                tooltip: 'Export Video',
                onPressed: _showVideoExportDialog,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: _deleteSelected,
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Storage Header
                    GlassCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('PHOTOS', '${_images.length}'),
                              _buildStatItem('USED', _formatBytes(usedSpace)),
                              _buildStatItem('FREE', _formatBytes(freeSpace)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentUsed,
                              backgroundColor: Colors.white10,
                              color: isStorageWarning ? Colors.redAccent : Colors.cyanAccent,
                              minHeight: 8,
                            ),
                          ),
                          if (isStorageWarning)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Storage is ${percentUsed * 100 > 0 ? (percentUsed * 100).toStringAsFixed(0) : 0}% full!',
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Auto-Cleanup Settings
                    const Text(
                      'AUTO-CLEANUP',
                      style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Enable Auto-Cleanup', style: TextStyle(color: Colors.white)),
                            value: _autoCleanupEnabled,
                            onChanged: (value) {
                              setState(() => _autoCleanupEnabled = value);
                              _saveSettings();
                            },
                            activeColor: Colors.cyanAccent,
                          ),
                          if (_autoCleanupEnabled) ...[
                            const Divider(color: Colors.white10),
                            ListTile(
                              title: const Text('Delete older than', style: TextStyle(color: Colors.white)),
                              trailing: DropdownButton<int>(
                                value: _retentionDays,
                                dropdownColor: Colors.grey[900],
                                style: const TextStyle(color: Colors.white),
                                items: [7, 14, 30, 60, 90].map((days) {
                                  return DropdownMenuItem(
                                    value: days,
                                    child: Text('$days days'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _retentionDays = value);
                                    _saveSettings();
                                  }
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('Keep max photos', style: TextStyle(color: Colors.white)),
                              trailing: DropdownButton<int>(
                                value: _maxPhotos,
                                dropdownColor: Colors.grey[900],
                                style: const TextStyle(color: Colors.white),
                                items: [1000, 5000, 10000, 20000].map((count) {
                                  return DropdownMenuItem(
                                    value: count,
                                    child: Text('$count'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _maxPhotos = value);
                                    _saveSettings();
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bulk Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'MANAGE PHOTOS',
                          style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                        TextButton(
                          onPressed: _selectByDateRange,
                          child: const Text('SELECT BY DATE', style: TextStyle(color: Colors.cyanAccent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Photo Grid (Paginated via GridView.builder)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        // Show latest first
                        final imageIndex = _images.length - 1 - index;
                        final image = _images[imageIndex];
                        final isSelected = _selectedPaths.contains(image.path);
                        
                        return GestureDetector(
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleSelection(image.path);
                            } else {
                              // Open Full Image Viewer
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullImageViewerScreen(
                                    images: _images, // Pass all images for swiping
                                    initialIndex: imageIndex,
                                    onDelete: (deletedPaths) {
                                      // Handle deletion from viewer
                                      setState(() {
                                        _images.removeWhere((img) => deletedPaths.contains(img.path));
                                      });
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              setState(() => _isSelectionMode = true);
                              _toggleSelection(image.path);
                            }
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(image.thumbnailPath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
                              ),
                              if (isSelected)
                                Container(
                                  color: Colors.cyanAccent.withOpacity(0.4),
                                  child: const Icon(Icons.check, color: Colors.white),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}
