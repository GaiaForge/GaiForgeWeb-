import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../models/timelapse_image.dart';
import '../../services/camera_service.dart';
import '../../widgets/common/app_background.dart';

class TimelapseViewerScreen extends StatefulWidget {
  final int cameraId;
  final int growId;
  final String cameraName;

  const TimelapseViewerScreen({
    super.key,
    required this.cameraId,
    required this.growId,
    required this.cameraName,
  });

  @override
  State<TimelapseViewerScreen> createState() => _TimelapseViewerScreenState();
}

class _TimelapseViewerScreenState extends State<TimelapseViewerScreen> {
  List<TimelapseImage> _images = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  
  // Playback controls
  bool _isPlaying = false;
  bool _isReverse = false;
  bool _wasPlaying = false; // Added for scrubbing
  double _playbackSpeed = 1.0; // 1x speed
  RangeValues? _rangeValues;
  Timer? _playbackTimer;
  
  static const List<double> _speedOptions = [0.5, 1.0, 2.0, 4.0, 8.0];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final images = await CameraService.instance.getTimelapseImages(
        widget.cameraId,
        widget.growId,
      );
      if (mounted) {
        setState(() {
          _images = images;
          _isLoading = false;
          // Start at the end (latest image)
          if (_images.isNotEmpty) {
            _currentIndex = _images.length - 1;
            _rangeValues = RangeValues(0, (_images.length - 1).toDouble());
          }
        });
        // Scroll to end after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && _images.isNotEmpty) {
            _scrollToIndex(_currentIndex);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading timelapse images: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    
    const itemWidth = 70.0; // 60 width + 10 margin
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _selectImage(int index) {
    setState(() {
      _currentIndex = index;
      // Pause if manually selecting while playing
      if (_isPlaying) _togglePlayback();
    });
    _scrollToIndex(index);
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _startPlayback();
    } else {
      _stopPlayback();
    }
  }

  void _startPlayback() {
    _stopPlayback(); // Cancel existing timer
    
    // Calculate interval based on speed (base 500ms)
    final intervalMs = (500 / _playbackSpeed).round();
    
    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) return;
      
      setState(() {
        // Check range bounds
        final start = _rangeValues?.start.round() ?? 0;
        final end = _rangeValues?.end.round() ?? (_images.length - 1);
        
        int nextIndex;
        if (_isReverse) {
          nextIndex = _currentIndex - 1;
          if (nextIndex < start) {
            nextIndex = end; // Loop back to end
          }
        } else {
          nextIndex = _currentIndex + 1;
          if (nextIndex > end) {
            nextIndex = start; // Loop back to start
          }
        }
        
        // Safety check if range changed mid-playback
        if (nextIndex < start) nextIndex = start;
        if (nextIndex > end) nextIndex = end;
        
        _currentIndex = nextIndex;
      });
      
      _scrollToIndex(_currentIndex);
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }

  void _updateSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    if (_isPlaying) {
      _startPlayback(); // Restart with new speed
    }
  }

  Future<void> _showExportDialog() async {
    if (_isPlaying) _togglePlayback();

    int selectedFps = 24;
    String selectedResolution = '1920x1080';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Export Timelapse', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create an MP4 video from the selected range.',
                style: TextStyle(color: Colors.white70),
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
      _exportVideo(selectedFps, selectedResolution);
    }
  }

  Future<void> _exportVideo(int fps, String resolution) async {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.amberAccent),
      ),
    );

    try {
      // Filter images based on range
      final start = _rangeValues?.start.round() ?? 0;
      final end = _rangeValues?.end.round() ?? (_images.length - 1);
      final selectedImages = _images.sublist(start, end + 1);

      final parts = resolution.split('x');
      final width = int.parse(parts[0]);
      final height = int.parse(parts[1]);

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final outputPath = '/home/sprigrig/SprigRig-main/media/timelapse_${widget.cameraName}_$timestamp.mp4';

      await CameraService.instance.exportTimelapse(
        images: selectedImages,
        outputPath: outputPath,
        fps: fps,
        width: width,
        height: height,
        onProgress: (progress) {
          // Update progress if we had a determinate progress bar
          // For now just showing circular indicator
        },
      );

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export saved to: $outputPath'),
            backgroundColor: Colors.green,
          ),
        );
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

  @override
  void dispose() {
    _stopPlayback();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'TIMELAPSE: ${widget.cameraName.toUpperCase()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
            : _images.isEmpty
                ? const Center(
                    child: Text(
                      'No images found',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : Column(
                    children: [
                      // Main Image Viewer
                      Expanded(
                        child: Center(
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.file(
                              File(_images[_currentIndex].path),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.broken_image, color: Colors.white54, size: 50),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      
                      // Info Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        color: Colors.black45,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMM d, yyyy').format(_images[_currentIndex].capturedAt),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              DateFormat('h:mm a').format(_images[_currentIndex].capturedAt),
                              style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_currentIndex + 1}/${_images.length}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),

                      // Playback Controls
                      Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            // Scrubbing Slider - FIRE Theme
                            if (_images.isNotEmpty)
                              SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: Colors.orange,
                                  inactiveTrackColor: Colors.red.shade900.withOpacity(0.3),
                                  thumbColor: Colors.amber,
                                  overlayColor: Colors.orange.withOpacity(0.3),
                                  trackHeight: 6,
                                  thumbShape: const _GlowingSunThumbShape(thumbRadius: 14),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
                                  activeTickMarkColor: Colors.amber.withOpacity(0.5),
                                  inactiveTickMarkColor: Colors.red.shade800.withOpacity(0.3),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.4),
                                        blurRadius: 15,
                                        spreadRadius: -5,
                                      ),
                                    ],
                                  ),
                                  child: Slider(
                                    value: _currentIndex.toDouble(),
                                    min: 0,
                                    max: (_images.length - 1).toDouble(),
                                    onChanged: (value) {
                                      setState(() {
                                        _currentIndex = value.round();
                                      });
                                      _scrollToIndex(_currentIndex);
                                    },
                                    onChangeStart: (value) {
                                      _wasPlaying = _isPlaying;
                                      if (_isPlaying) _stopPlayback();
                                    },
                                    onChangeEnd: (value) {
                                      if (_wasPlaying) _startPlayback();
                                    },
                                  ),
                                ),
                              ),

                            // Range Slider - ICE Theme
                            if (_images.length > 1)
                              Row(
                                children: [
                                  Text(
                                    '🔥',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                        activeTrackColor: Colors.cyan.shade400,
                                        inactiveTrackColor: Colors.indigo.shade900.withOpacity(0.4),
                                        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 12, elevation: 4),
                                        overlayColor: Colors.cyan.withOpacity(0.2),
                                        trackHeight: 5,
                                        rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.cyan.withOpacity(0.3),
                                              blurRadius: 12,
                                              spreadRadius: -4,
                                            ),
                                          ],
                                        ),
                                        child: RangeSlider(
                                          values: _rangeValues ?? const RangeValues(0, 1),
                                          min: 0,
                                          max: (_images.length - 1).toDouble(),
                                          divisions: _images.length > 1 ? _images.length - 1 : 1,
                                          onChanged: (values) {
                                            setState(() {
                                              _rangeValues = values;
                                              // If current index is out of new range, move it
                                              if (_currentIndex < values.start || _currentIndex > values.end) {
                                                _currentIndex = values.start.round();
                                                _scrollToIndex(_currentIndex);
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '❄️',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            
                            // Modern Playback Controls Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Speed Control - Pill shaped
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.speed_rounded, color: Colors.white.withOpacity(0.7), size: 18),
                                      const SizedBox(width: 6),
                                      DropdownButton<double>(
                                        value: _playbackSpeed,
                                        dropdownColor: Colors.grey[900],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                        underline: const SizedBox(),
                                        isDense: true,
                                        icon: Icon(Icons.expand_more_rounded, color: Colors.white.withOpacity(0.5), size: 18),
                                        items: _speedOptions.map((speed) {
                                          return DropdownMenuItem(
                                            value: speed,
                                            child: Text('${speed}×'),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value != null) _updateSpeed(value);
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Reverse Toggle - Modern circular
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isReverse ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                    border: Border.all(
                                      color: _isReverse ? Colors.amber.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.replay_rounded,
                                      color: _isReverse ? Colors.amberAccent : Colors.white.withOpacity(0.6),
                                      size: 22,
                                    ),
                                    tooltip: 'Reverse',
                                    onPressed: () {
                                      setState(() => _isReverse = !_isReverse);
                                    },
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Play/Pause - Large centered with glow
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(_isPlaying ? 0.5 : 0.3),
                                        blurRadius: 25,
                                        spreadRadius: -5,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _togglePlayback,
                                      borderRadius: BorderRadius.circular(35),
                                      child: Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.orange.shade400,
                                              Colors.deepOrange.shade600,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Step buttons
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.05),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.skip_next_rounded, color: Colors.white.withOpacity(0.6), size: 22),
                                    tooltip: 'Next Frame',
                                    onPressed: () {
                                      if (_currentIndex < _images.length - 1) {
                                        setState(() => _currentIndex++);
                                        _scrollToIndex(_currentIndex);
                                      }
                                    },
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Export Button - Modern pill
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.cyan.shade600.withOpacity(0.8),
                                        Colors.indigo.shade600.withOpacity(0.8),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.cyan.withOpacity(0.3),
                                        blurRadius: 12,
                                        spreadRadius: -4,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _showExportDialog,
                                      borderRadius: BorderRadius.circular(22),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.movie_creation_rounded, color: Colors.white, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              'EXPORT',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Thumbnail Strip
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          border: const Border(top: BorderSide(color: Colors.white10)),
                        ),
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            final isSelected = index == _currentIndex;
                            return GestureDetector(
                              onTap: () => _selectImage(index),
                              child: Container(
                                width: 60,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: isSelected
                                      ? Border.all(color: Colors.amber, width: 2)
                                      : Border.all(color: Colors.white24, width: 1),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        File(_images[index].thumbnailPath),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          // Fallback to main image if thumb missing
                                          return Image.file(
                                            File(_images[index].path),
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      ),
                                      if (isSelected)
                                        Container(color: Colors.amber.withOpacity(0.2)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

/// Custom thumb shape that looks like a glowing sun
class _GlowingSunThumbShape extends SliderComponentShape {
  final double thumbRadius;
  
  const _GlowingSunThumbShape({this.thumbRadius = 12.0});
  
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius * 2);
  }
  
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    
    // Outer glow layers (sun corona)
    for (int i = 4; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = Colors.orange.withOpacity(0.15 / i)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, thumbRadius * i * 0.5);
      canvas.drawCircle(center, thumbRadius * (1 + i * 0.4), glowPaint);
    }
    
    // Gradient sun body
    final sunGradient = RadialGradient(
      colors: [
        Colors.yellow.shade200,
        Colors.amber,
        Colors.orange,
        Colors.deepOrange,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
    
    final sunPaint = Paint()
      ..shader = sunGradient.createShader(
        Rect.fromCircle(center: center, radius: thumbRadius),
      );
    
    canvas.drawCircle(center, thumbRadius, sunPaint);
    
    // Inner bright core
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, thumbRadius * 0.4, corePaint);
  }
}
