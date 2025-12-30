import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sprigrig/services/database_helper.dart';
import 'package:sprigrig/models/recipe_template.dart';
import 'package:sprigrig/models/recipe_phase.dart';
import 'package:sprigrig/models/zone_crop.dart';

void main() {
  // Initialize ffi loader
  sqfliteFfiInit();

  group('DatabaseHelper Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      databaseFactory = databaseFactoryFfi;
      // Delete the database to ensure a fresh start
      await databaseFactory.deleteDatabase(await DatabaseHelper().databasePath);
      dbHelper = DatabaseHelper();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Create and Read Recipe Template', () async {
      final template = {
        'name': 'Test Template',
        'category': 'custom',
        'description': 'Test Description',
        'total_cycle_days': 90,
        'is_system_template': 0,
        'created_by_user': 1,
      };

      final id = await dbHelper.createRecipeTemplate(template);
      expect(id, isPositive);

      final retrieved = await dbHelper.getRecipeTemplateById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!['name'], 'Test Template');
    });

    test('Create and Read Recipe Phase', () async {
      final templateId = await dbHelper.createRecipeTemplate({
        'name': 'Phase Test Template',
        'category': 'custom',
      });

      final phase = {
        'template_id': templateId,
        'phase_name': 'Test Phase',
        'phase_order': 1,
        'duration_days': 10,
        'light_hours_on': 18,
        'light_hours_off': 6,
      };

      final phaseId = await dbHelper.createRecipePhase(phase);
      expect(phaseId, isPositive);

      final phases = await dbHelper.getPhasesForTemplate(templateId);
      expect(phases.length, 1);
      expect(phases.first['phase_name'], 'Test Phase');
    });

    test('Assign Crop to Zone', () async {
      // Create a dummy zone first (assuming zones table exists and we can insert)
      // This might be tricky without a full mock, but let's try inserting a crop directly
      // assuming foreign key constraints might fail if zone doesn't exist.
      // For unit testing with sqflite_ffi, we are using a real in-memory db usually.
      
      // We need to ensure the database is initialized.
      final db = await dbHelper.database;
      
      // Insert a dummy zone
      final zoneId = await db.insert('zones', {
        'name': 'Test Zone',
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });

      final crop = {
        'zone_id': zoneId,
        'crop_name': 'Test Crop',
        'use_recipe_profile': 1,
        'is_active': 1,
      };

      final cropId = await dbHelper.assignCropToZone(crop);
      expect(cropId, isPositive);

      final retrievedCrop = await dbHelper.getZoneCrop(zoneId);
      expect(retrievedCrop, isNotNull);
      expect(retrievedCrop!['crop_name'], 'Test Crop');
    });
  });
}
