import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/guardian_config.dart';
import '../../models/guardian/guardian_action.dart';

class GuardianActionService {
  static final GuardianActionService _instance = GuardianActionService._internal();
  factory GuardianActionService() => _instance;
  GuardianActionService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  
  // Action cooldown tracking
  final Map<String, DateTime> _lastActionTime = {};

  /// Check if an action type is permitted for this zone
  Future<bool> isActionPermitted(int zoneId, String actionCategory) async {
    final config = await _db.getGuardianConfig(zoneId);
    if (config == null || !config.actionsEnabled) return false;
    return config.actionPermissions[actionCategory] ?? false;
  }

  /// Execute an action with safety checks
  Future<ActionResult> executeAction(GuardianAction action) async {
    // 1. Verify permissions
    if (!await isActionPermitted(action.zoneId, action.category)) {
      return ActionResult(
        success: false,
        message: 'Action not permitted. Enable "${action.category}" in Guardian settings.',
        action: action,
      );
    }

    // 2. Check cooldown
    final cooldownKey = '${action.zoneId}_${action.category}';
    final config = await _db.getGuardianConfig(action.zoneId);
    final cooldownMinutes = config?.actionCooldownMinutes ?? 5;
    
    if (_lastActionTime.containsKey(cooldownKey)) {
      final elapsed = DateTime.now().difference(_lastActionTime[cooldownKey]!);
      if (elapsed.inMinutes < cooldownMinutes) {
        return ActionResult(
          success: false,
          message: 'Cooldown active. Wait ${cooldownMinutes - elapsed.inMinutes} minutes.',
          action: action,
        );
      }
    }

    // 3. Validate parameters are within safe bounds
    final validation = _validateAction(action);
    if (!validation.isValid) {
      return ActionResult(
        success: false,
        message: validation.reason,
        action: action,
      );
    }

    // 4. Execute the action
    try {
      await _executeActionInternal(action);
      
      // 5. Log the action
      await _logAction(action, success: true);
      
      // 6. Update cooldown
      _lastActionTime[cooldownKey] = DateTime.now();

      return ActionResult(
        success: true,
        message: 'Action completed: ${action.description}',
        action: action,
      );
    } catch (e) {
      await _logAction(action, success: false, error: e.toString());
      return ActionResult(
        success: false,
        message: 'Action failed: $e',
        action: action,
      );
    }
  }

  ValidationResult _validateAction(GuardianAction action) {
    // Safety bounds for different action types
    switch (action.actionType) {
      case 'set_ph_target':
        final value = action.parameters['value'] as double?;
        if (value == null || value < 4.5 || value > 7.5) {
          return ValidationResult(false, 'pH target must be between 4.5 and 7.5');
        }
        break;
        
      case 'set_ec_target':
        final value = action.parameters['value'] as double?;
        if (value == null || value < 0.2 || value > 3.5) {
          return ValidationResult(false, 'EC target must be between 0.2 and 3.5');
        }
        break;
        
      case 'trigger_dose':
        final ml = action.parameters['ml'] as double?;
        final maxDose = action.parameters['max_dose'] as double? ?? 50.0;
        if (ml == null || ml <= 0 || ml > maxDose) {
          return ValidationResult(false, 'Dose must be between 0 and $maxDose ml');
        }
        break;
        
      case 'set_temperature_target':
        final value = action.parameters['value'] as double?;
        if (value == null || value < 15 || value > 35) {
          return ValidationResult(false, 'Temperature target must be between 15°C and 35°C');
        }
        break;
        
      // Add more validation for other action types
      default:
        break;
    }
    
    return ValidationResult(true, '');
  }

  Future<void> _executeActionInternal(GuardianAction action) async {
    switch (action.actionType) {
      case 'set_ph_target':
        await _db.updateFertigationTarget(
          action.zoneId, 
          'ph_min', 
          action.parameters['min'],
        );
        await _db.updateFertigationTarget(
          action.zoneId,
          'ph_max',
          action.parameters['max'],
        );
        break;
        
      case 'set_ec_target':
        await _db.updateFertigationTarget(
          action.zoneId, 
          'ec_min', 
          action.parameters['min'],
        );
        await _db.updateFertigationTarget(
          action.zoneId,
          'ec_max',
          action.parameters['max'],
        );
        break;
        
      case 'trigger_dose':
        // Call into FertigationService
        // await FertigationService().triggerDose(
        //   pumpId: action.parameters['pump_id'],
        //   ml: action.parameters['ml'],
        //   trigger: 'guardian_ai',
        // );
        debugPrint('Would trigger dose: ${action.parameters['ml']}ml of ${action.parameters['pump_type']}');
        break;
        
      case 'toggle_light':
        // await LightingService().setLightState(
        //   zoneId: action.zoneId,
        //   state: action.parameters['state'],
        // );
        debugPrint('Would toggle light: ${action.parameters['state']}');
        break;
        
      // Implement other action types as services become available
      default:
        debugPrint('Action type not yet implemented: ${action.actionType}');
        break;
    }
  }

  Future<void> _logAction(GuardianAction action, {required bool success, String? error}) async {
    await _db.insertGuardianActionLog(
      zoneId: action.zoneId,
      actionType: action.actionType,
      category: action.category,
      description: action.description,
      parameters: action.parameters,
      reasoning: action.reasoning,
      success: success,
      error: error,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Get action history for display
  Future<List<GuardianActionLog>> getActionHistory(int zoneId, {int limit = 50}) async {
    return await _db.getGuardianActionLogs(zoneId, limit: limit);
  }
}
