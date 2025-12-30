import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/zone.dart';
import '../../models/sensor_hub.dart';
import '../../models/irrigation_schedule.dart';
import '../../models/environmental_control.dart';
import '../../models/sensor.dart';
import '../../services/database_helper.dart';
import '../../services/interval_scheduler_service.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';
import '../../widgets/common/duration_picker.dart';
import '../../widgets/reservoir_tank_widget.dart'; // NEW
import 'sensing_screen.dart';

class IrrigationScreen extends StatefulWidget {
  final Zone zone;
  const IrrigationScreen({super.key, required this.zone});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<IrrigationSchedule> _intervals = [];
  List<EnvironmentalControl> _pumps = [];
  List<SensorHub> _hubs = [];
  bool _isLoading = true;
  String _growModeName = '';
  
  // Reservoir Settings
  double _targetWaterLevel = 50.0;
  int? _refillPumpId;
  int? _upperFloatSensorId;
  int? _lowerFloatSensorId;
  
  // New Settings
  String _sensingMethod = 'digital'; // 'digital' or 'analog'
  int? _analogSensorId;

  // Temporary state for Hub/Input selection
  int? _upperHubId;
  int? _upperChannelId;
  int? _lowerHubId;
  int? _lowerChannelId;
  
  // Analog selection
  int? _analogHubId;
  int? _analogChannelId;

  bool _isReservoirMode = false;
  List<Sensor> _sensors = []; // Changed dynamic to Sensor

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    await _loadGrowInfo();

    // Load schedules
    final schedules = await _databaseHelper.getIrrigationSchedules(widget.zone.id);
    
    // Load pumps
    final allControls = await _databaseHelper.getZoneControls(widget.zone.id!);
    final pumps = allControls.where((c) => c.controlTypeId == 5 || c.controlTypeId == 6).toList();

    // Load sensors
    final sensors = await _databaseHelper.getZoneSensors(widget.zone.id!);
    
    // Load Hubs
    final hubs = await _databaseHelper.getSensorHubs();

    // Load settings
    final settings = await _databaseHelper.getIrrigationSettings(widget.zone.id);
    
    setState(() {
      _intervals = schedules;
      _pumps = pumps;
      _sensors = sensors;
      _hubs = hubs;
      
      if (settings != null) {
        _targetWaterLevel = (settings['target_water_level'] as num?)?.toDouble() ?? 50.0;
        _sensingMethod = settings['sensing_method'] as String? ?? 'digital';
        
        // Validate IDs exist in loaded lists
        final savedRefillId = settings['refill_pump_id'] as int?;
        if (savedRefillId != null && pumps.any((p) => p.id == savedRefillId)) {
          _refillPumpId = savedRefillId;
        } else {
          _refillPumpId = null;
        }

        final savedUpperId = settings['upper_float_sensor_id'] as int?;
        if (savedUpperId != null) {
          _upperFloatSensorId = savedUpperId;
          final sensor = sensors.firstWhere((s) => s.id == savedUpperId, orElse: () => Sensor(id: -1, zoneId: 0, sensorType: '', name: '', enabled: false, createdAt: 0, updatedAt: 0));
          if (sensor.id != -1) {
            _upperHubId = sensor.hubId;
            _upperChannelId = sensor.inputChannel;
          }
        } else {
          _upperFloatSensorId = null;
        }

        final savedLowerId = settings['lower_float_sensor_id'] as int?;
        if (savedLowerId != null) {
          _lowerFloatSensorId = savedLowerId;
          final sensor = sensors.firstWhere((s) => s.id == savedLowerId, orElse: () => Sensor(id: -1, zoneId: 0, sensorType: '', name: '', enabled: false, createdAt: 0, updatedAt: 0));
          if (sensor.id != -1) {
            _lowerHubId = sensor.hubId;
            _lowerChannelId = sensor.inputChannel;
          }
        } else {
          _lowerFloatSensorId = null;
        }

        final savedAnalogId = settings['analog_sensor_id'] as int?;
        if (savedAnalogId != null) {
          _analogSensorId = savedAnalogId;
          final sensor = sensors.firstWhere((s) => s.id == savedAnalogId, orElse: () => Sensor(id: -1, zoneId: 0, sensorType: '', name: '', enabled: false, createdAt: 0, updatedAt: 0));
          if (sensor.id != -1) {
            _analogHubId = sensor.hubId;
            _analogChannelId = sensor.inputChannel;
          }
        } else {
          _analogSensorId = null;
        }
      }
      _isLoading = false;
    });
  }

  Future<void> _loadGrowInfo() async {
    if (widget.zone.growId != null) {
      final grow = await _databaseHelper.getGrow(widget.zone.growId!);
      if (grow != null && grow.growModeId != null) {
        final modeName = await _databaseHelper.getGrowModeName(grow.growModeId!);
        if (modeName != null) {
          setState(() {
            _growModeName = modeName;
            _isReservoirMode = _checkIfHydroponic(modeName);
          });
        }
      }
    }
  }

  bool _checkIfHydroponic(String modeName) {
    final mode = modeName.toLowerCase();
    return mode.contains('hydro') || 
           mode.contains('aero') || 
           mode.contains('dwc') || 
           mode.contains('nft') || 
           mode.contains('ebb');
  }

  Future<void> _saveReservoirSettings() async {
    // Helper to find or create sensor
    Future<int?> getOrCreateSensorId(int? hubId, int? channelId, String nameSuffix) async {
      if (hubId == null || channelId == null) return null;
      
      // Check if sensor exists
      try {
        final existingSensor = _sensors.firstWhere(
          (s) => s.hubId == hubId && s.inputChannel == channelId,
        );
        return existingSensor.id;
      } catch (e) {
        // Not found, create new
      }

      // Create new sensor
      final newSensor = Sensor(
        id: 0, // Auto-increment
        zoneId: widget.zone.id!,
        sensorType: 'water_level',
        name: 'Reservoir $nameSuffix',
        enabled: true,
        hubId: hubId,
        inputChannel: channelId,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      
      return await _databaseHelper.createSensor(newSensor);
    }

    final upperId = await getOrCreateSensorId(_upperHubId, _upperChannelId, 'High Float');
    final lowerId = await getOrCreateSensorId(_lowerHubId, _lowerChannelId, 'Low Float');

    await _databaseHelper.saveIrrigationSettings(
      widget.zone.id!,
      'Reservoir', // Mode
      'None', // Sync Mode
      0, // Sunrise Offset
      0, // Sunset Offset
      targetWaterLevel: _targetWaterLevel,
      refillPumpId: _refillPumpId,
      upperFloatSensorId: upperId,
      lowerFloatSensorId: lowerId,
    );
    
    // Reload to get new sensor IDs
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservoir settings saved')),
      );
    }
  }

  Widget _buildHubInputSelector({
    required String label,
    required int? selectedHubId,
    required int? selectedChannelId,
    required Function(int?) onHubChanged,
    required Function(int?) onChannelChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedHubId,
                    isExpanded: true,
                    hint: const Text('Select Hub', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('None'),
                      ),
                      ..._hubs.map((hub) {
                        return DropdownMenuItem<int>(
                          value: hub.id,
                          child: Text(hub.name),
                        );
                      }),
                    ],
                    onChanged: onHubChanged,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedChannelId,
                    isExpanded: true,
                    hint: const Text('Input (DI)', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: selectedHubId == null 
                      ? [] 
                      : List.generate(4, (index) { // Assuming 4 DI channels for now, ideally fetch from hub capabilities
                          final channel = index + 1;
                          return DropdownMenuItem<int>(
                            value: channel,
                            child: Text('DI $channel'),
                          );
                        }),
                    onChanged: onChannelChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showIntervalDialog({int? index}) {
    final isEditing = index != null;
    final IrrigationSchedule? existingInterval = isEditing ? _intervals[index] : null;

    if (!isEditing && _intervals.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 10 intervals allowed.')),
      );
      return;
    }

    final nameController = TextEditingController(text: existingInterval?.name ?? '');
    Duration tempDuration = existingInterval?.duration ?? const Duration(minutes: 15);
    TimeOfDay tempStart = existingInterval?.startTime ?? const TimeOfDay(hour: 8, minute: 0);
    List<bool> tempDays = existingInterval != null 
        ? List.from(existingInterval.days) 
        : List.filled(7, true);
    int? tempPumpId = existingInterval?.pumpId;
    
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
                    isEditing ? 'Edit Watering Cycle' : 'Add Watering Cycle',
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
                        labelText: 'Select Pump',
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

                            final newInterval = IrrigationSchedule(
                              id: isEditing ? existingInterval!.id : const Uuid().v4(),
                              name: nameController.text,
                              startTime: tempStart,
                              duration: tempDuration,

                              days: tempDays,
                              pumpId: tempPumpId,
                              isEnabled: existingInterval?.isEnabled ?? true,
                            );

                            await _databaseHelper.insertIrrigationSchedule(newInterval, widget.zone.id);
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

  void _deleteInterval(int index) async {
    await _databaseHelper.deleteIrrigationSchedule(_intervals[index].id);
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
          title: Text(_isReservoirMode ? 'Reservoir Control' : 'Irrigation'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: _isReservoirMode ? 'Settings' : 'Schedules'),
              const Tab(text: 'Devices'),
            ],
          ),
        ),
        body: AppBackground(
          child: SafeArea(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      _isReservoirMode ? _buildReservoirControlTab() : _buildFixedScheduleView(),
                      _buildDevicesTab(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }



  Widget _buildReservoirControlTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Tank Animation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade900.withOpacity(0.6), Colors.blue.shade800.withOpacity(0.3)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                ReservoirTankWidget(
                  levelPercent: _sensingMethod == 'analog' ? 0.65 : 0.8, // Mock value for preview
                  targetPercent: _sensingMethod == 'analog' ? _targetWaterLevel / 100 : null,
                  height: 120,
                  width: 80,
                  waterColor: Colors.blueAccent,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reservoir Status',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _sensingMethod == 'analog' 
                            ? 'Level: 65% (Mock)\nTarget: ${_targetWaterLevel.toInt()}%' 
                            : 'Status: OK\nRefill: Idle',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Sensing Method Toggle
          const Text(
            'Sensing Method',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _sensingMethod = 'digital'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _sensingMethod == 'digital' ? Colors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Dual Float Switches',
                        style: TextStyle(
                          color: _sensingMethod == 'digital' ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _sensingMethod = 'analog'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _sensingMethod == 'analog' ? Colors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Analog Level Sensor',
                        style: TextStyle(
                          color: _sensingMethod == 'analog' ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Configuration Area
          AnimatedCrossFade(
            firstChild: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHubInputSelector(
                    label: 'Upper Float Sensor (Stop Fill)',
                    selectedHubId: _upperHubId,
                    selectedChannelId: _upperChannelId,
                    onHubChanged: (val) => setState(() {
                      _upperHubId = val;
                      _upperChannelId = null;
                    }),
                    onChannelChanged: (val) => setState(() => _upperChannelId = val),
                  ),
                  const SizedBox(height: 24),
                  _buildHubInputSelector(
                    label: 'Lower Float Sensor (Start Fill)',
                    selectedHubId: _lowerHubId,
                    selectedChannelId: _lowerChannelId,
                    onHubChanged: (val) => setState(() {
                      _lowerHubId = val;
                      _lowerChannelId = null;
                    }),
                    onChannelChanged: (val) => setState(() => _lowerChannelId = val),
                  ),
                ],
              ),
            ),
            secondChild: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHubInputSelector(
                    label: 'Analog Level Sensor (0-10V / 4-20mA)',
                    selectedHubId: _analogHubId,
                    selectedChannelId: _analogChannelId,
                    onHubChanged: (val) => setState(() {
                      _analogHubId = val;
                      _analogChannelId = null;
                    }),
                    onChannelChanged: (val) => setState(() => _analogChannelId = val),
                  ),
                  const SizedBox(height: 24),
                  const Text('Target Water Level', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.blueAccent,
                            inactiveTrackColor: Colors.blueAccent.withOpacity(0.3),
                            thumbColor: Colors.white,
                            overlayColor: Colors.blueAccent.withOpacity(0.2),
                          ),
                          child: Slider(
                            value: _targetWaterLevel,
                            min: 0,
                            max: 100,
                            divisions: 100,
                            label: '${_targetWaterLevel.toInt()}%',
                            onChanged: (val) => setState(() => _targetWaterLevel = val),
                          ),
                        ),
                      ),
                      Container(
                        width: 50,
                        alignment: Alignment.center,
                        child: Text(
                          '${_targetWaterLevel.toInt()}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'The system will maintain this level by filling when below and draining when above (if drain pump configured).',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            crossFadeState: _sensingMethod == 'digital' ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),

          const SizedBox(height: 32),

          const Text(
            'Refill Pump',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _refillPumpId,
                isExpanded: true,
                hint: const Text('Select Refill Pump', style: TextStyle(color: Colors.white54)),
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('None'),
                  ),
                  ..._pumps.map((pump) {
                    return DropdownMenuItem(
                      value: pump.id,
                      child: Text(pump.name),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() => _refillPumpId = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 48),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveReservoirSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: Colors.blue.withOpacity(0.5),
              ),
              child: const Text(
                'Save Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedScheduleView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
      key: const ValueKey('Fixed'),
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
                    child: const Icon(Icons.water_drop, color: Colors.white, size: 32),
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
                        '${_intervals.length} cycles scheduled',
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

        const SizedBox(height: 10),

        if (_intervals.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No watering cycles set.', style: TextStyle(color: Colors.white54)),
          )
        else
          ..._intervals.asMap().entries.map((entry) {
            final index = entry.key;
            final interval = entry.value;
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
                            interval.name,
                            style: TextStyle(
                              color: interval.isEnabled ? Colors.white : Colors.white38,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${interval.startTime.format(context)} • ${_formatDuration(interval.duration)}',
                                style: TextStyle(color: Colors.white.withOpacity(0.5)),
                              ),
                              if (interval.pumpId != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Pump: ${_pumps.firstWhere((p) => p.id == interval.pumpId, orElse: () => _pumps.first).name}',
                                  style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: interval.isEnabled,
                                activeColor: Colors.blue,
                                onChanged: (val) async {
                                  final updated = IrrigationSchedule(
                                    id: interval.id,
                                    name: interval.name,
                                    startTime: interval.startTime,
                                    duration: interval.duration,
                                    days: interval.days,
                                    pumpId: interval.pumpId,
                                    isEnabled: val,
                                  );
                                  await _databaseHelper.updateIrrigationSchedule(updated);
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
          }),
      ],
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
                'Pumps',
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.water_drop, color: Colors.blue),
                  title: Text(pump.name, style: const TextStyle(color: Colors.white)),
                  subtitle: FutureBuilder<List<dynamic>>(
                    future: _databaseHelper.getControlIoAssignments(pump.id),
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
                    onPressed: () => _showDeviceDialog(pump: pump),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDeviceDialog({EnvironmentalControl? pump}) async {
    final nameController = TextEditingController(text: pump?.name ?? '');
    int? selectedChannelId;
    
    // If editing, load existing assignment
    if (pump != null) {
      final assignments = await _databaseHelper.getControlIoAssignments(pump.id);
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
                  pump == null ? 'Add Pump' : 'Edit Pump',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                VirtualKeyboardTextField(
                  controller: nameController,
                  label: 'Pump Name',
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
                          if (pump == null) {
                            // Create new pump
                            final newId = await _databaseHelper.createZoneControl(
                              widget.zone.id!,
                              5, // Water Pump type
                              nameController.text,
                            );
                            if (selectedChannelId != null) {
                              await _databaseHelper.assignControlIo(newId, selectedChannelId!, 'power');
                            }
                          } else {
                            // Update existing
                            await _databaseHelper.updateZoneControlName(pump.id, nameController.text);
                            
                            // Update assignment
                            final assignments = await _databaseHelper.getControlIoAssignments(pump.id);
                            if (assignments.isNotEmpty) {
                              if (selectedChannelId != null) {
                                await _databaseHelper.updateIoAssignment(assignments.first.id, channelId: selectedChannelId);
                              } else {
                                await _databaseHelper.deleteIoAssignment(assignments.first.id);
                              }
                            } else if (selectedChannelId != null) {
                              await _databaseHelper.assignControlIo(pump.id, selectedChannelId!, 'power');
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
            style: const TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildDayIndicators(List<bool> days) {
    if (days.every((d) => d)) return const Text('Daily', style: TextStyle(color: Colors.white54, fontSize: 12));
    if (days.every((d) => !d)) return const Text('Never', style: TextStyle(color: Colors.white54, fontSize: 12));

    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: List.generate(7, (index) {
        if (!days[index]) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Text(
            dayNames[index],
            style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
      }),
    );
  }
}
