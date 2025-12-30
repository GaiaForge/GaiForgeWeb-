import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/zone.dart';
import '../../models/aeration_schedule.dart';
import '../../models/environmental_control.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';
import '../../widgets/common/duration_picker.dart';

class AerationScreen extends StatefulWidget {
  final Zone zone;
  const AerationScreen({super.key, required this.zone});

  @override
  State<AerationScreen> createState() => _AerationScreenState();
}

class _AerationScreenState extends State<AerationScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  String _selectedMode = 'Scheduled'; // 'Scheduled' or 'Always On'
  List<AerationSchedule> _schedules = [];
  List<EnvironmentalControl> _pumps = [];
  bool _isLoading = true;
  bool _alwaysOnEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load schedules
    final schedulesData = await _databaseHelper.getAerationSchedules(widget.zone.id!);
    final schedules = schedulesData.map((s) => AerationSchedule.fromMap(s)).toList();
    
    // Load air pumps (assuming control type 7 or similar, adjusting based on available types)
    // For now, we'll look for controls with 'pump' or 'air' in the name or description if specific type isn't defined
    // Or we can reuse water pump type (5) if user assigns it for air
    final allControls = await _databaseHelper.getZoneControls(widget.zone.id!);
    final pumps = allControls.where((c) => 
      c.name.toLowerCase().contains('air') || 
      c.name.toLowerCase().contains('pump') ||
      c.controlTypeId == 5 // Water pump type as fallback
    ).toList();

    // Load settings
    final settings = await _databaseHelper.getAerationSettings(widget.zone.id!);
    
    setState(() {
      _schedules = schedules;
      _pumps = pumps;
      if (settings != null) {
        _selectedMode = settings['mode'] ?? 'Scheduled';
        _alwaysOnEnabled = (settings['always_on_enabled'] as int?) == 1;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _databaseHelper.saveAerationSettings(
      widget.zone.id!,
      _selectedMode,
      _alwaysOnEnabled,
    );
  }

  void _showScheduleDialog({int? index}) {
    final isEditing = index != null;
    final AerationSchedule? existingSchedule = isEditing ? _schedules[index] : null;

    if (!isEditing && _schedules.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 10 schedules allowed.')),
      );
      return;
    }

    final nameController = TextEditingController(text: existingSchedule?.name ?? '');
    Duration tempDuration = existingSchedule != null 
        ? Duration(seconds: existingSchedule.durationSeconds) 
        : const Duration(minutes: 15);
    
    // Parse start time string "HH:MM"
    TimeOfDay tempStart = const TimeOfDay(hour: 8, minute: 0);
    if (existingSchedule != null) {
      final parts = existingSchedule.startTime.split(':');
      tempStart = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    List<int> tempDays = existingSchedule != null 
        ? List.from(existingSchedule.days) 
        : [0, 1, 2, 3, 4, 5, 6]; // All days by default
        
    int? tempPumpId = existingSchedule?.pumpId;
    
    // Default to first pump if adding new and pumps exist
    if (tempPumpId == null && _pumps.isNotEmpty && !isEditing) {
      tempPumpId = _pumps.first.id;
    }

    // Validation State
    Color nameHintColor = Colors.white54;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEditing ? 'Edit Aeration Cycle' : 'Add Aeration Cycle',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  VirtualKeyboardTextField(
                    controller: nameController,
                    label: 'Name',
                    hintText: 'Enter cycle name',
                    hintColor: nameHintColor,
                  ),
                  const SizedBox(height: 24),
                  if (_pumps.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      value: tempPumpId,
                      decoration: InputDecoration(
                        labelText: 'Select Air Pump',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      items: _pumps.map((pump) {
                        return DropdownMenuItem(
                          value: pump.id,
                          child: Text(pump.name),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => tempPumpId = val),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildLargeTimeCard(
                          'Start Time',
                          tempStart,
                          (t) => setDialogState(() => tempStart = t),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Duration', style: TextStyle(color: Colors.white54, fontSize: 14)),
                            const SizedBox(height: 8),
                            DurationPicker(
                              initialDuration: tempDuration,
                              onDurationChanged: (d) => setDialogState(() => tempDuration = d),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Days Active', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            tempDays = [0, 1, 2, 3, 4, 5, 6];
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Daily', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final dayName = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
                      final isSelected = tempDays.contains(index);
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            if (isSelected) {
                              tempDays.remove(index);
                            } else {
                              tempDays.add(index);
                            }
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            dayName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.isEmpty) {
                              // Blink Animation
                              for (int i = 0; i < 2; i++) {
                                setDialogState(() => nameHintColor = Colors.redAccent);
                                await Future.delayed(const Duration(milliseconds: 200));
                                if (!context.mounted) return;
                                setDialogState(() => nameHintColor = Colors.white54);
                                await Future.delayed(const Duration(milliseconds: 200));
                                if (!context.mounted) return;
                              }
                              return;
                            }

                            final newSchedule = AerationSchedule(
                              id: isEditing ? existingSchedule!.id : const Uuid().v4(),
                              zoneId: widget.zone.id!,
                              name: nameController.text,
                              startTime: '${tempStart.hour}:${tempStart.minute.toString().padLeft(2, '0')}',
                              durationSeconds: tempDuration.inSeconds,
                              days: tempDays,
                              pumpId: tempPumpId,
                            );

                            await _databaseHelper.saveAerationSchedule(newSchedule.toMap());
                            _loadData();
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isEditing ? 'Save' : 'Add', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours} hr';
    if (d.inMinutes > 0) return '${d.inMinutes} min';
    return '${d.inSeconds} sec';
  }

  Widget _buildLargeTimeCard(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return GestureDetector(
      onTap: () async {
        final newTime = await showTimePicker(context: context, initialTime: time);
        if (newTime != null) onChanged(newTime);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              time.format(context),
              style: const TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSchedule(int index) async {
    await _databaseHelper.deleteAerationSchedule(_schedules[index].id);
    _loadData();
  }

  // Device Management Methods
  Future<void> _showDeviceDialog({EnvironmentalControl? device}) async {
    final isEditing = device != null;
    final nameController = TextEditingController(text: device?.name ?? '');
    final ioChannels = await _databaseHelper.getAllIoChannels();
    
    // Find currently assigned channel for this device if editing
    int? selectedChannelId;
    if (isEditing) {
      // This logic would need to be expanded to query control_io_assignments
      // For now, we'll just allow creating new controls
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(isEditing ? 'Edit Air Pump' : 'Add Air Pump', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VirtualKeyboardTextField(
                controller: nameController,
                label: 'Device Name',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedChannelId,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Assign Output Channel',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                ),
                items: ioChannels.map((c) {
                  final isAssigned = c.isAssigned && (isEditing ? false : true); // Simplified logic
                  return DropdownMenuItem(
                    value: c.id,
                    enabled: !isAssigned,
                    child: Text(
                      '${c.name} ${isAssigned ? '(Used by ${c.assignedTo ?? "Unknown"})' : ''}',
                      style: TextStyle(color: isAssigned ? Colors.grey : Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedChannelId = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  if (isEditing) {
                    // Update existing control
                  } else {
                    // Create new control (Type 5 for Pump, or we could add a new type for Air Pump)
                    final id = await _databaseHelper.createZoneControl(widget.zone.id!, 5, nameController.text);
                    
                    if (selectedChannelId != null) {
                      await _databaseHelper.assignControlIo(id, selectedChannelId!, 'on_off');
                    }
                  }
                  _loadData();
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDevice(EnvironmentalControl device) async {
    // Logic to delete device and unassign IO
    // await _databaseHelper.deleteZoneControl(device.id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Aeration'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'Schedules'),
              Tab(text: 'Devices'),
            ],
          ),
        ),
        body: AppBackground(
          child: SafeArea(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      Column(
                        children: [
                          // Mode Selector
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  _buildModeButton('Scheduled', Icons.timer),
                                  _buildModeButton('Always On', Icons.power),
                                ],
                              ),
                            ),
                          ),

                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _selectedMode == 'Scheduled'
                                    ? _buildScheduledView()
                                    : _buildAlwaysOnView(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildDevicesTab(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String mode, IconData icon) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedMode = mode);
          _saveSettings();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: isSelected
                ? Border.all(color: Colors.blue.withOpacity(0.5))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blue : Colors.white54,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                mode,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduledView() {
    return Column(
      key: const ValueKey('Scheduled'),
      children: [
        // Header / Summary
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.air, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status: Active',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_schedules.length} cycles scheduled',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _schedules.isNotEmpty 
                  ? 'Active (${_schedules.length}/10)' 
                  : 'Inactive (${_schedules.length}/10)',
              style: TextStyle(
                color: _schedules.isNotEmpty ? Colors.green : Colors.redAccent, 
                fontSize: 20, 
                fontWeight: FontWeight.bold
              ),
            ),
            IconButton(
              onPressed: () => _showScheduleDialog(),
              icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 32),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (_schedules.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No aeration cycles set.', style: TextStyle(color: Colors.white54)),
          )
        else
          ..._schedules.asMap().entries.map((entry) {
            final index = entry.key;
            final schedule = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.timer, color: Colors.white70),
                          title: Text(
                            schedule.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${schedule.startTime} • ${_formatDuration(Duration(seconds: schedule.durationSeconds))}',
                                style: TextStyle(color: Colors.white.withOpacity(0.5)),
                              ),
                              if (schedule.pumpId != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Pump: ${_pumps.firstWhere((p) => p.id == schedule.pumpId, orElse: () => _pumps.isNotEmpty ? _pumps.first : EnvironmentalControl(id: 0, zoneId: 0, controlTypeId: 0, name: 'Unknown', enabled: false)).name}',
                                  style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white70),
                                onPressed: () => _showScheduleDialog(index: index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _deleteSchedule(index),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            children: [
                              _buildDayIndicators(schedule.days),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAlwaysOnView() {
    return Column(
      key: const ValueKey('AlwaysOn'),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.power, size: 64, color: Colors.blueAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Always On Mode',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Air pumps will run continuously.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SwitchListTile(
                    title: const Text('Enable Always On', style: TextStyle(color: Colors.white, fontSize: 18)),
                    value: _alwaysOnEnabled,
                    activeColor: Colors.blueAccent,
                    onChanged: (val) {
                      setState(() => _alwaysOnEnabled = val);
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Air Pumps',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => _showDeviceDialog(),
                icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 32),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _pumps.length,
            itemBuilder: (context, index) {
              final pump = _pumps[index];
              return Card(
                color: Colors.white.withOpacity(0.05),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.air, color: Colors.blueAccent),
                  title: Text(pump.name, style: const TextStyle(color: Colors.white)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteDevice(pump),
                  ),
                  onTap: () => _showDeviceDialog(device: pump),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayIndicators(List<int> days) {
    return Row(
      children: List.generate(7, (index) {
        final dayName = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
        final isActive = days.contains(index);
        return Container(
          margin: const EdgeInsets.only(right: 4),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            dayName,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }),
    );
  }
}
