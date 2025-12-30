import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../anthropic_service.dart';
import '../database_helper.dart';
import '../../models/guardian/guardian_context.dart';
import '../../models/guardian/guardian_action.dart';
import '../../models/guardian_report.dart';

class GuardianAdvisorService {
  static final GuardianAdvisorService _instance = GuardianAdvisorService._internal();
  factory GuardianAdvisorService() => _instance;
  GuardianAdvisorService._internal();

  final AnthropicService _anthropic = AnthropicService();
  final DatabaseHelper _db = DatabaseHelper();

  static const String _systemPrompt = '''
You are Guardian, the AI assistant for SprigRig - an automated grow system controller.

Your role:
- Analyze sensor data, configurations, and system state
- Provide clear, actionable advice for plant care
- Diagnose issues by examining the full system context
- When actions are enabled, you can suggest system adjustments

Guidelines:
- Be concise but thorough
- Reference specific readings and configurations when relevant
- If something looks misconfigured, point it out specifically
- For problems, explain both the issue AND the solution
- Use plain language, avoid jargon unless necessary

When suggesting actions (if enabled), use this exact format:
```action
{
  "action_type": "...",
  "category": "...",
  "description": "...",
  "parameters": {...},
  "reasoning": "..."
}
```
''';

  /// Get AI advice with real API call
  Future<GuardianAdviceResponse> getAdvice(
    GuardianContext context, 
    String userQuery,
  ) async {
    // Get config for API key and action permissions
    final config = await _db.getGuardianConfig(context.zoneId);
    if (config == null || config.apiKey == null || config.apiKey!.isEmpty) {
      return GuardianAdviceResponse(
        success: false,
        message: 'API key not configured. Please add your Anthropic API key in Guardian settings.',
      );
    }

    // Build prompt with full context
    final includeActions = config.actionsEnabled;
    final prompt = generatePrompt(context, userQuery, includeActionCapabilities: includeActions);

    debugPrint('Sending prompt to Claude (${prompt.length} chars)');

    // Make API call
    final response = await _anthropic.sendMessage(
      apiKey: config.apiKey!,
      prompt: prompt,
      systemPrompt: _systemPrompt,
      maxTokens: 1500,
    );

    if (!response.success) {
      return GuardianAdviceResponse(
        success: false,
        message: response.message,
        error: response.error,
      );
    }

    // Parse response for any action blocks
    GuardianAction? suggestedAction;
    String cleanedMessage = response.message;

    if (includeActions) {
      final actionMatch = RegExp(r'```action\s*([\s\S]*?)\s*```').firstMatch(response.message);
      if (actionMatch != null) {
        try {
          final actionJson = jsonDecode(actionMatch.group(1)!);
          suggestedAction = GuardianAction(
            zoneId: context.zoneId,
            actionType: actionJson['action_type'],
            category: actionJson['category'],
            description: actionJson['description'],
            parameters: actionJson['parameters'],
            reasoning: actionJson['reasoning'],
          );
          // Remove action block from displayed message
          cleanedMessage = response.message.replaceAll(actionMatch.group(0)!, '').trim();
        } catch (e) {
          debugPrint('Failed to parse action block: $e');
        }
      }
    }

    // Save to report history
    await _saveReport(
      zoneId: context.zoneId,
      reportType: 'advice',
      content: cleanedMessage,
      userQuery: userQuery,
    );

    return GuardianAdviceResponse(
      success: true,
      message: cleanedMessage,
      suggestedAction: suggestedAction,
      requiresConfirmation: config.requireConfirmation,
      tokensUsed: response.tokensUsed,
    );
  }

  Future<void> _saveReport({
    required int zoneId,
    required String reportType,
    required String content,
    String? userQuery,
  }) async {
    final report = GuardianReport(
      zoneId: zoneId,
      reportType: reportType,
      fullResponse: content,
      // userQuery is not currently stored in GuardianReport
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    await _db.insertGuardianReport(report);
  }

  /// Generate a prompt for the LLM based on the context and user query
  String generatePrompt(GuardianContext context, String userQuery, {bool includeActionCapabilities = false}) {
    final buffer = StringBuffer();

    // 1. System Context
    buffer.writeln('You are Guardian, an AI botanical assistant for the SprigRig system.');
    buffer.writeln('Analyze the following zone status and configuration to answer the user\'s query.');
    buffer.writeln('');

    // 2. Zone Information
    buffer.writeln('--- ZONE INFORMATION ---');
    buffer.writeln('Zone: ${context.zoneName} (ID: ${context.zoneId})');
    buffer.writeln('Crop: ${context.cropName ?? "None"}');
    buffer.writeln('Grow Day: ${context.growDay}');
    buffer.writeln('Phase: ${context.growPhase ?? "Unknown"}');
    buffer.writeln('');

    // 3. Sensor Data
    buffer.writeln('--- CURRENT READINGS ---');
    context.currentReadings.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    buffer.writeln('');

    // 4. Configuration & System State
    buffer.writeln('--- SYSTEM CONFIGURATION & STATE ---');
    
    // Fertigation
    buffer.writeln('FERTIGATION SYSTEM:');
    if (context.fertigation == null || !context.fertigation!.enabled) {
      buffer.writeln('  Status: Not configured/Disabled');
    } else {
      final f = context.fertigation!;
      buffer.writeln('  Mode: ${f.dosingMode}');
      buffer.writeln('  Targets (${f.targetSource}): pH ${f.targets?['ph_min']}-${f.targets?['ph_max']}, EC ${f.targets?['ec_min']}-${f.targets?['ec_max']}');
      buffer.writeln('  Last Readings: pH ${f.lastPhReading ?? "N/A"}, EC ${f.lastEcReading ?? "N/A"}');
      buffer.writeln('  Doses Last Hour: ${f.dosesLastHour}/${f.maxDosesPerHour}');
      buffer.writeln('  Pumps:');
      for (var p in f.pumps) {
        buffer.writeln('    - ${p.name} (${p.pumpType}): ${p.enabled ? "Enabled" : "Disabled"}, Relay ${p.relayModuleAddress}:${p.relayChannel}');
      }
      buffer.writeln('  Probes:');
      for (var p in f.probes) {
        buffer.writeln('    - ${p.probeType}: ${p.enabled ? "Enabled" : "Disabled"}, Cal offset ${p.calibrationOffset}');
      }
    }
    buffer.writeln('');

    // Hardware Topology
    buffer.writeln('HARDWARE TOPOLOGY:');
    for (var module in context.relayModules) {
      buffer.writeln('  Module ${module.address}: ${module.status}, ${module.channelCount}ch');
    }
    buffer.writeln('  Output Assignments:');
    for (var out in context.outputs) {
      buffer.writeln('    - ${out.moduleAddress}:${out.channel} → ${out.assignedTo} [${out.category}] ${out.currentState ? "ON" : "OFF"}');
    }
    buffer.writeln('');

    // Active Recipe
    if (context.activeRecipe != null) {
      buffer.writeln('ACTIVE RECIPE:');
      final r = context.activeRecipe!;
      buffer.writeln('  Recipe: ${r.recipeName} (${r.cropType})');
      buffer.writeln('  Phase: ${r.currentPhaseName} - Day ${r.phaseDayNumber}/${r.totalPhaseDays}');
      buffer.writeln('  Targets: Temp ${r.targets.targetTempDay}°C, Humidity ${r.targets.targetHumidityDay}%, VPD ${r.targets.targetVpd}');
      if (r.phaseTransitionDate != null) {
        buffer.writeln('  Next phase in ${r.phaseTransitionDate!.difference(DateTime.now()).inDays} days');
      }
      buffer.writeln('');
    }

    // Schedules
    buffer.writeln('SCHEDULES:');
    buffer.writeln('  Lighting:');
    for (var s in context.lightingSchedules) {
      buffer.writeln('    - ${s['enabled'] == 1 ? "[ON]" : "[OFF]"} ${s['on_time']} - ${s['off_time']}');
    }
    buffer.writeln('  Irrigation:');
    for (var s in context.irrigationSchedules) {
      buffer.writeln('    - ${s.isEnabled ? "[ON]" : "[OFF]"} ${s.name}: ${s.startTime}');
    }
    buffer.writeln('  Intervals:');
    for (var s in context.intervals) {
      buffer.writeln('    - ${s.enabled ? "[ON]" : "[OFF]"} ${s.name} (${s.type})');
    }
    buffer.writeln('');

    // System State
    if (context.systemState != null) {
      buffer.writeln('SYSTEM STATE:');
      final sys = context.systemState!;
      buffer.writeln('  GPIO: ${sys.gpioEnabled ? "Enabled" : "Disabled"}');
      buffer.writeln('  ESP32: ${sys.esp32Connected ? "Connected" : "Disconnected"}');
      buffer.writeln('  RTC: ${sys.rtcSynced ? "Synced" : "Not synced"}');
      buffer.writeln('  Timezone: ${sys.timezone}');
      buffer.writeln('  Uptime: ${(sys.uptimeSeconds / 3600).toStringAsFixed(1)}h');
      buffer.writeln('');
    }

    // Alert History
    buffer.writeln('RECENT ALERT HISTORY:');
    for (var alert in context.alertHistory.take(10)) {
      if (alert.acknowledgedAt != null) continue;
      final resolved = alert.acknowledgedAt != null ? '[RESOLVED]' : '[ACTIVE]';
      buffer.writeln('  - $resolved ${alert.title}');
    }
    buffer.writeln('');

    // Calibrations
    buffer.writeln('SENSOR CALIBRATIONS:');
    for (var cal in context.sensorCalibrations.values) {
      final lastCal = '${DateTime.now().difference(DateTime.parse(cal.calibrationDate)).inDays} days ago';
      buffer.writeln('  - ${cal.parameterName}: offset ${cal.offsetValue}, slope ${cal.scaleFactor}, last cal: $lastCal');
      if (cal.parameterName == 'ph' && (cal.offsetValue.abs() > 0.5 || cal.scaleFactor < 0.8 || cal.scaleFactor > 1.2)) {  }
    }
    buffer.writeln('');

    // Guardian Config
    if (context.config != null) {
      buffer.writeln('GUARDIAN SETTINGS:');
      buffer.writeln('  - Vision: ${context.config!['vision_enabled'] == 1}');
      buffer.writeln('  - Voice: ${context.config!['voice_enabled'] == 1}');
      buffer.writeln('  - Check Interval: ${context.config!['check_interval_hours']}h');
    }
    buffer.writeln('');

    // AI Action Capabilities (if enabled)
    if (includeActionCapabilities && context.config != null && context.config!['actions_enabled'] == 1) {
      buffer.writeln('--- AI ACTION CAPABILITIES ---');
      buffer.writeln('You have permission to execute actions if appropriate.');
      buffer.writeln('Enabled capabilities:');
      
      final permissions = context.config!['action_permissions'];
      if (permissions != null && permissions is Map) {
        permissions.forEach((key, enabled) {
          if (enabled == true) {
            buffer.writeln('  - $key: ENABLED');
          }
        });
      }
      
      buffer.writeln('');
      buffer.writeln('To execute an action, respond with a JSON block:');
      buffer.writeln('```action');
      buffer.writeln('{');
      buffer.writeln('  "action_type": "set_ph_target",');
      buffer.writeln('  "category": "fertigation_ph",');
      buffer.writeln('  "description": "Adjust pH target to 6.0-6.5",');
      buffer.writeln('  "parameters": {"min": 6.0, "max": 6.5},');
      buffer.writeln('  "reasoning": "Current pH is 7.2, outside optimal range"');
      buffer.writeln('}');
      buffer.writeln('```');
      buffer.writeln('');
      
      if (context.config!['require_confirmation'] == 1) {
        buffer.writeln('NOTE: User confirmation is required before execution.');
      }
      buffer.writeln('');
    }

    // 5. Alerts
    if (context.recentAlerts.isNotEmpty) {
      buffer.writeln('--- ACTIVE ALERTS ---');
      for (var alert in context.recentAlerts) {
        buffer.writeln('- [${alert.severity.toUpperCase()}] ${alert.title}: ${alert.message}');
      }
      buffer.writeln('');
    }

    // 6. User Query
    buffer.writeln('--- USER QUERY ---');
    buffer.writeln(userQuery);

    return buffer.toString();
  }
}

class GuardianAdviceResponse {
  final bool success;
  final String message;
  final String? error;
  final GuardianAction? suggestedAction;
  final bool requiresConfirmation;
  final int tokensUsed;

  GuardianAdviceResponse({
    required this.success,
    required this.message,
    this.error,
    this.suggestedAction,
    this.requiresConfirmation = true,
    this.tokensUsed = 0,
  });
}
