// lib/widgets/cards/card_factory.dart - UPDATED WITH VENTILATION & CLIMATE
import 'package:flutter/material.dart';
import 'base_control_card.dart';
import 'lighting/lighting_card.dart';
import 'irrigation/irrigation_card.dart';
import 'sensors/sensor_card.dart';
import 'aeration/aeration_card.dart';
import 'hvac/hvac_card.dart';
import 'climate/climate_card.dart';
import 'fertigation/fertigation_card.dart';
import 'guardian/guardian_card.dart';

/// Factory for creating control cards
class CardFactory {
  static BaseControlCard createCard({
    required String cardType,
    required int zoneId,
    required Map<String, dynamic> data,
    bool isCompact = false,
    VoidCallback? onTap,
    VoidCallback? onDetailTap,
  }) {
    switch (cardType) {
      case 'lighting':
        return LightingCard(
          zoneId: zoneId,
          isLightOn: data['isLightOn'] ?? false,
          brightness: data['brightness'] ?? 50,
          schedule: data['schedule'] ?? 'Manual',
          isScheduleActive: data['isScheduleActive'] ?? false,
          onToggle: data['onToggle'],
          onBrightnessChanged: data['onBrightnessChanged'],
          isCompact: isCompact,
          onTap: onTap,
          onDetailTap: onDetailTap,
        );

      case 'irrigation':
        return IrrigationCard(
          zoneId: zoneId,
          isWatering: data['isWatering'] ?? false,
          duration: data['duration'] ?? 10,
          nextWatering: data['nextWatering'] ?? 'Manual only',
          soilMoisture: data['soilMoisture'] ?? 50,
          mode: data['mode'] ?? 'manual',
          //onStartWatering: data['onStartWatering'],
          //onStopWatering: data['onStopWatering'],
          isCompact: isCompact,
          onTap: onTap,
          onDetailTap: onDetailTap,
        );

      case 'sensor':
        return SensorCard(
          zoneId: zoneId,
          temperature: data['temperature'] ?? 22.0,
          humidity: data['humidity'] ?? 60.0,
          soilMoisture: data['soilMoisture'] ?? 50,
          lightLevel: data['lightLevel'] ?? 75.0,
          lastUpdate: data['lastUpdate'] ?? '5 min ago',
          recentReadings: data['recentReadings'] ?? [],
          isCompact: isCompact,
          onTap: onTap,
          onDetailTap: onDetailTap,
        );

      case 'grow_info':
        return GrowInfoCard(
          zoneId: zoneId,
          plantName: data['plantName'] ?? 'Unknown Plant',
          growDay: data['growDay'] ?? 0,
          growStage: data['growStage'] ?? 'Vegetative',
          harvestDate: data['harvestDate'] ?? 'Unknown',
          isCompact: isCompact,
          onTap: onTap,
          onDetailTap: onDetailTap,
        );

      case 'aeration':
        return AerationCard(
          zoneId: zoneId,
          isPumpOn: data['isPumpOn'] ?? false,
          mode: data['mode'] ?? 'continuous',
          nextCycle: data['nextCycle'] ?? 'Always on',
          pressure: data['pressure'] ?? 75,
          onToggle: data['onToggle'],
          onModeChanged: data['onModeChanged'],
          isCompact: isCompact,
          onTap: onTap,
          onDetailTap: onDetailTap,
        );

      case 'hvac':
        return HvacCard(
          zoneId: zoneId,
          isFanRunning: data['isFanRunning'] ?? false,
          fanSpeed: data['fanSpeed'] ?? 50,
          mode: data['mode'] ?? 'manual',
          targetTemperature: data['targetTemperature'] ?? 25.0,
          schedule: data['schedule'] ?? '',
          onToggle: data['onToggle'],
          onSpeedChanged: data['onSpeedChanged'],
          onModeChanged: data['onModeChanged'],
          onTargetTempChanged: data['onTargetTempChanged'],
          isCompact: isCompact,
          onTap: onTap,
          onDetailTap: onDetailTap,
        );

      case 'climate':
        return ClimateCard(
          zoneId: zoneId,
          isClimateControlActive: data['isClimateControlActive'] ?? false,
          currentTemperature: data['currentTemperature'] ?? 22.0,
          currentHumidity: data['currentHumidity'] ?? 60.0,
          targetTempDay: data['targetTempDay'] ?? 24.0,
          targetTempNight: data['targetTempNight'] ?? 20.0,
          targetHumidity: data['targetHumidity'] ?? 65.0,
          mode: data['mode'] ?? 'manual',
          heatingEnabled: data['heatingEnabled'] ?? false,
          coolingEnabled: data['coolingEnabled'] ?? false,
          onToggle: data['onToggle'],
          onTargetTempDayChanged: data['onTargetTempDayChanged'],
          onTargetTempNightChanged: data['onTargetTempNightChanged'],
          onTargetHumidityChanged: data['onTargetHumidityChanged'],
          onModeChanged: data['onModeChanged'],
          isCompact: isCompact,
          onTap: onTap,
          onDetailTap: onDetailTap,
        );

      case 'fertigation':
        return FertigationCard(
          zoneId: zoneId,
          currentPh: data['currentPh'] ?? 0.0,
          currentEc: data['currentEc'] ?? 0.0,
          targetPh: data['targetPh'] ?? 6.0,
          targetEc: data['targetEc'] ?? 1.5,
          status: data['status'] ?? 'Idle',
          reservoirLevel: data['reservoirLevel'],
          onSettingsTap: data['onSettingsTap'],
          isCompact: isCompact,
          onTap: onTap,
          onDetailTap: onDetailTap,
        );

      case 'guardian':
        return GuardianCard(
          zoneId: zoneId,
          lastCheck: data['lastCheck'] ?? 'Never',
          latestAdvice: data['latestAdvice'] ?? 'No advice yet.',
          isMonitoring: data['isMonitoring'] ?? false,
          onSettingsTap: data['onSettingsTap'],
          isCompact: isCompact,
          onTap: onTap,
          onDetailTap: onDetailTap,
        );

      case 'camera':
        return SimpleControlCard(
          zoneId: zoneId,
          title: 'Camera',
          icon: Icons.camera_alt,
          color: Colors.pink,
          isEnabled: data['isEnabled'] ?? true,
          isActive: data['isActive'] ?? false,
          onToggle: data['onToggle'],
          isCompact: isCompact,
          onTap: onTap,
          onDetailTap: onDetailTap,
        );

      default:
        throw Exception('Unknown card type: $cardType');
    }
  }

  /// Get card configuration for a grow method
  static List<String> getDefaultCardsForGrowMethod(String growMethod) {
    switch (growMethod.toLowerCase()) {
      case 'soil':
        return ['grow_info', 'sensor', 'irrigation', 'camera'];
      
      case 'hydroponic':
        return ['grow_info', 'sensor', 'lighting', 'aeration', 'hvac', 'camera'];

      case 'ebb_flow':
        return ['grow_info', 'sensor', 'lighting', 'aeration', 'irrigation', 'hvac', 'camera'];

      case 'nft':
        return ['grow_info', 'sensor', 'lighting', 'aeration', 'irrigation', 'hvac', 'camera'];
      
      case 'aeroponics':
        return ['grow_info', 'sensor', 'lighting', 'aeration', 'irrigation', 'hvac', 'climate', 'camera'];
      
      case 'drip_irrigation':
        return ['grow_info', 'sensor', 'irrigation', 'camera'];
      
      default:
        return ['grow_info', 'sensor', 'lighting', 'irrigation'];
    }
  }

  /// Get card metadata
  static Map<String, dynamic> getCardMetadata(String cardType) {
    switch (cardType) {
      case 'grow_info':
        return {
          'name': 'Grow Info',
          'icon': Icons.eco,
          'color': Colors.green,
          'description': 'Plant information and growth progress',
          'category': 'essential',
        };
      
      case 'sensor':
        return {
          'name': 'Sensors',
          'icon': Icons.sensors,
          'color': Colors.blue,
          'description': 'Environmental monitoring and readings',
          'category': 'essential',
        };
      
      case 'lighting':
        return {
          'name': 'Lighting',
          'icon': Icons.lightbulb,
          'color': Colors.yellow,
          'description': 'Light control and scheduling',
          'category': 'control',
        };
      
      case 'irrigation':
        return {
          'name': 'Irrigation',
          'icon': Icons.water_drop,
          'color': Colors.cyan,
          'description': 'Watering control and scheduling',
          'category': 'control',
        };
      
      case 'hvac':
        return {
          'name': 'HVAC',
          'icon': Icons.air,
          'color': Colors.purple,
          'description': 'Air circulation and ventilation',
          'category': 'control',
        };

      case 'aeration':
        return {
          'name': 'Aeration',
          'icon': Icons.air,
          'color': Colors.lightBlue,
          'description': 'Air pump and oxygenation control',
          'category': 'control',
        };
      
      case 'climate':
        return {
          'name': 'Climate',
          'icon': Icons.thermostat,
          'color': Colors.orange,
          'description': 'Temperature and humidity control',
          'category': 'control',
        };
      
      case 'fertigation':
        return {
          'name': 'Fertigation',
          'icon': Icons.science,
          'color': Colors.teal,
          'description': 'Automated nutrient dosing and pH control',
          'category': 'control',
        };
      
      case 'guardian':
        return {
          'name': 'Guardian AI',
          'icon': Icons.psychology,
          'color': Colors.purple,
          'description': 'AI-powered grow advisor and monitor',
          'category': 'monitoring',
        };
      
      case 'camera':
        return {
          'name': 'Camera',
          'icon': Icons.camera_alt,
          'color': Colors.pink,
          'description': 'Time-lapse and monitoring',
          'category': 'monitoring',
        };
      
      default:
        return {
          'name': cardType,
          'icon': Icons.dashboard,
          'color': Colors.grey,
          'description': 'Unknown card type',
          'category': 'other',
        };
    }
  }

  /// Get all available card types
  static List<String> getAllCardTypes() {
    return [
      'grow_info',
      'sensor',
      'lighting',
      'irrigation',
      'aeration',
      'hvac',
      'climate',
      'fertigation',
      'guardian',
      'camera',
    ];
  }
}

/// Grow info card implementation
class GrowInfoCard extends BaseControlCard {
  final String plantName;
  final int growDay;
  final String growStage;
  final String harvestDate;

  const GrowInfoCard({
    super.key,
    required super.zoneId,
    required this.plantName,
    required this.growDay,
    required this.growStage,
    required this.harvestDate,
    super.isCompact = false,
    super.onTap,
    super.onDetailTap,
  }) : super(
          title: 'Grow Info',
          icon: Icons.eco,
          color: Colors.green,
        );

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plant name
        Text(
          plantName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 8),
        
        // Growth info
        Row(
          children: [
            Expanded(
              child: CardStatusIndicator(
                label: 'Day',
                value: growDay.toString(),
                color: Colors.green,
                icon: Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CardStatusIndicator(
                label: 'Stage',
                value: growStage,
                color: Colors.blue,
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Harvest estimate
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.schedule,
                color: Colors.green,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Harvest: $harvestDate',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Growth progress bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Growth Progress',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: _getGrowthProgress(),
              backgroundColor: Colors.grey.shade700,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 4,
            ),
          ],
        ),
      ],
    );
  }

  @override
  String getStatusText() {
    return 'Day $growDay • $growStage';
  }

  double _getGrowthProgress() {
    // Simplified progress calculation based on growth stage
    switch (growStage.toLowerCase()) {
      case 'seedling':
        return 0.2;
      case 'vegetative':
        return 0.5;
      case 'flowering':
        return 0.8;
      case 'harvest':
        return 1.0;
      default:
        return growDay / 90.0; // Assume 90-day cycle
    }
  }
}