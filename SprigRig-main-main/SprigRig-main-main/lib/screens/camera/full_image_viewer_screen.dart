import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/timelapse_image.dart';
import '../../services/camera_service.dart';

class FullImageViewerScreen extends StatefulWidget {
  final List<TimelapseImage> images;
  final int initialIndex;
  final Function(List<String>)? onDelete;

  const FullImageViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
    this.onDelete,
  });

  @override
  State<FullImageViewerScreen> createState() => _FullImageViewerScreenState();
}

class _FullImageViewerScreenState extends State<FullImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _deleteCurrentImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Image?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this image?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final imagePath = widget.images[_currentIndex].path;
      await CameraService.instance.deleteImages([imagePath]);
      
      if (widget.onDelete != null) {
        widget.onDelete!([imagePath]);
      }

      setState(() {
        widget.images.removeAt(_currentIndex);
        if (_currentIndex >= widget.images.length) {
          _currentIndex = widget.images.length - 1;
        }
      });

      if (widget.images.isEmpty) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image View
          GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    File(widget.images[index].path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                    ),
                  ),
                );
              },
            ),
          ),

          // Top Bar
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black45,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  bottom: 8,
                  left: 8,
                  right: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: _deleteCurrentImage,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
