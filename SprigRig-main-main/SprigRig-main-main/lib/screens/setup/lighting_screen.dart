import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/zone.dart';
import '../../models/lighting_schedule.dart';
import '../../models/environmental_control.dart';
import '../../services/database_helper.dart';
import 'astral_simulation_screen.dart';
import '../../services/interval_scheduler_service.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';

class LightingScreen extends StatefulWidget {
  final Zone zone;
  const LightingScreen({super.key, required this.zone});

  @override
  State<LightingScreen> createState() => _LightingScreenState();
}

class _LightingScreenState extends State<LightingScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  String _selectedMode = 'Fixed Interval'; // 'Fixed Interval' or 'Astral'
  List<LightingSchedule> _intervals = [];
  List<EnvironmentalControl> _lights = [];
  bool _isLoading = true;

  // Astral State
  String _syncMode = 'sunrise'; // 'sunrise', 'sunset', 'moon'
  double _startOffset = 0; // minutes
  double _endOffset = 0; // minutes

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load schedules
    final schedules = await _databaseHelper.getLightingSchedules(widget.zone.id);
    
    // Load settings
    final settings = await _databaseHelper.getLightingSettings(widget.zone.id);
    
    // Load lights
    final allControls = await _databaseHelper.getZoneControls(widget.zone.id!);
    final lights = allControls.where((c) => c.controlTypeId == 1 || c.controlTypeId == 2).toList();

    setState(() {
      _intervals = schedules;
      _lights = lights;
      if (settings != null) {
        _selectedMode = settings['mode'] ?? 'Fixed Interval';
        _syncMode = settings['sync_mode'] ?? 'sunrise';
        if (_syncMode == 'moon') _syncMode = 'sunrise';
        // Map database columns to logical start/end offsets
        _startOffset = ((settings['sunrise_offset'] as int?)?.toDouble() ?? 0.0).clamp(-120.0, 0.0);
        _endOffset = ((settings['sunset_offset'] as int?)?.toDouble() ?? 0.0).clamp(0.0, 120.0);
      }
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _databaseHelper.saveLightingSettings(
      widget.zone.id,
      _selectedMode,
      _syncMode,
      _startOffset.round(),
      _endOffset.round(),
    );
  }

  void _showIntervalDialog({int? index}) {
    final isEditing = index != null;
    final LightingSchedule? existingInterval = isEditing ? _intervals[index] : null;

    if (!isEditing && _intervals.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 10 intervals allowed.')),
      );
      return;
    }

    final nameController = TextEditingController(text: existingInterval?.name ?? '');
    TimeOfDay tempOn = existingInterval?.startTime ?? const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay tempOff = existingInterval?.endTime ?? const TimeOfDay(hour: 20, minute: 0);
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
                    isEditing ? 'Edit Interval' : 'Add Interval',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  VirtualKeyboardTextField(
                    controller: nameController,
                    label: 'Name',
                    hintText: 'Enter schedule name',
                    hintColor: nameHintColor,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLargeTimeCard(
                          'Start Time',
                          tempOn,
                          (t) => setDialogState(() => tempOn = t),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildLargeTimeCard(
                          'End Time',
                          tempOff,
                          (t) => setDialogState(() => tempOff = t),
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
                            color: isSelected ? Colors.amber : Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            dayName,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a name for the schedule'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
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

                            try {
                              final newInterval = LightingSchedule(
                                id: isEditing ? existingInterval!.id : const Uuid().v4(),
                                name: nameController.text,
                                startTime: tempOn,
                                endTime: tempOff,
                                days: tempDays,
                                isEnabled: existingInterval?.isEnabled ?? true,
                              );

                              await _databaseHelper.insertLightingSchedule(newInterval, widget.zone.id);
                              await IntervalSchedulerService().recalculate();
                              _loadData();
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              debugPrint('Error saving lighting schedule: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error saving schedule: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
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

  Widget _buildLargeTimeCard(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return GestureDetector(
      onTap: () async {
        final newTime = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.amber, // Header background color
                  onPrimary: Colors.black, // Header text color
                  surface: Color(0xFF1E293B), // Background color
                  onSurface: Colors.white, // Text color
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amber, // Button text color
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
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
              style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteInterval(int index) async {
    await _databaseHelper.deleteLightingSchedule(_intervals[index].id);
    await IntervalSchedulerService().recalculate();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Lighting'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.amber,
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
                                  _buildModeButton('Fixed Interval', Icons.timer),
                                  _buildModeButton('Astral', Icons.nightlight_round),
                                ],
                              ),
                            ),
                          ),

                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _selectedMode == 'Fixed Interval'
                                    ? _buildFixedIntervalView()
                                    : _buildAstralView(),
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

  Widget _buildDevicesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lights',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => _showDeviceDialog(),
                icon: const Icon(Icons.add_circle, color: Colors.amber, size: 32),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _lights.length,
            itemBuilder: (context, index) {
              final light = _lights[index];
              return Card(
                color: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.lightbulb, color: Colors.amber),
                  title: Text(light.name, style: const TextStyle(color: Colors.white)),
                  subtitle: FutureBuilder<List<dynamic>>(
                    future: _databaseHelper.getControlIoAssignments(light.id),
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
                    onPressed: () => _showDeviceDialog(light: light),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDeviceDialog({EnvironmentalControl? light}) async {
    final nameController = TextEditingController(text: light?.name ?? '');
    int? selectedChannelId;
    
    // If editing, load existing assignment
    if (light != null) {
      final assignments = await _databaseHelper.getControlIoAssignments(light.id);
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
                  light == null ? 'Add Light' : 'Edit Light',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                VirtualKeyboardTextField(
                  controller: nameController,
                  label: 'Light Name',
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
                          if (light == null) {
                            // Create new light
                            final newId = await _databaseHelper.createZoneControl(
                              widget.zone.id!,
                              1, // Grow Light type
                              nameController.text,
                            );
                            if (selectedChannelId != null) {
                              await _databaseHelper.assignControlIo(newId, selectedChannelId!, 'power');
                            }
                          } else {
                            // Update existing
                            await _databaseHelper.updateZoneControlName(light.id, nameController.text);
                            
                            // Update assignment
                            final assignments = await _databaseHelper.getControlIoAssignments(light.id);
                            if (assignments.isNotEmpty) {
                              if (selectedChannelId != null) {
                                await _databaseHelper.updateIoAssignment(assignments.first.id, channelId: selectedChannelId);
                              } else {
                                await _databaseHelper.deleteIoAssignment(assignments.first.id);
                              }
                            } else if (selectedChannelId != null) {
                              await _databaseHelper.assignControlIo(light.id, selectedChannelId!, 'power');
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
            color: isSelected ? Colors.amber.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: isSelected
                ? Border.all(color: Colors.amber.withOpacity(0.5))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.amber : Colors.white54,
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

  Widget _buildFixedIntervalView() {
    return Column(
      key: const ValueKey('Fixed'),
      children: [
        Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _intervals.isNotEmpty 
                ? 'Active (${_intervals.length}/10)' 
                : 'Inactive (${_intervals.length}/10)',
            style: TextStyle(
              color: _intervals.isNotEmpty ? Colors.green : Colors.redAccent, 
              fontSize: 18, 
              fontWeight: FontWeight.bold
            ),
          ),
          IconButton(
            onPressed: () => _showIntervalDialog(),
            icon: const Icon(Icons.add_circle, color: Colors.amber, size: 32),
          ),
        ],
      ),
        const SizedBox(height: 10),
        if (_intervals.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No intervals set.', style: TextStyle(color: Colors.white54)),
          )
        else
          ..._intervals.asMap().entries.map((entry) {
            final index = entry.key;
            final interval = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.light_mode, color: Colors.white70),
                            const SizedBox(width: 12),
                            Text(
                              interval.name,
                              style: TextStyle(
                                color: interval.isEnabled ? Colors.white : Colors.white38,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Switch(
                              value: interval.isEnabled,
                              activeColor: Colors.amber,
                              onChanged: (val) async {
                                final updated = LightingSchedule(
                                  id: interval.id,
                                  name: interval.name,
                                  startTime: interval.startTime,
                                  endTime: interval.endTime,
                                  days: interval.days,
                                  isEnabled: val,
                                );
                                await _databaseHelper.updateLightingSchedule(updated);
                                await IntervalSchedulerService().recalculate();
                                _loadData();
                              },
                            ),
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
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ON', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(
                              interval.startTime.format(context),
                              style: TextStyle(
                                color: interval.isEnabled ? Colors.amberAccent : Colors.white24,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.white24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('OFF', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(
                              interval.endTime.format(context),
                              style: TextStyle(
                                color: interval.isEnabled ? Colors.white70 : Colors.white24,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: interval.isEnabled ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Duration: ${_calculateDuration(interval.startTime, interval.endTime)}',
                            style: TextStyle(
                              color: interval.isEnabled ? Colors.amber : Colors.white24,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        _buildDayIndicators(interval.days, interval.isEnabled),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildDayIndicators(List<bool> days, bool isEnabled) {
    if (days.every((d) => d)) return Text('Daily', style: TextStyle(color: isEnabled ? Colors.white54 : Colors.white24, fontSize: 12));
    if (days.every((d) => !d)) return Text('Never', style: TextStyle(color: isEnabled ? Colors.white54 : Colors.white24, fontSize: 12));

    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: List.generate(7, (index) {
        if (!days[index]) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            dayNames[index],
            style: TextStyle(color: isEnabled ? Colors.amber : Colors.white24, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
      }),
    );
  }

  Widget _buildAstralView() {
    final isSunrise = _syncMode == 'sunrise';
    final isSunset = _syncMode == 'sunset';
    final eventName = isSunrise ? 'Sunrise' : 'Sunset';

    return Column(
      key: const ValueKey('Astral'),
      children: [
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sync Mode',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSyncOption(
                title: 'Sync with Sunrise',
                subtitle: 'Lights turn on at sunrise',
                value: 'sunrise',
                icon: Icons.wb_sunny_outlined,
              ),
              const SizedBox(height: 12),
              _buildSyncOption(
                title: 'Sync with Sunset',
                subtitle: 'Lights turn on at sunset',
                value: 'sunset',
                icon: Icons.wb_twilight,
              ),

            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AstralSimulationScreen(zone: widget.zone),
              ),
            ).then((_) => _loadData());
          },
          icon: const Icon(Icons.settings_suggest, color: Colors.black),
          label: const Text('CONFIGURE SIMULATION', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 16),
        _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$eventName Schedule',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // Start Offset Slider
                Text('Start Time (relative to $eventName)', style: const TextStyle(color: Colors.white70)),
                Slider(
                  value: _startOffset,
                  min: -120,
                  max: 0,
                  divisions: 24,
                  label: '${_startOffset.round()} min',
                  activeColor: Colors.amber,
                  onChanged: (v) {
                    setState(() => _startOffset = v);
                    _saveSettings();
                  },
                ),
                Text(
                  _startOffset == 0 
                      ? 'At $eventName' 
                      : '${_startOffset.abs().round()} min ${_startOffset < 0 ? 'before' : 'after'} $eventName',
                  style: const TextStyle(color: Colors.amberAccent),
                ),
                
                const SizedBox(height: 20),
                
                // End Offset Slider
                Text('End Time (relative to $eventName)', style: const TextStyle(color: Colors.white70)),
                Slider(
                  value: _endOffset,
                  min: 0,
                  max: 120,
                  divisions: 24,
                  label: '${_endOffset.round()} min',
                  activeColor: Colors.indigoAccent,
                  onChanged: (v) {
                    setState(() => _endOffset = v);
                    _saveSettings();
                  },
                ),
                Text(
                  _endOffset == 0 
                      ? 'At $eventName' 
                      : '${_endOffset.abs().round()} min ${_endOffset < 0 ? 'before' : 'after'} $eventName',
                  style: const TextStyle(color: Colors.amberAccent),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSyncOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _syncMode == value;
    return GestureDetector(
      onTap: () {
        setState(() => _syncMode = value);
        _saveSettings();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.amber.withOpacity(0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.amber : Colors.white54,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.amber, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDialogTimeRow(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        TextButton(
          onPressed: () async {
            final newTime = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (newTime != null) onChanged(newTime);
          },
          child: Text(
            time.format(context),
            style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  String _calculateDuration(TimeOfDay start, TimeOfDay end) {
    final startMin = start.hour * 60 + start.minute;
    final endMin = end.hour * 60 + end.minute;
    
    int diff = endMin - startMin;
    if (diff < 0) diff += 24 * 60; // Handle overnight

    final hours = diff ~/ 60;
    final minutes = diff % 60;
    
    return '${hours}h ${minutes > 0 ? '${minutes}m' : ''}';
  }
}
