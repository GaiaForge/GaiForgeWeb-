// lib/widgets/cards/camera/camera_detail_screen.dart
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../widgets/common/app_background.dart';
import 'dart:io';

import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:http/http.dart' as http;

import '../../../screens/camera/media_management_screen.dart';
import '../../../services/camera_service.dart';

class CameraDetailScreen extends StatefulWidget {
  final int zoneId;
  final int cameraId; // Added
  final int cameraIndex;
  final bool isCameraActive;
  final bool isTimelapseRunning;
  final String timelapseInterval;
  final double initialIntervalHours;
  final int totalPhotos;
  final String storageUsed;
  final String nextCapture;
  final String resolution;
  final String cameraModel;
  final bool onlyWhenLightsOn;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onStartTimelapse;
  final VoidCallback? onStopTimelapse;
  final Future<String?> Function()? onTakePhoto; 
  final VoidCallback? onViewTimelapse;
  final ValueChanged<double>? onIntervalChanged;
  final ValueChanged<String>? onResolutionChanged;
  final ValueChanged<bool>? onToggleOnlyWhenLightsOn;

  const CameraDetailScreen({
    super.key,
    required this.zoneId,
    required this.cameraId,
    required this.cameraIndex,
    required this.isCameraActive,
    required this.isTimelapseRunning,
    required this.timelapseInterval,
    required this.initialIntervalHours,
    required this.totalPhotos,
    required this.storageUsed,
    required this.nextCapture,
    required this.resolution,
    required this.cameraModel,
    required this.onlyWhenLightsOn,
    this.onToggleCamera,
    this.onStartTimelapse,
    this.onStopTimelapse,
    this.onTakePhoto,
    this.onViewTimelapse,
    this.onIntervalChanged,
    this.onResolutionChanged,
    this.onToggleOnlyWhenLightsOn,
  });

  @override
  State<CameraDetailScreen> createState() => _CameraDetailScreenState();
}

class _CameraDetailScreenState extends State<CameraDetailScreen> {
  bool _isLiveViewOn = false;
  late String _selectedResolution;
  bool _isCapturing = false;
  File? _capturedImage; // Add state for captured image
  int _intervalMinutes = 60; // Default 1 hour
  
  // Local stats state for live updates
  late int _photoCount;
  late String _storageUsed;

  List<String> _resolutions = [];

  @override
  void initState() {
    super.initState();
    _intervalMinutes = (widget.initialIntervalHours * 60).round();
    if (_intervalMinutes < 1) _intervalMinutes = 60;
    
    // Initialize local stats from widget props
    _photoCount = widget.totalPhotos;
    _storageUsed = widget.storageUsed;

    // Define resolutions based on camera model
    if (widget.cameraModel.toUpperCase().contains('IMX477')) {
      _resolutions = [
        '4056x3040', // Max
        '3840x2160', // 4K
        '1920x1080', // 1080p
        '1280x720',  // 720p
        '640x480',   // 480p
      ];
    } else if (widget.cameraModel.toUpperCase().contains('IMX219')) {
      _resolutions = [
        '3280x2464', // Max
        '1920x1080', // 1080p
        '1640x1232', // Binning
        '1280x720',  // 720p
        '640x480',   // 480p
      ];
    } else {
      // Default/Generic
      _resolutions = [
        '1920x1080',
        '1280x720',
        '640x480',
      ];
    }

    if (_resolutions.contains(widget.resolution)) {
      _selectedResolution = widget.resolution;
    } else {
      _selectedResolution = _resolutions.isNotEmpty ? _resolutions[0] : '1920x1080';
    }
  }

  void _parseInterval(String interval) {
    // Parse "15 minutes" or "1 hour" to minutes
    if (interval.contains('hour')) {
      final parts = interval.split(' ');
      final value = int.tryParse(parts[0]) ?? 1;
      _intervalMinutes = value * 60;
    } else if (interval.contains('minute')) {
      final parts = interval.split(' ');
      _intervalMinutes = int.tryParse(parts[0]) ?? 15;
    } else {
      _intervalMinutes = 15; // Default
    }
  }

  String _formatInterval(int minutes) {
    if (minutes >= 60) {
      final hours = minutes / 60;
      return '${hours.toStringAsFixed(hours.truncateToDouble() == hours ? 0 : 1)} hour${hours == 1 ? '' : 's'}';
    }
    return '$minutes minutes';
  }

  void _updateInterval(int minutes) {
    setState(() {
      _intervalMinutes = minutes.clamp(1, 1440); // 1 min to 24 hours
    });
    widget.onIntervalChanged?.call(_intervalMinutes / 60.0);
  }

  Future<void> _handleTakePhoto() async {
    setState(() => _isCapturing = true);
    
    // Show flash feedback overlay
    if (mounted) {
      showDialog(
        context: context,
        barrierColor: Colors.white.withOpacity(0.5),
        barrierDismissible: false,
        builder: (context) => const SizedBox(),
      );
      
      // Close flash after short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        Navigator.of(context).pop();
      });
    }

    final imagePath = await widget.onTakePhoto?.call();
    
    if (mounted) {
      setState(() {
        _isCapturing = false;
        if (imagePath != null) {
          _capturedImage = File(imagePath);
          _isLiveViewOn = false; // Turn off live view to show the image
        }
      });
      
      // Refresh stats after photo capture
      await _refreshStats();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo captured!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
  
  Future<void> _refreshStats() async {
    try {
      final stats = await CameraService.instance.getCameraStats(widget.cameraId, widget.zoneId);
      if (mounted) {
        setState(() {
          _photoCount = stats['count'] as int? ?? _photoCount;
          _storageUsed = stats['storageUsed'] as String? ?? _storageUsed;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Camera Control',
            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLivePreviewSection(),
              const SizedBox(height: 24),
              _buildTimelapseControlCard(),
              const SizedBox(height: 16),
              _buildStatsCard(),
              const SizedBox(height: 24),
              _buildSettingsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreviewSection() {
    return Column(
      children: [
        // Live View Container
        Container(
          height: 380,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _isLiveViewOn
              ? Mjpeg(
                  isLive: _isLiveViewOn,
                  stream: 'http://localhost:8081/stream/${widget.cameraIndex}',
                  fit: BoxFit.cover,
                  error: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Stream Unavailable',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () => setState(() {}),
                            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
                            label: const Text('Retry Connection', style: TextStyle(color: Colors.cyanAccent)),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : _capturedImage != null
                  ? Image.file(
                      _capturedImage!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.videocam_off_outlined, size: 64, color: Colors.white.withOpacity(0.3)),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Live View is OFF',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start live view to see camera feed',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
        const SizedBox(height: 20),
        
        // Controls Row
        Row(
          children: [
            Expanded(
              child: _GlassButton(
                onPressed: () async {
                  if (_isLiveViewOn) {
                    try {
                      await http.post(
                        Uri.parse('http://localhost:8081/stop/${widget.cameraIndex}'),
                      );
                    } catch (e) {
                      debugPrint('Error stopping stream: $e');
                    }
                  }
                  setState(() => _isLiveViewOn = !_isLiveViewOn);
                },
                icon: _isLiveViewOn ? Icons.videocam_off : Icons.videocam,
                label: _isLiveViewOn ? 'Stop Live View' : 'Start Live View',
                isActive: _isLiveViewOn,
                activeColor: Colors.redAccent,
                inactiveColor: Colors.greenAccent, // Custom color extension or use standard green
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _GlassButton(
                onPressed: (_isCapturing || _isLiveViewOn) ? null : _handleTakePhoto,
                icon: Icons.camera_alt,
                label: 'Take Photo',
                isActive: true, // Always styled as active unless disabled
                activeColor: Colors.blueAccent,
                isLoading: _isCapturing,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelapseControlCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.timelapse, color: Colors.pinkAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Timelapse',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isTimelapseRunning 
                      ? Colors.redAccent.withOpacity(0.2) 
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.isTimelapseRunning ? Colors.redAccent.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    if (widget.isTimelapseRunning) ...[
                      const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.isTimelapseRunning ? 'RECORDING' : 'IDLE',
                      style: TextStyle(
                        color: widget.isTimelapseRunning ? Colors.redAccent : Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Interval Selector
          Center(
            child: Column(
              children: [
                Text(
                  'CAPTURE INTERVAL',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RepeatableButton(
                      icon: Icons.remove,
                      onPressed: widget.isTimelapseRunning ? null : () => _updateInterval(_intervalMinutes - 1),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _formatInterval(_intervalMinutes),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    _RepeatableButton(
                      icon: Icons.add,
                      onPressed: widget.isTimelapseRunning ? null : () => _updateInterval(_intervalMinutes + 1),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Presets
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPresetButton(10, '10m'),
                      const SizedBox(width: 8),
                      _buildPresetButton(30, '30m'),
                      const SizedBox(width: 8),
                      _buildPresetButton(60, '1h'),
                      const SizedBox(width: 8),
                      _buildPresetButton(120, '2h'),
                      const SizedBox(width: 8),
                      _buildPresetButton(240, '4h'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Lights On Only Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amberAccent.withOpacity(0.8), size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Only when lights are ON',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: widget.onlyWhenLightsOn,
                  onChanged: widget.isTimelapseRunning ? null : widget.onToggleOnlyWhenLightsOn,
                  activeColor: Colors.amberAccent,
                  activeTrackColor: Colors.amberAccent.withOpacity(0.2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Buttons Row
          Row(
            children: [
              // Start/Stop Button
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.isTimelapseRunning) {
                        widget.onStopTimelapse?.call();
                      } else {
                        widget.onStartTimelapse?.call();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isTimelapseRunning 
                          ? Colors.redAccent.withOpacity(0.8) 
                          : Colors.pinkAccent.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ).copyWith(
                      overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(
                      widget.isTimelapseRunning ? 'STOP' : 'START',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // View Timelapse Button - always show
              Expanded(
                child: _GlassButton(
                  onPressed: widget.onViewTimelapse,
                  icon: Icons.play_circle_outline,
                  label: 'VIEW',
                  isActive: true,
                  activeColor: Colors.cyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(int minutes, String label) {
    final isSelected = _intervalMinutes == minutes;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isTimelapseRunning ? null : () => _updateInterval(minutes),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.pinkAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.pinkAccent.withOpacity(0.5) : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.pinkAccent : Colors.white.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return _GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.photo_library_outlined, '$_photoCount', 'Photos'),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
          _buildStatItem(Icons.sd_storage_outlined, _storageUsed, 'Storage'),
          if (widget.isTimelapseRunning) ...[
            Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
            _buildStatItem(Icons.timer_outlined, widget.nextCapture, 'Next'),
          ],
        ],
      ),
    );
  }



  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.cyanAccent.withOpacity(0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Manage Media Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MediaManagementScreen(
                      cameraId: widget.cameraId,
                      growId: widget.zoneId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.perm_media_outlined, color: Colors.cyanAccent),
              label: const Text('MANAGE MEDIA', style: TextStyle(color: Colors.cyanAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.cyanAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Resolution Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resolution',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedResolution,
                    dropdownColor: const Color(0xFF1F2937), // Matches app background dark tone
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
                    items: _resolutions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: widget.isTimelapseRunning ? null : (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedResolution = newValue);
                        widget.onResolutionChanged?.call(newValue);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Storage Location (Read-only)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Storage Location',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder_open, size: 14, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Text(
                      '/media/images',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Helper Widgets ---

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final bool isLoading;

  const _GlassButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor = Colors.blue,
    this.inactiveColor = Colors.green, // Default to green for "Start" actions
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: color.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
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
}

class _RepeatableButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _RepeatableButton({required this.icon, this.onPressed});

  @override
  State<_RepeatableButton> createState() => _RepeatableButtonState();
}

class _RepeatableButtonState extends State<_RepeatableButton> {
  Timer? _timer;

  void _startTimer() {
    if (widget.onPressed == null) return;
    
    // Initial press
    widget.onPressed!();
    
    // Repeat
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      widget.onPressed!();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startTimer(),
      onLongPressEnd: (_) => _stopTimer(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              color: Colors.white.withOpacity(0.05),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}