import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../../models/guardian/guardian_settings.dart';
import '../../models/guardian/guardian_context.dart';
import '../../models/guardian/guardian_status.dart';
import '../../models/guardian/guardian_alert.dart';
import 'guardian_context_builder.dart';

class GuardianService {
  final DatabaseHelper _db = DatabaseHelper();
  
  // Singleton pattern
  static final GuardianService _instance = GuardianService._internal();
  factory GuardianService() => _instance;
  GuardianService._internal();

  Future<GuardianStatus> getZoneStatus(int zoneId) async {
    // 1. Build Context
    final builder = GuardianContextBuilder(zoneId);
    final context = await builder.build();

    // 2. Run Local Analysis (Tier 1 & 2)
    final alerts = await _runLocalAnalysis(context);

    // 3. Get latest AI Analysis (Tier 3)
    // final latestAnalysis = await _db.getLatestGuardianAnalysis(zoneId);

    // 4. Construct Status
    return GuardianStatus(
      overallStatus: _determineOverallStatus(alerts),
      confidence: 1.0, // Placeholder
      summary: _generateSummary(context, alerts),
      conditions: _evaluateConditions(context),
      trends: _extractTrends(context),
      alerts: alerts,
      recommendations: _generateRecommendations(context, alerts),
      lastAnalysis: DateTime.now(),
      // lastVisionAnalysis: latestAnalysis?.analysisType == 'vision' ? ... : null,
    );
  }

  List<GuardianAlert> _checkThresholds(GuardianContext context) {
    List<GuardianAlert> alerts = [];
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Check each sensor against its thresholds (if available in context)
    // Note: This is a basic implementation. Real implementation would check against recipe targets.
    
    // Example: Check if temperature is within reasonable bounds (10-40 C)
    if (context.currentReadings.containsKey('temperature')) {
      final temp = context.currentReadings['temperature']!;
      if (temp < 10.0 || temp > 40.0) {
        alerts.add(GuardianAlert(
          zoneId: context.zoneId,
          severity: 'warning',
          category: 'environment',
          title: 'Temperature Out of Range',
          message: 'Current temperature ($temp°C) is outside safe limits (10-40°C).',
          readingType: 'temperature',
          value: temp,
          createdAt: now,
        ));
      }
    }

    return alerts;
  }

  List<GuardianAlert> _detectAnomalies(GuardianContext context) {
    List<GuardianAlert> alerts = [];
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    context.sensorHistory.forEach((type, history) {
      if (history.length < 2) return;

      // Sort by timestamp descending just in case
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      final current = history[0];
      final previous = history[1];
      final timeDiff = current.timestamp - previous.timestamp;
      
      // Ignore if readings are too far apart (e.g., > 1 hour)
      if (timeDiff > 3600) return;

      final delta = (current.value - previous.value).abs();
      
      // 1. Sudden Flow Increase (Potential Leak)
      if (type == 'flow_rate') {
        // If flow increases significantly when it was previously low/zero
        if (current.value > 5.0 && previous.value < 1.0) {
          // Check if irrigation is active
          if (!context.irrigationActive) {
             alerts.add(GuardianAlert(
              zoneId: context.zoneId,
              severity: 'critical',
              category: 'anomaly',
              title: 'Sudden Flow Detected (Leak?)',
              message: 'Flow rate jumped to ${current.value} L/min while irrigation is inactive.',
              readingType: 'flow_rate',
              value: current.value,
              createdAt: now,
            ));
          }
        }
      }

      // 2. Sudden Temperature Spike (Fire/Fault)
      if (type == 'temperature') {
        if (delta > 5.0) { // 5 degree jump in one reading interval is suspicious
           alerts.add(GuardianAlert(
            zoneId: context.zoneId,
            severity: 'critical',
            category: 'safety',
            title: 'Sudden Temperature Spike',
            message: 'Temperature jumped by ${delta.toStringAsFixed(1)}°C in ${timeDiff}s. Check for fire or sensor fault.',
            readingType: 'temperature',
            value: current.value,
            createdAt: now,
          ));
        }
      }

      // 3. Sudden pH/EC Instability (Probe Fault)
      if (type == 'ph' && delta > 1.0) {
         alerts.add(GuardianAlert(
          zoneId: context.zoneId,
          severity: 'warning',
          category: 'hardware',
          title: 'Sudden pH Jump',
          message: 'pH changed by ${delta.toStringAsFixed(1)} in ${timeDiff}s. Possible probe fault.',
          readingType: 'ph',
          value: current.value,
          createdAt: now,
        ));
      }
    });

    return alerts;
  }

  Future<List<GuardianAlert>> _runLocalAnalysis(GuardianContext context) async {
    List<GuardianAlert> alerts = [];
    
    // Tier 1: Thresholds
    alerts.addAll(_checkThresholds(context));
    
    // Tier 2: Trends
    alerts.addAll(_analyzeTrends(context));

    // Tier 3: Anomalies
    alerts.addAll(_detectAnomalies(context));
    
    return alerts;
  }

  List<GuardianAlert> _analyzeTrends(GuardianContext context) {
    List<GuardianAlert> alerts = [];
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    context.statistics.forEach((type, stats) {
      // pH Trending Up
      if (type == 'ph' && stats.trend == 'rising') {
        alerts.add(GuardianAlert(
          zoneId: context.zoneId,
          severity: 'info',
          category: 'trend',
          title: 'pH Trending Up',
          message: 'pH has been rising over the past 24h (current: ${context.currentReadings['ph']}). May need pH down dose soon.',
          readingType: 'ph',
          value: context.currentReadings['ph'],
          createdAt: now,
        ));
      }

      // EC Declining
      if (type == 'ec' && stats.trend == 'falling') {
        alerts.add(GuardianAlert(
          zoneId: context.zoneId,
          severity: 'info',
          category: 'trend',
          title: 'EC Declining',
          message: 'EC dropping faster than usual. Plants may be feeding heavily or dilution occurring.',
          readingType: 'ec',
          value: context.currentReadings['ec'],
          createdAt: now,
        ));
      }

      // Temperature Instability
      if (type == 'temperature' && stats.stdDev > 4.0) {
        alerts.add(GuardianAlert(
          zoneId: context.zoneId,
          severity: 'warning',
          category: 'stability',
          title: 'Temperature Unstable',
          message: 'Temperature swings of ${(stats.max - stats.min).toStringAsFixed(1)}°C in 24h. Check HVAC or environment.',
          readingType: 'temperature',
          value: context.currentReadings['temperature'],
          createdAt: now,
        ));
      }
      
      // Recipe Compliance (if targets available)
      // This requires implementing target checking in ContextBuilder first
    });

    return alerts;
  }

  String _determineOverallStatus(List<GuardianAlert> alerts) {
    if (alerts.any((a) => a.severity == 'critical')) return 'critical';
    if (alerts.any((a) => a.severity == 'warning')) return 'warning';
    return 'healthy';
  }

  String _generateSummary(GuardianContext context, List<GuardianAlert> alerts) {
    if (alerts.isEmpty) {
      return 'All systems nominal. Environment stable and on target.';
    }
    return '${alerts.length} active alerts. Attention required.';
  }

  Map<String, ConditionStatus> _evaluateConditions(GuardianContext context) {
    // Placeholder
    return {};
  }

  Map<String, String> _extractTrends(GuardianContext context) {
    Map<String, String> trends = {};
    context.statistics.forEach((key, stats) {
      trends[key] = stats.trend;
    });
    return trends;
  }

  List<Recommendation> _generateRecommendations(GuardianContext context, List<GuardianAlert> alerts) {
    // Placeholder
    return [];
  }
}
