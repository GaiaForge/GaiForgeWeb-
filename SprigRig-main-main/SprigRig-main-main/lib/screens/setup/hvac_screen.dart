import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/zone.dart';
import '../../models/hvac_schedule.dart';
import '../../models/environmental_control.dart';
import '../../services/database_helper.dart';
import '../../services/interval_scheduler_service.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';

class HvacScreen extends StatefulWidget {
  final Zone zone;
  const HvacScreen({super.key, required this.zone});

  @override
  State<HvacScreen> createState() => _HvacScreenState();
}

class _HvacScreenState extends State<HvacScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  String _selectedMode = 'Standard Fan'; // 'Standard Fan' or 'Variable Speed'
  String _controlMode = 'Schedule'; // 'Schedule', 'Always On', 'Always Off'
  double _alwaysOnSpeed = 100; // Speed for Always On mode
  
  List<HvacSchedule> _intervals = [];
  List<EnvironmentalControl> _fans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final schedules = await _databaseHelper.getHvacSchedules(widget.zone.id);
    final settings = await _databaseHelper.getHvacSettings(widget.zone.id);
    
    // Load fans
    final allControls = await _databaseHelper.getZoneControls(widget.zone.id!);
    final fans = allControls.where((c) => c.controlTypeId == 3 || c.controlTypeId == 4).toList();

    setState(() {
      _intervals = schedules;
      _fans = fans;
      if (settings != null) {
        _selectedMode = settings['mode'] as String;
        _controlMode = settings['control_mode'] as String;
        _alwaysOnSpeed = settings['always_on_speed'] as double;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _databaseHelper.saveHvacSettings(
      widget.zone.id,
      _selectedMode,
      _controlMode,
      _alwaysOnSpeed,
    );
  }

  void _showIntervalDialog({int? index}) {
    final isEditing = index != null;
    final HvacSchedule? existingInterval = isEditing ? _intervals[index] : null;

    if (!isEditing && _intervals.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 10 intervals allowed.')),
      );
      return;
    }

    final nameController = TextEditingController(text: existingInterval?.name ?? '');
    TimeOfDay tempStart = existingInterval?.startTime ?? const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay tempEnd = existingInterval?.endTime ?? const TimeOfDay(hour: 20, minute: 0);
    double tempSpeed = (existingInterval?.speed ?? 100).toDouble();
    List<bool> tempDays = existingInterval != null 
        ? List.from(existingInterval.days) 
        : List.filled(7, true);

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
                    isEditing ? 'Edit Fan Cycle' : 'Add Fan Cycle',
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
                  Row(
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
                        child: _buildLargeTimeCard(
                          'End Time',
                          tempEnd,
                          (t) => setDialogState(() => tempEnd = t),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedMode == 'Variable Speed') ...[
                    const SizedBox(height: 24),
                    const Text('Fan Speed', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: tempSpeed,
                            min: 0,
                            max: 100,
                            divisions: 100,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.white.withOpacity(0.1),
                            label: '${tempSpeed.round()}%',
                            onChanged: (value) {
                              setDialogState(() {
                                tempSpeed = value;
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 60,
                          alignment: Alignment.center,
                          child: Text(
                            '${tempSpeed.round()}%',
                            style: const TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Days Active', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            for (int i = 0; i < 7; i++) {
                              tempDays[i] = true;
                            }
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
                      final isSelected = tempDays[index];
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            tempDays[index] = !isSelected;
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

                            final newInterval = HvacSchedule(
                              id: isEditing ? existingInterval!.id : const Uuid().v4(),
                              name: nameController.text,
                              startTime: tempStart,
                              endTime: tempEnd,
                              speed: tempSpeed.round(),
                              days: tempDays,
                            );

                            await _databaseHelper.insertHvacSchedule(newInterval, widget.zone.id);
                            await IntervalSchedulerService().recalculate();
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

  void _deleteInterval(int index) async {
    await _databaseHelper.deleteHvacSchedule(_intervals[index].id);
    await IntervalSchedulerService().recalculate();
    _loadData();
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

  Widget _buildDayIndicators(List<bool> days) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (index) {
        if (!days[index]) return const SizedBox.shrink();
        final dayName = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            dayName,
            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('HVAC'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'Controls'),
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
                          // Mode Selector (Standard vs Variable)
                          Container(
                            margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedMode = 'Standard Fan');
                                      _saveSettings();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _selectedMode == 'Standard Fan' ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: _selectedMode == 'Standard Fan' ? Border.all(color: Colors.blue.withOpacity(0.5)) : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'Standard Fan',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedMode = 'Variable Speed');
                                      _saveSettings();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _selectedMode == 'Variable Speed' ? Colors.purple.withOpacity(0.3) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: _selectedMode == 'Variable Speed' ? Border.all(color: Colors.purple.withOpacity(0.5)) : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'Variable Speed',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Control Mode Selector (Schedule, Always On, Always Off)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Row(
                              children: [
                                _buildControlModeButton('Schedule', Icons.calendar_month),
                                const SizedBox(width: 12),
                                _buildControlModeButton('Always On', Icons.power),
                                const SizedBox(width: 12),
                                _buildControlModeButton('Always Off', Icons.power_off),
                              ],
                            ),
                          ),

                          // Content based on Control Mode
                          Expanded(
                            child: _buildContent(),
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

  Widget _buildDevicesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fans',
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
            itemCount: _fans.length,
            itemBuilder: (context, index) {
              final fan = _fans[index];
              return Card(
                color: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.wind_power, color: Colors.blue),
                  title: Text(fan.name, style: const TextStyle(color: Colors.white)),
                  subtitle: FutureBuilder<List<dynamic>>(
                    future: _databaseHelper.getControlIoAssignments(fan.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No Output Assigned', style: TextStyle(color: Colors.orange));
                      }
                      final assignment = snapshot.data!.first;
                      return Text('Output: ${assignment.channelName}', style: const TextStyle(color: Colors.green));
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    onPressed: () => _showDeviceDialog(fan: fan),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDeviceDialog({EnvironmentalControl? fan}) async {
    final nameController = TextEditingController(text: fan?.name ?? '');
    int? selectedChannelId;
    
    // If editing, load existing assignment
    if (fan != null) {
      final assignments = await _databaseHelper.getControlIoAssignments(fan.id);
      if (assignments.isNotEmpty) {
        selectedChannelId = assignments.first.ioChannelId;
      }
    }

    // Load available channels
    final allChannels = await _databaseHelper.getAllIoChannels();
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fan == null ? 'Add Fan' : 'Edit Fan',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                VirtualKeyboardTextField(
                  controller: nameController,
                  label: 'Fan Name',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedChannelId,
                  decoration: const InputDecoration(
                    labelText: 'Assign Output',
                    filled: true,
                    fillColor: Colors.black26,
                  ),
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  items: allChannels.map((c) {
                    final isAssigned = c.isAssigned && c.id != selectedChannelId;
                    return DropdownMenuItem(
                      value: c.id,
                      enabled: !isAssigned,
                      child: Text(
                        '${c.name} ${isAssigned ? '(Used by ${c.assignedTo ?? "Unknown"})' : ''}',
                        style: TextStyle(color: isAssigned ? Colors.grey : Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedChannelId = val),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isNotEmpty) {
                          if (fan == null) {
                            // Create new fan
                            final newId = await _databaseHelper.createZoneControl(
                              widget.zone.id!,
                              3, // Exhaust Fan type
                              nameController.text,
                            );
                            if (selectedChannelId != null) {
                              await _databaseHelper.assignControlIo(newId, selectedChannelId!, 'power');
                            }
                          } else {
                            // Update existing
                            await _databaseHelper.updateZoneControlName(fan.id, nameController.text);
                            
                            // Update assignment
                            final assignments = await _databaseHelper.getControlIoAssignments(fan.id);
                            if (assignments.isNotEmpty) {
                              if (selectedChannelId != null) {
                                await _databaseHelper.updateIoAssignment(assignments.first.id, channelId: selectedChannelId);
                              } else {
                                await _databaseHelper.deleteIoAssignment(assignments.first.id);
                              }
                            } else if (selectedChannelId != null) {
                              await _databaseHelper.assignControlIo(fan.id, selectedChannelId!, 'power');
                            }
                          }
                          _loadData();
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlModeButton(String mode, IconData icon) {
    final isSelected = _controlMode == mode;
    Color color;
    if (mode == 'Schedule') color = Colors.blue;
    else if (mode == 'Always On') color = Colors.green;
    else color = Colors.red;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _controlMode = mode);
          _saveSettings();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.white.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.white70, size: 28),
              const SizedBox(height: 8),
              Text(
                mode,
                style: TextStyle(
                  color: isSelected ? color : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_controlMode == 'Always Off') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.power_off, size: 80, color: Colors.red.withOpacity(0.5)),
            const SizedBox(height: 20),
            const Text(
              'Ventilation is OFF',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'System is manually disabled',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_controlMode == 'Always On') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wind_power, size: 80, color: Colors.green.withOpacity(0.5)),
            const SizedBox(height: 20),
            const Text(
              'Ventilation is ON',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'System is manually enabled',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
            ),
            if (_selectedMode == 'Variable Speed') ...[
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    const Text('Manual Speed', style: TextStyle(color: Colors.white70, fontSize: 18)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _alwaysOnSpeed,
                            min: 0,
                            max: 100,
                            divisions: 100,
                            activeColor: Colors.green,
                            inactiveColor: Colors.white.withOpacity(0.1),
                            label: '${_alwaysOnSpeed.round()}%',
                            onChanged: (value) {
                              setState(() {
                                _alwaysOnSpeed = value;
                              });
                            },
                            onChangeEnd: (value) => _saveSettings(),
                          ),
                        ),
                        Container(
                          width: 60,
                          alignment: Alignment.center,
                          child: Text(
                            '${_alwaysOnSpeed.round()}%',
                            style: const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Schedule Mode
    return Column(
      children: [
        // Status Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _intervals.isNotEmpty 
                    ? 'Active (${_intervals.length}/10)' 
                    : 'Inactive (${_intervals.length}/10)',
                style: TextStyle(
                  color: _intervals.isNotEmpty ? Colors.green : Colors.redAccent, 
                  fontSize: 20, 
                  fontWeight: FontWeight.bold
                ),
              ),
              IconButton(
                onPressed: () => _showIntervalDialog(),
                icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 32),
              ),
            ],
          ),
        ),

        // List of Intervals
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: _intervals.length,
            itemBuilder: (context, index) {
              final interval = _intervals[index];
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
                            leading: Icon(
                              Icons.wind_power, 
                              color: _selectedMode == 'Variable Speed' ? Colors.purpleAccent : Colors.blueAccent
                            ),
                            title: Text(
                              interval.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${interval.startTime.format(context)} - ${interval.endTime.format(context)}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                ),
                                if (_selectedMode == 'Variable Speed')
                                  Text(
                                    'Speed: ${interval.speed}%',
                                    style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white70),
                                  onPressed: () => _showIntervalDialog(index: index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _deleteInterval(index),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Row(
                              children: [
                                _buildDayIndicators(interval.days),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
