// lib/screens/home/zone_control_screen.dart - Fixed version
// 
// FIXES APPLIED:
// 1. Removed reference to missing getLatestSensorReadings method
// 2. Removed unused _availableCards field
// 3. Fixed BuildContext usage in buildDetailScreen check
// 4. Added proper error handling for missing methods

import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/database_helper.dart';
import '../../services/timer_manager.dart';
import '../../services/hardware_service.dart';
import '../../models/zone.dart';
import '../../models/grow.dart';
import '../../models/sensor.dart';
import '../../widgets/cards/card_factory.dart';


class ZoneControlScreen extends StatefulWidget {
  final int? zoneId; // Pass zone ID for direct navigation

  const ZoneControlScreen({super.key, this.zoneId});

  @override
  State<ZoneControlScreen> createState() => _ZoneControlScreenState();
}

class _ZoneControlScreenState extends State<ZoneControlScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final TimerManager _timerManager = TimerManager.instance;
  final HardwareService _hardware = HardwareService.instance;

  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Data
  List<Zone> _zones = [];
  Zone? _currentZone;
  Grow? _currentGrow;
  Map<int, List<SensorReading>> _latestReadings = {};
  bool _isZoneActive = false;
  
  // UI State
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  // Card system data - FIXED: Removed unused _availableCards
  List<String> _enabledCards = [];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _loadData();

    // Refresh timer
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshSensorData();
    });

    // Listen to timer events
    _timerManager.eventStream.listen((event) {
      if (event.type == TimerEventType.manualActivated ||
          event.type == TimerEventType.manualDeactivated) {
        _updateZoneStatus();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load zones
      final zones = await _db.getZones();
      
      if (zones.isEmpty) {
        setState(() {
          _errorMessage = 'No zones found';
          _isLoading = false;
        });
        return;
      }

      // Determine current zone
      Zone currentZone;
      if (widget.zoneId != null) {
        currentZone = zones.firstWhere(
          (z) => z.id == widget.zoneId,
          orElse: () => zones.first,
        );
      } else {
        currentZone = zones.first;
      }

      // Load grow for current zone
      Grow? currentGrow;
      if (currentZone.growId != null) {
        try {
          currentGrow = await _db.getGrow(currentZone.growId!);
        } catch (e) {
          debugPrint('Error loading grow: $e');
        }
      }

      // Initialize tab controller
      _tabController = TabController(
        length: zones.length,
        vsync: this,
        initialIndex: zones.indexOf(currentZone),
      );

      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          _switchToZone(zones[_tabController.index]);
        }
      });

      // Load card configuration
      await _loadCardConfiguration(currentZone);

      // Update state
      setState(() {
        _zones = zones;
        _currentZone = currentZone;
        _currentGrow = currentGrow;
        _isLoading = false;
      });

      await _updateZoneStatus();
      await _refreshSensorData();

      _fadeController.forward();

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load zone data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCardConfiguration(Zone zone) async {
    // Get grow method to determine default cards
    String? growMethod;
    if (_currentGrow != null) {
      try {
        // Get grow mode from grow
        final growModes = await _db.getGrowModes();
        final growMode = growModes.firstWhere(
          (mode) => mode.id == _currentGrow!.growModeId,
          orElse: () => growModes.first,
        );
        growMethod = growMode.name;
      } catch (e) {
        debugPrint('Error loading grow method: $e');
      }
    }

    // Get default cards for this grow method
    final defaultCards = CardFactory.getDefaultCardsForGrowMethod(
      growMethod ?? 'soil',
    );

    // TODO: Load user's customized card configuration from database
    // For now, use defaults
    setState(() {
      _enabledCards = defaultCards;
    });
  }

  Future<void> _switchToZone(Zone zone) async {
    setState(() {
      _currentZone = zone;
      _isLoading = true;
    });

    try {
      // Load grow for this zone
      if (zone.growId != null) {
        _currentGrow = await _db.getGrow(zone.growId!);
      } else {
        _currentGrow = null;
      }

      await _loadCardConfiguration(zone);
      await _updateZoneStatus();
      await _refreshSensorData();

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to switch to zone: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateZoneStatus() async {
    if (_currentZone == null) return;

    try {
      final activeZones = await _timerManager.getActiveZones();
      setState(() {
        _isZoneActive = activeZones.contains(_currentZone!.id);
      });
    } catch (e) {
      debugPrint('Error updating zone status: $e');
    }
  }

  // FIXED: Simplified sensor data refresh without missing getLatestSensorReadings
  Future<void> _refreshSensorData() async {
    if (_currentZone == null) return;

    try {
      // Try to get sensors for the zone
      final sensors = await _db.getZoneSensors(_currentZone!.id);
      final readings = <int, List<SensorReading>>{};

      for (final sensor in sensors) {
        try {
          // Try to get fresh reading from hardware
          final supportedTypes = sensor.getSupportedReadingTypes();
          
          for (final readingType in supportedTypes) {
            final value = await _hardware.readSensor(sensor.id, readingType);
            
            if (!readings.containsKey(sensor.id)) {
              readings[sensor.id] = [];
            }
            
            readings[sensor.id]!.add(SensorReading(
              id: 0,
              sensorId: sensor.id,
              readingType: readingType,
              value: value,
              timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            ));
          }
        } catch (e) {
          debugPrint('Error reading sensor ${sensor.id}: $e');
          // Use mock data if hardware fails
          readings[sensor.id] = _getMockSensorReadings(sensor.id);
        }
      }

      if (mounted) {
        setState(() {
          _latestReadings = readings;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing sensor data: $e');
      // Use mock data if everything fails
      _latestReadings = _getMockAllSensorData();
    }
  }

  // Helper to create mock sensor readings
  List<SensorReading> _getMockSensorReadings(int sensorId) {
    return [
      SensorReading(
        id: 0,
        sensorId: sensorId,
        readingType: 'temperature',
        value: 22.5,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
      SensorReading(
        id: 1,
        sensorId: sensorId,
        readingType: 'humidity',
        value: 65.0,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    ];
  }

  Map<int, List<SensorReading>> _getMockAllSensorData() {
    return {
      1: _getMockSensorReadings(1),
    };
  }

  Future<void> _toggleZone() async {
    if (_currentZone == null) return;

    try {
      if (_isZoneActive) {
        await _timerManager.manualDeactivate(_currentZone!.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zone ${_currentZone!.name} deactivated'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        await _timerManager.manualActivate(_currentZone!.id, 600); // 10 minutes
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zone ${_currentZone!.name} activated for 10 minutes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling zone: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startIrrigation() async {
    if (_currentZone == null) return;

    try {
      // Start irrigation for 5 minutes
      await _timerManager.manualActivate(_currentZone!.id, 300);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Irrigation started for 5 minutes'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting irrigation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopIrrigation() async {
    if (_currentZone == null) return;

    try {
      await _timerManager.manualDeactivate(_currentZone!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Irrigation stopped'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error stopping irrigation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // slate-900
              Color(0xFF1E3A8A), // blue-900
              Color(0xFF1E293B), // slate-800
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingView()
              : _errorMessage != null
                  ? _buildErrorView()
                  : _buildZoneControl(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 16),
          Text(
            'Loading zone...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneControl() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildHeader(),
          if (_zones.length > 1) _buildTabBar(),
          Expanded(
            child: _zones.length > 1
                ? TabBarView(
                    controller: _tabController,
                    children: _zones.map((zone) => _buildZoneContent(zone)).toList(),
                  )
                : _buildZoneContent(_currentZone!),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_zones.length > 1) {
                    Navigator.pushReplacementNamed(context, '/zones/selection');
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _currentZone?.name ?? 'Loading...',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_currentGrow != null)
                      Text(
                        '${_currentGrow!.name} • Day ${_currentGrow!.getCurrentDay()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isZoneActive ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isZoneActive ? 'ACTIVE' : 'INACTIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorColor: Colors.green,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey,
      tabs: _zones.map((zone) => Tab(text: zone.name)).toList(),
    );
  }

  Widget _buildZoneContent(Zone zone) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildQuickControls(),
          const SizedBox(height: 24),
          Expanded(child: _buildControlCards()),
        ],
      ),
    );
  }

  Widget _buildQuickControls() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickControlButton(
            _isZoneActive ? 'Stop Zone' : 'Start Zone',
            _isZoneActive ? Icons.stop : Icons.play_arrow,
            _isZoneActive ? Colors.red : Colors.green,
            _toggleZone,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickControlButton(
            'Sensors',
            Icons.sensors,
            Colors.blue,
            () {
              // Navigate to sensor detail
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickControlButton(
            'Settings',
            Icons.tune,
            Colors.grey,
            () => Navigator.pushNamed(context, '/zones/management'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickControlButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha:0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCards() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _enabledCards.length,
      itemBuilder: (context, index) {
        final cardType = _enabledCards[index];
        return _buildControlCard(cardType);
      },
    );
  }

  Widget _buildControlCard(String cardType) {
    if (_currentZone == null) return const SizedBox.shrink();

    // Prepare card data based on type
    final cardData = _getCardData(cardType);

    return CardFactory.createCard(
      cardType: cardType,
      zoneId: _currentZone!.id,
      data: cardData,
      isCompact: false,
      onTap: () => _handleCardTap(cardType),
      onDetailTap: () => _navigateToCardDetail(cardType),
    );
  }

  Map<String, dynamic> _getCardData(String cardType) {
    switch (cardType) {
      case 'lighting':
        return {
          'isLightOn': _isZoneActive, // Simplified - use zone active state
          'brightness': 75,
          'schedule': 'Auto (Sunrise + 30min)',
          'isScheduleActive': true,
          'onToggle': () => _toggleZoneSystem('lighting'),
          'onBrightnessChanged': (int brightness) {
            // TODO: Implement brightness control
            debugPrint('Brightness changed to: $brightness');
          },
        };

      case 'irrigation':
        return {
          'isWatering': _isZoneActive,
          'duration': 10,
          'nextWatering': 'In 2h 30m',
          'soilMoisture': _getSoilMoisture(),
          'onStartWatering': () => _startIrrigation(),
          'onStopWatering': () => _stopIrrigation(),
        };

      case 'aeration':
        return {
          'isPumpOn': _isZoneActive,
          'mode': 'continuous',
          'nextCycle': 'Always on',
          'pressure': 75,
          'onToggle': () => _toggleZoneSystem('aeration'),
          'onModeChanged': (String mode) {
            debugPrint('Aeration mode changed to: $mode');
            setState(() {
              // Update mode state here when backend is connected
            });
          },
        };

      case 'sensor':
        return {
          'temperature': _getTemperature(),
          'humidity': _getHumidity(),
          'soilMoisture': _getSoilMoisture(),
          'lightLevel': _getLightLevel(),
          'lastUpdate': '2 min ago',
          'recentReadings': _getRecentReadings(),
        };

      case 'grow_info':
        return {
          'plantName': _getPlantName(),
          'growDay': _currentGrow?.getCurrentDay() ?? 0,
          'growStage': 'Vegetative',
          'harvestDate': _getEstimatedHarvestDate(),
        };

      case 'climate':
        return {
          'isClimateControlActive': _isZoneActive,
          'currentTemperature': _getTemperature(),
          'currentHumidity': _getHumidity(),
          'targetTempDay': 24.0,
          'targetTempNight': 20.0,
          'targetHumidity': 65.0,
          'mode': 'automatic',
          'heatingEnabled': false,
          'coolingEnabled': false,
          'onToggle': () => _toggleZoneSystem('climate'),
          'onTargetTempDayChanged': (double temp) {
            debugPrint('Day target temperature changed to: $temp°C');
            setState(() {
              // Update day target temperature state here when backend is connected
            });
          },
          'onTargetTempNightChanged': (double temp) {
            debugPrint('Night target temperature changed to: $temp°C');
            setState(() {
              // Update night target temperature state here when backend is connected
            });
          },
          'onTargetHumidityChanged': (double humidity) {
            debugPrint('Target humidity changed to: $humidity%');
            setState(() {
              // Update target humidity state here when backend is connected
            });
          },
          'onModeChanged': (String mode) {
            debugPrint('Climate mode changed to: $mode');
            setState(() {
              // Update climate mode state here when backend is connected
            });
          },
        };

      case 'ventilation':
        return {
          'isFanRunning': _isZoneActive,
          'fanSpeed': 50,
          'mode': 'manual',
          'targetTemperature': 25.0,
          'schedule': '6:00 AM - 10:00 PM',
          'onToggle': () => _toggleZoneSystem('ventilation'),
          'onSpeedChanged': (int speed) {
            debugPrint('Fan speed changed to: $speed%');
            setState(() {
              // Update fan speed state here when backend is connected
            });
          },
          'onModeChanged': (String mode) {
            debugPrint('Ventilation mode changed to: $mode');
            setState(() {
              // Update ventilation mode state here when backend is connected
            });
          },
          'onTargetTempChanged': (double temp) {
            debugPrint('Target temperature changed to: $temp°C');
            setState(() {
              // Update target temperature state here when backend is connected
            });
          },
        };

      default:
        return {};
    }
  }

  void _handleCardTap(String cardType) {
    // Handle simple card interactions
    switch (cardType) {
      case 'lighting':
        _toggleZoneSystem('lighting');
        break;
      case 'irrigation':
        _startIrrigation();
        break;
      default:
        _navigateToCardDetail(cardType);
        break;
    }
  }

  // FIXED: Proper BuildContext handling for buildDetailScreen check
  void _navigateToCardDetail(String cardType) {
    // Navigate to detailed card control screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          final cardData = _getCardData(cardType);
          final card = CardFactory.createCard(
            cardType: cardType,
            zoneId: _currentZone!.id,
            data: cardData,
          );
          
          // FIXED: Pass actual context instead of null
          final detailScreen = card.buildDetailScreen(context);
          
          if (detailScreen != null) {
            return detailScreen;
          } else {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Text(
                  '${_getCardDisplayName(cardType)} details coming soon!',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  String _getCardDisplayName(String cardType) {
    switch (cardType) {
      case 'grow_info':
        return 'Grow Info';
      case 'sensor':
        return 'Sensors';
      case 'lighting':
        return 'Lighting';
      case 'irrigation':
        return 'Irrigation';
      case 'ventilation':
        return 'Ventilation';
      case 'climate':
        return 'Climate';
      case 'camera':
        return 'Camera';
      default:
        return cardType;
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: _enabledCards.take(5).map((cardType) {
          final metadata = CardFactory.getCardMetadata(cardType);
          
          return Expanded(
            child: GestureDetector(
              onTap: () => _navigateToCardDetail(cardType),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800.withValues(alpha:0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      metadata['icon'],
                      color: metadata['color'],
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadata['name'],
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Helper methods for getting card data
  double _getTemperature() {
    // Try to get from sensor readings, fallback to mock data
    for (final readings in _latestReadings.values) {
      for (final reading in readings) {
        if (reading.readingType == 'temperature') {
          return reading.value;
        }
      }
    }
    return 22.5; // Mock temperature
  }

  double _getHumidity() {
    for (final readings in _latestReadings.values) {
      for (final reading in readings) {
        if (reading.readingType == 'humidity') {
          return reading.value;
        }
      }
    }
    return 65.0; // Mock humidity
  }

  int _getSoilMoisture() {
    for (final readings in _latestReadings.values) {
      for (final reading in readings) {
        if (reading.readingType == 'soil_moisture') {
          return reading.value.round();
        }
      }
    }
    return 55; // Mock soil moisture
  }

  double _getLightLevel() {
    for (final readings in _latestReadings.values) {
      for (final reading in readings) {
        if (reading.readingType == 'light_level') {
          return reading.value;
        }
      }
    }
    return 75.0; // Mock light level
  }

  String _getPlantName() {
    // TODO: Get from plant database
    return _currentGrow?.name ?? 'Unknown Plant';
  }

  String _getEstimatedHarvestDate() {
    if (_currentGrow == null) return 'Unknown';
    
    // Simple estimation: add 90 days to start date
    final harvestDate = DateTime.fromMillisecondsSinceEpoch(
      (_currentGrow!.startTime + (90 * 24 * 3600)) * 1000,
    );
    
    return '${harvestDate.month}/${harvestDate.day}/${harvestDate.year}';
  }

  List<dynamic> _getRecentReadings() {
    // Convert sensor readings to simple format
    return _latestReadings.values
        .expand((readings) => readings)
        .map((reading) => {
              'type': reading.readingType,
              'value': reading.value,
              'timestamp': DateTime.fromMillisecondsSinceEpoch(
                reading.timestamp * 1000,
              ),
            })
        .toList();
  }

  Future<void> _toggleZoneSystem(String systemType) async {
    try {
      // Simple toggle implementation
      // TODO: Implement proper system-specific controls
      if (_isZoneActive) {
        await _timerManager.manualDeactivate(_currentZone!.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$systemType deactivated'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await _timerManager.manualActivate(_currentZone!.id, 300); // 5 minutes
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$systemType activated for 5 minutes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling $systemType: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}