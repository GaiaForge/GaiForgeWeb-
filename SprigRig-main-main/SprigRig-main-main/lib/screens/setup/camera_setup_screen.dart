import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../models/camera.dart';
import '../../services/camera_service.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';

class CameraSetupScreen extends StatefulWidget {
  final Zone zone;

  const CameraSetupScreen({super.key, required this.zone});

  @override
  State<CameraSetupScreen> createState() => _CameraSetupScreenState();
}

class _CameraSetupScreenState extends State<CameraSetupScreen> {
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
      final cameras = await _cameraService.getZoneCameras(widget.zone.id!);
      setState(() {
        _cameras = cameras;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading cameras: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddEditCameraDialog([Camera? camera]) async {
    final isEditing = camera != null;
    final nameController = TextEditingController(text: camera?.name ?? '');
    bool isEnabled = camera?.enabled ?? true;

    List<Map<String, dynamic>> detectedCameras = [];
    bool isDetecting = false;
    Map<String, dynamic>? selectedCameraData;
    
    // If editing, try to find the current camera in detected list to pre-select?
    // Or just show current values. For simplicity, we'll focus on adding new cameras via detection.
    // If editing, we mainly allow renaming or disabling. Re-detecting would be like replacing.

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(isEditing ? 'Edit Camera' : 'Add Camera', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VirtualKeyboardTextField(
                  controller: nameController,
                  label: 'Camera Name',
                ),
                const SizedBox(height: 16),
                
                // Detection Section (Only for adding)
                if (!isEditing) ...[
                  if (detectedCameras.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isDetecting
                              ? null
                              : () async {
                                  setState(() => isDetecting = true);
                                  try {
                                    final cameras = await _cameraService.detectCameras();
                                    setState(() {
                                      detectedCameras = cameras;
                                      isDetecting = false;
                                      if (selectedCameraData == null && cameras.isNotEmpty) {
                                        selectedCameraData = cameras.first;
                                        if (nameController.text.isEmpty) {
                                          nameController.text = selectedCameraData!['name'] ?? 'Camera';
                                        }
                                      }
                                    });
                                    if (cameras.isEmpty && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('No cameras detected. Check connection.')),
                                      );
                                    }
                                  } catch (e) {
                                    setState(() => isDetecting = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error detecting cameras: $e')),
                                      );
                                    }
                                  }
                                },
                          icon: isDetecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.search),
                          label: Text(isDetecting ? 'Detecting...' : 'Detect Cameras'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),

                  // Detected Cameras List
                  if (detectedCameras.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select a Camera:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        ...detectedCameras.map((c) {
                          final isSelected = selectedCameraData == c;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCameraData = c;
                                if (nameController.text.isEmpty) {
                                  nameController.text = c['name'] ?? 'Camera';
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.pink.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                border: Border.all(
                                  color: isSelected ? Colors.pink : Colors.white.withOpacity(0.1),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.camera, color: isSelected ? Colors.pink : Colors.white54),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c['name'] ?? 'Unknown Camera',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${c['model'] ?? 'Unknown Model'} • Index: ${c['index'] ?? 0}',
                                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: Colors.pink),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                ],

                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enabled', style: TextStyle(color: Colors.white)),
                  value: isEnabled,
                  onChanged: (value) => setState(() => isEnabled = value),
                  activeColor: Colors.pink,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera name cannot be empty.')),
                  );
                  return;
                }

                if (!isEditing && selectedCameraData == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please detect and select a camera.')),
                  );
                  return;
                }

                try {
                  final newCamera = Camera(
                    id: camera?.id,
                    name: nameController.text,
                    devicePath: selectedCameraData?['devicePath'] ?? camera?.devicePath ?? '',
                    cameraIndex: camera?.cameraIndex ?? 0,
                    model: selectedCameraData?['model'] ?? camera?.model ?? '',
                    resolutionWidth: selectedCameraData?['resolutionWidth'] ?? camera?.resolutionWidth ?? 0,
                    resolutionHeight: selectedCameraData?['resolutionHeight'] ?? camera?.resolutionHeight ?? 0,
                    captureIntervalHours: camera?.captureIntervalHours ?? 1, // Default
                    enabled: isEnabled,
                    createdAt: camera?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
                    updatedAt: DateTime.now().millisecondsSinceEpoch,
                  );

                  if (isEditing) {
                    await _cameraService.updateCamera(newCamera);
                  } else {
                    final cameraId = await _cameraService.addCamera(newCamera);
                    await _cameraService.assignCameraToZone(cameraId, widget.zone.id!, 'default');
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    _loadCameras();
                  }
                } catch (e) {
                  debugPrint('Error saving camera: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving camera: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Save' : 'Add', style: const TextStyle(color: Colors.pinkAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCamera(Camera camera) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Camera', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete ${camera.name}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true && camera.id != null) {
      await _cameraService.deleteCamera(camera.id!);
      _loadCameras();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Camera Setup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: _cameras.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _cameras.length,
                              itemBuilder: (context, index) {
                                final camera = _cameras[index];
                                return Card(
                                  color: Colors.white.withOpacity(0.1),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: camera.enabled ? Colors.pink.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: camera.enabled ? Colors.pink : Colors.grey,
                                      ),
                                    ),
                                    title: Text(camera.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      '${camera.devicePath} • ${camera.resolutionWidth}x${camera.resolutionHeight}',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                          onPressed: () => _showAddEditCameraDialog(camera),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                                          onPressed: () => _deleteCamera(camera),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddEditCameraDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          const SizedBox(height: 8),
          Text(
            'Add a camera to monitor your grow',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
