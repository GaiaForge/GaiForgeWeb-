// lib/services/database_helper.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/zone.dart';
import '../models/plant.dart';
import '../models/grow.dart';
import '../models/timer.dart';
import '../models/sensor.dart';
import '../models/system_config.dart';
import '../models/io_channel.dart';
import '../models/environmental_control.dart';
import '../models/camera_assignment.dart';
import '../models/astral_simulation_settings.dart';
import '../models/camera.dart' as camera_model;
import '../models/image_info.dart';
import '../models/irrigation_schedule.dart';
import '../models/lighting_schedule.dart';
import '../models/hvac_schedule.dart';

import '../models/location_settings.dart';
import '../models/sensor_hub.dart'; // NEW
import '../models/sensor_calibration.dart'; // NEW
import '../models/hub_diagnostic.dart'; // NEW
import '../models/fertigation_config.dart';
import '../models/fertigation_pump.dart';
import '../models/fertigation_probe.dart';
import '../models/fertigation_schedule.dart';
import '../models/guardian_config.dart';
import '../models/guardian_report.dart';
import '../models/guardian_alert.dart';
import '../models/guardian/guardian_action.dart';
import '../models/user.dart';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;
  static const int _databaseVersion = 42;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<String> get databasePath async {
    if (Platform.isAndroid || Platform.isIOS) {
      return join(await getDatabasesPath(), 'sprigrig.db');
    } else {
      // For development/desktop platforms, use a local directory
      final appDataDir = Directory('sprigrig_data');
      if (!await appDataDir.exists()) {
        await appDataDir.create(recursive: true);
      }
      return join(appDataDir.path, 'sprigrig.db');
    }
  }

  Future<Database> _initDatabase() async {
    String path = await databasePath;
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDatabase(Database db, int version) async {
    try {
      debugPrint('Creating database tables...');
      await _createAllTables(db);
      // Preload system recipe templates after tables are created (includes crop management tables)
      await _preloadSystemTemplates(db);
      // Note: grow_modes, control_types, and io_channels seeding is handled in _createAllTables

      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Error creating database: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Version 2: Add new grow modes
      debugPrint('Applying version 2 migration: Adding new grow modes');
      
      final newModes = [
        {'id': 3, 'name': 'aeroponic', 'description': 'Aeroponic growing', 'is_system': 1},
        {'id': 4, 'name': 'drip', 'description': 'Drip irrigation', 'is_system': 1},
        {'id': 5, 'name': 'ebb_and_flow', 'description': 'Ebb and Flow (Flood and Drain)', 'is_system': 1},
        {'id': 6, 'name': 'nft', 'description': 'Nutrient Film Technique', 'is_system': 1},
      ];

      for (final mode in newModes) {
        final existing = await db.query('grow_modes', where: 'id = ?', whereArgs: [mode['id']]);
        if (existing.isEmpty) {
          await db.insert('grow_modes', mode);
        }
      }
    }

    if (oldVersion < 3) {
      // Version 3: Add schedule tables
      debugPrint('Applying version 3 migration: Adding schedule tables');
      await _createScheduleTables(db);
    }

    if (oldVersion < 4) {
      // Version 4: Ensure lighting_settings table exists (added post-v3)
      debugPrint('Applying version 4 migration: Ensuring schedule tables exist');
      await _createScheduleTables(db);
    }

    if (oldVersion < 5) {
      // Version 5: Add calibration_offset to sensors table
      debugPrint('Applying version 5 migration: Adding calibration_offset to sensors table');
      try {
        await db.execute('ALTER TABLE sensors ADD COLUMN calibration_offset REAL DEFAULT 0.0');
      } catch (e) {
        // Ignore if column already exists (e.g. if created via createAllTables in dev)
        debugPrint('Error adding calibration_offset column (might already exist): $e');
      }
    }

    if (oldVersion < 6) {
      // Version 6: Add pump_id to irrigation_schedules
      debugPrint('Applying version 6 migration: Adding pump_id to irrigation_schedules');
      try {
        await db.execute('ALTER TABLE irrigation_schedules ADD COLUMN pump_id INTEGER');
      } catch (e) {
        debugPrint('Error adding pump_id column: $e');
      }
    }
    if (oldVersion < 7) {
      // Version 7: Add display_order to sensors
      debugPrint('Applying version 7 migration: Adding display_order to sensors');
      try {
        await db.execute('ALTER TABLE sensors ADD COLUMN display_order INTEGER DEFAULT 0');
      } catch (e) {
        debugPrint('Error adding display_order column: $e');
      }
    }
    if (oldVersion < 23) {
      // Version 23: Add grow_method to zones
      debugPrint('Applying version 23 migration: Adding grow_method to zones');
      try {
        await db.execute('ALTER TABLE zones ADD COLUMN grow_method TEXT');
      } catch (e) {
        debugPrint('Error adding grow_method column: $e');
      }
    }
    if (oldVersion < 24) {
      // Version 24: Rename default IO channels to generic names
      debugPrint('Applying version 24 migration: Rename default IO channels');
      try {
        final batch = db.batch();
        for (int i = 0; i < 8; i++) {
          batch.update(
            'io_channels',
            {'name': 'Waveshare Relay ${i + 1}'},
            where: 'module_number = ? AND channel_number = ?',
            whereArgs: [100, i],
          );
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Error applying version 24 migration: $e');
      }
    }
    if (oldVersion < 28) {
      // Version 28: Add seedling_mat_settings table
      debugPrint('Applying version 28 migration: Adding seedling_mat_settings table');
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS seedling_mat_settings (
            zone_id INTEGER PRIMARY KEY,
            enabled INTEGER DEFAULT 0,
            mode TEXT DEFAULT 'manual',
            target_temp REAL DEFAULT 24.0,
            auto_off_enabled INTEGER DEFAULT 0,
            auto_off_days INTEGER DEFAULT 14,
            sensor_id INTEGER,
            created_at INTEGER,
            updated_at INTEGER,
            FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE
          )
        ''');
      } catch (e) {
        debugPrint('Error adding seedling_mat_settings table: $e');
      }
    }

    if (oldVersion < 34) {
      // Version 34: Recreate Guardian tables and add Zone flags
      debugPrint('Applying version 34 migration: Recreating Guardian tables and adding Zone flags');
      try {
        await db.execute('DROP TABLE IF EXISTS guardian_config');
        await _createGuardianTables(db);
      } catch (e) {
        debugPrint('Error recreating guardian_config: $e');
      }

      try {
        await db.execute('ALTER TABLE zones ADD COLUMN has_fertigation INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        debugPrint('Error adding has_fertigation column: $e');
      }

      try {
        await db.execute('ALTER TABLE zones ADD COLUMN has_guardian INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        debugPrint('Error adding has_guardian column: $e');
      }
    }

    if (oldVersion < 35) {
      // Version 35: Add fertigation columns to recipe_phases
      debugPrint('Applying version 35 migration: Adding fertigation columns to recipe_phases');
      try {
        await db.execute('ALTER TABLE recipe_phases ADD COLUMN fertigation_enabled INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE recipe_phases ADD COLUMN nutrient_a_ml_per_liter REAL');
        await db.execute('ALTER TABLE recipe_phases ADD COLUMN nutrient_b_ml_per_liter REAL');
        await db.execute('ALTER TABLE recipe_phases ADD COLUMN nutrient_c_ml_per_liter REAL');
        await db.execute('ALTER TABLE recipe_phases ADD COLUMN calmag_ml_per_liter REAL');
        await db.execute('ALTER TABLE recipe_phases ADD COLUMN silica_ml_per_liter REAL');
        await db.execute('ALTER TABLE recipe_phases ADD COLUMN enzymes_ml_per_liter REAL');
      } catch (e) {
        debugPrint('Error adding fertigation columns to recipe_phases: $e');
      }
    }

    if (oldVersion < 36) {
      // Version 36: Update fertigation_config for hybrid architecture
      debugPrint('Applying version 36 migration: Update fertigation_config');
      try {
        await db.execute("ALTER TABLE fertigation_config ADD COLUMN dosing_mode TEXT DEFAULT 'auto'");
        await db.execute('ALTER TABLE fertigation_config ADD COLUMN manual_ph_min REAL');
        await db.execute('ALTER TABLE fertigation_config ADD COLUMN manual_ph_max REAL');
        await db.execute('ALTER TABLE fertigation_config ADD COLUMN manual_ec_min REAL');
        await db.execute('ALTER TABLE fertigation_config ADD COLUMN manual_ec_max REAL');
        
        // Migrate old data if exists
        try {
          await db.execute('UPDATE fertigation_config SET manual_ph_min = ph_target_min, manual_ph_max = ph_target_max, manual_ec_min = ec_target');
        } catch (e) {
          // Ignore if old columns didn't exist
        }
      } catch (e) {
        debugPrint('Error updating fertigation_config: $e');
      }
    }

    if (oldVersion < 37) {
      // Version 37: Add sensor aggregation tables
      debugPrint('Applying version 37 migration: Add sensor aggregation tables');
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sensor_readings_hourly (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sensor_id INTEGER NOT NULL,
            reading_type TEXT NOT NULL,
            hour_timestamp INTEGER NOT NULL,
            avg_value REAL,
            min_value REAL,
            max_value REAL,
            sample_count INTEGER,
            FOREIGN KEY (sensor_id) REFERENCES sensors(id),
            UNIQUE(sensor_id, reading_type, hour_timestamp)
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS sensor_readings_daily (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sensor_id INTEGER NOT NULL,
            reading_type TEXT NOT NULL,
            day_timestamp INTEGER NOT NULL,
            avg_value REAL,
            min_value REAL,
            max_value REAL,
            sample_count INTEGER,
            FOREIGN KEY (sensor_id) REFERENCES sensors(id),
            UNIQUE(sensor_id, reading_type, day_timestamp)
          )
        ''');

        await db.execute('CREATE INDEX IF NOT EXISTS idx_readings_sensor_time ON sensor_readings(sensor_id, reading_type, timestamp)');
      } catch (e) {
        debugPrint('Error creating aggregation tables: $e');
      }
    }


    if (oldVersion < 38) {
      // Version 38: Guardian AI Actions System
      debugPrint('Applying version 38 migration: Guardian AI Actions');
      try {
        // Add action fields to guardian_settings
        await db.execute('ALTER TABLE guardian_settings ADD COLUMN actions_enabled INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE guardian_settings ADD COLUMN action_permissions TEXT DEFAULT "{}"');
        await db.execute('ALTER TABLE guardian_settings ADD COLUMN require_confirmation INTEGER DEFAULT 1');
        await db.execute('ALTER TABLE guardian_settings ADD COLUMN action_cooldown_minutes INTEGER DEFAULT 5');

        // Create guardian_action_log table
        await db.execute('''
          CREATE TABLE guardian_action_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            zone_id INTEGER NOT NULL,
            action_type TEXT NOT NULL,
            category TEXT NOT NULL,
            description TEXT NOT NULL,
            parameters TEXT NOT NULL,
            reasoning TEXT,
            success INTEGER NOT NULL,
            error TEXT,
            timestamp INTEGER NOT NULL,
            FOREIGN KEY (zone_id) REFERENCES zones(id)
          )
        ''');

        await db.execute('CREATE INDEX idx_guardian_actions_zone ON guardian_action_log(zone_id)');
        await db.execute('CREATE INDEX idx_guardian_actions_time ON guardian_action_log(timestamp)');
      } catch (e) {
        debugPrint('Error applying Guardian Actions migration: $e');
      }
    }

    if (oldVersion < 30) {
      // Version 30: Add astral_simulation and astral_daily_cache tables
      debugPrint('Applying version 30 migration: Adding astral simulation tables');
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS astral_simulation (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            zone_id INTEGER NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
            enabled INTEGER DEFAULT 0,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            location_name TEXT,
            timezone TEXT,
            simulation_mode TEXT DEFAULT 'full_year',
            include_spring INTEGER DEFAULT 1,
            include_summer INTEGER DEFAULT 1,
            include_fall INTEGER DEFAULT 1,
            include_winter INTEGER DEFAULT 1,
            range_start_month INTEGER,
            range_start_day INTEGER,
            range_end_month INTEGER,
            range_end_day INTEGER,
            fixed_month INTEGER,
            fixed_day INTEGER,
            time_compression REAL DEFAULT 1.0,
            simulation_start_date INTEGER,
            current_simulated_date INTEGER,
            sunrise_offset_minutes INTEGER DEFAULT 0,
            sunset_offset_minutes INTEGER DEFAULT 0,
            use_intensity_curve INTEGER DEFAULT 0,
            dawn_duration_minutes INTEGER DEFAULT 30,
            dusk_duration_minutes INTEGER DEFAULT 30,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
            updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS astral_daily_cache (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            zone_id INTEGER NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
            simulated_date TEXT NOT NULL,
            sunrise_time TEXT NOT NULL,
            sunset_time TEXT NOT NULL,
            day_length_minutes INTEGER NOT NULL,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
            UNIQUE(zone_id, simulated_date)
          )
        ''');
      } catch (e) {
        debugPrint('Error creating astral simulation tables: $e');
      }
    }

    if (oldVersion < 32) {
      // Version 32: Ensure seedling_mat_settings table exists (fix for missing table in v30/v31)
      debugPrint('Applying version 32 migration: Ensuring seedling_mat_settings table exists');
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS seedling_mat_settings (
            zone_id INTEGER PRIMARY KEY,
            enabled INTEGER DEFAULT 0,
            mode TEXT DEFAULT 'manual',
            target_temp REAL DEFAULT 24.0,
            auto_off_enabled INTEGER DEFAULT 0,
            auto_off_days INTEGER DEFAULT 14,
            sensor_id INTEGER,
            created_at INTEGER,
            updated_at INTEGER,
            FOREIGN KEY (zone_id) REFERENCES zones (id) ON DELETE CASCADE
          )
        ''');
      } catch (e) {
        debugPrint('Error creating seedling_mat_settings table in v32 migration: $e');
      }
    }
    if (oldVersion < 29) {
      // Version 29: Add auto-cleanup columns to cameras
      debugPrint('Applying version 29 migration: Adding auto-cleanup columns to cameras');
      try {
        await db.execute('ALTER TABLE cameras ADD COLUMN auto_cleanup_enabled INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE cameras ADD COLUMN retention_days INTEGER');
        await db.execute('ALTER TABLE cameras ADD COLUMN max_photos INTEGER');
      } catch (e) {
        debugPrint('Error applying version 29 migration: $e');
      }
    }
    if (oldVersion < 8) {
      // Version 8: Populate default IO channels
      debugPrint('Applying version 8 migration: Populating default IO channels');
      try {
        // Check if channels exist first
        final List<Map<String, dynamic>> existing = await db.query('io_channels');
        if (existing.isEmpty) {
          final batch = db.batch();
          for (int i = 1; i <= 8; i++) {
            batch.insert('io_channels', {
              'channel_number': i,
              'module_number': 1,
              'is_input': 0,
              'name': 'Channel $i',
              'is_assigned': 0,
              'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
              'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            });
          }
          await batch.commit();
          debugPrint('Created 8 default IO channels');
        }
      } catch (e) {
        debugPrint('Error populating IO channels: $e');
      }
    }
    if (oldVersion < 9) {
      // Version 9: Add irrigation_settings table
      debugPrint('Applying version 9 migration: Adding irrigation_settings table');
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS irrigation_settings (
            zone_id INTEGER PRIMARY KEY,
            mode TEXT NOT NULL,
            sync_mode TEXT NOT NULL,
            sunrise_offset INTEGER NOT NULL,
            sunset_offset INTEGER NOT NULL,
            FOREIGN KEY (zone_id) REFERENCES zones (id)
          )
        ''');
      } catch (e) {
        debugPrint('Error creating irrigation_settings table: $e');
      }
    }
    if (oldVersion < 10) {
      // Version 10: Add aeration tables
      debugPrint('Applying version 10 migration: Adding aeration tables');
      await _createAerationTables(db);
    }

    if (oldVersion < 11) {
      // Version 11: Add feature flags to zones and reservoir settings to irrigation_settings
      debugPrint('Applying version 11 migration: Adding feature flags and reservoir settings');
      try {
        await db.execute('ALTER TABLE zones ADD COLUMN has_irrigation INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE zones ADD COLUMN has_lighting INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE zones ADD COLUMN has_ventilation INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE zones ADD COLUMN has_aeration INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE zones ADD COLUMN has_cameras INTEGER DEFAULT 0');
        
        await db.execute('ALTER TABLE irrigation_settings ADD COLUMN target_water_level REAL');
        await db.execute('ALTER TABLE irrigation_settings ADD COLUMN refill_pump_id INTEGER');
      } catch (e) {
        debugPrint('Error applying version 11 migration: $e');
      }
    }

    if (oldVersion < 12) {
      // Version 12: Distributed Sensor Hub Architecture
      debugPrint('Applying version 12 migration: Distributed Sensor Hub Architecture');
      try {
        // Create Sensor Hubs table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sensor_hubs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            modbus_address INTEGER UNIQUE NOT NULL CHECK (modbus_address BETWEEN 1 AND 247),
            name TEXT NOT NULL,
            zone_id INTEGER REFERENCES zones(id),
            status TEXT DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'error', 'maintenance')),
            last_seen TEXT,
            firmware_version TEXT,
            hardware_revision TEXT,
            total_channels INTEGER DEFAULT 8,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Create Sensor Calibrations table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sensor_calibrations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sensor_id INTEGER REFERENCES sensors(id) ON DELETE CASCADE,
            parameter_name TEXT NOT NULL,
            offset_value REAL DEFAULT 0.0,
            scale_factor REAL DEFAULT 1.0,
            reference_low REAL,
            reference_high REAL,
            measured_low REAL,
            measured_high REAL,
            calibration_date TEXT DEFAULT CURRENT_TIMESTAMP,
            next_calibration_due TEXT,
            calibrated_by TEXT,
            notes TEXT
          )
        ''');

        // Create Hub Diagnostics table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS hub_diagnostics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            hub_id INTEGER REFERENCES sensor_hubs(id) ON DELETE CASCADE,
            timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
            communication_errors INTEGER DEFAULT 0,
            successful_reads INTEGER DEFAULT 0,
            average_response_time_ms REAL,
            last_error_message TEXT
          )
        ''');

        // Alter Sensors table
        await db.execute('ALTER TABLE sensors ADD COLUMN hub_id INTEGER REFERENCES sensor_hubs(id)');
        await db.execute('ALTER TABLE sensors ADD COLUMN input_channel INTEGER CHECK (input_channel BETWEEN 1 AND 8)');
        await db.execute("ALTER TABLE sensors ADD COLUMN input_type TEXT CHECK (input_type IN ('i2c', 'spi', 'analog_0_10v', 'analog_4_20ma'))");
        await db.execute('ALTER TABLE sensors ADD COLUMN i2c_address TEXT');
        await db.execute('ALTER TABLE sensors ADD COLUMN spi_cs_pin INTEGER');
        await db.execute('ALTER TABLE sensors ADD COLUMN sample_rate_seconds INTEGER DEFAULT 60');
        await db.execute('ALTER TABLE sensors ADD COLUMN is_active INTEGER DEFAULT 1');

      } catch (e) {
        debugPrint('Error applying version 12 migration: $e');
      }
    }

    if (oldVersion < 13) {
      // Version 13: Crop Management
      debugPrint('Applying version 13 migration: Crop Management');
      try {
        // Create Recipe Templates table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS recipe_templates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT CHECK (category IN ('cannabis','tomatoes','leafy_greens','herbs','strawberries','peppers','microgreens','cucumbers','custom')),
            description TEXT,
            total_cycle_days INTEGER,
            is_system_template INTEGER DEFAULT 0,
            created_by_user INTEGER DEFAULT 1,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
          );
        ''');

        // Create Recipe Phases table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS recipe_phases (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            template_id INTEGER REFERENCES recipe_templates(id) ON DELETE CASCADE,
            phase_name TEXT NOT NULL,
            phase_order INTEGER NOT NULL,
            duration_days INTEGER NOT NULL,
            light_hours_on INTEGER,
            light_hours_off INTEGER,
            light_intensity_percent REAL,
            target_temp_day REAL,
            target_temp_night REAL,
            target_humidity REAL,
            target_ph_min REAL,
            target_ph_max REAL,
            target_ec_min REAL,
            target_ec_max REAL,
            watering_frequency_hours INTEGER,
            watering_duration_minutes INTEGER,
            aeration_on_minutes INTEGER,
            aeration_off_minutes INTEGER,
            notes TEXT,
            fertigation_enabled INTEGER DEFAULT 0,
            nutrient_a_ml_per_liter REAL,
            nutrient_b_ml_per_liter REAL,
            nutrient_c_ml_per_liter REAL,
            calmag_ml_per_liter REAL,
            silica_ml_per_liter REAL,
            enzymes_ml_per_liter REAL,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
          );
        ''');

        // Create Zone Crops table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS zone_crops (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            zone_id INTEGER REFERENCES zones(id) ON DELETE CASCADE,
            crop_name TEXT NOT NULL,
            template_id INTEGER REFERENCES recipe_templates(id),
            current_phase_id INTEGER REFERENCES recipe_phases(id),
            phase_start_date TEXT,
            grow_start_date TEXT,
            expected_harvest_date TEXT,
            use_recipe_profile INTEGER DEFAULT 1,
            is_active INTEGER DEFAULT 1,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
          );
        ''');
        
        // Preload system templates
        await _preloadSystemTemplates(db);

      } catch (e) {
        debugPrint('Error applying version 13 migration: $e');
      }
    }

    if (oldVersion < 14) {
      // Version 14: Fix orphaned IO assignments
      debugPrint('Applying version 14 migration: Cleanup orphaned IO assignments');
      try {
        // 1. Reset is_assigned for all channels
        await db.update('io_channels', {'is_assigned': 0});

        // 2. Re-calculate is_assigned based on existing assignments
        
        // From control_io_assignments
        final assignments = await db.query('control_io_assignments', columns: ['io_channel_id']);
        for (var a in assignments) {
          await db.update('io_channels', {'is_assigned': 1}, where: 'id = ?', whereArgs: [a['io_channel_id']]);
        }

        // From irrigation_schedules
        // Check if pump_id column exists first
        final tableInfo = await db.rawQuery("PRAGMA table_info(irrigation_schedules)");
        final hasPumpId = tableInfo.any((c) => c['name'] == 'pump_id');
        
        if (hasPumpId) {
          final schedules = await db.query('irrigation_schedules', columns: ['pump_id']);
          for (var s in schedules) {
            if (s['pump_id'] != null) {
              await db.update('io_channels', {'is_assigned': 1}, where: 'id = ?', whereArgs: [s['pump_id']]);
            }
          }
        }
        
      } catch (e) {
        debugPrint('Error applying version 14 migration: $e');
      }
    }

    if (oldVersion < 15) {
      // Version 15: Update system templates with detailed phases
      debugPrint('Applying version 15 migration: Update system templates');
      try {
        // Delete existing SYSTEM templates to force reload
        await db.delete('recipe_templates', where: 'is_system_template = ?', whereArgs: [1]);
        // Cascade delete should handle phases
        
        await _preloadSystemTemplates(db);
      } catch (e) {
        debugPrint('Error applying version 15 migration: $e');
      }
    }

    if (oldVersion < 16) {
      // Version 16: Add is_enabled toggle to schedules
      debugPrint('Applying version 16 migration: Add is_enabled to schedules');
      try {
        final tables = ['irrigation_schedules', 'lighting_schedules', 'ventilation_schedules', 'aeration_schedules'];
        for (var table in tables) {
          // Check if table exists first (aeration might not be created for all users yet if they didn't have hydro)
          // But _createAllTables creates them if not exists.
          // Let's just try adding the column.
          try {
             await db.execute('ALTER TABLE $table ADD COLUMN is_enabled INTEGER NOT NULL DEFAULT 1');
          } catch (e) {
             debugPrint('Error adding column to $table: $e');
             // Ignore if table doesn't exist or column already exists
          }
        }
      } catch (e) {
        debugPrint('Error applying version 16 migration: $e');
      }
    }

    if (oldVersion < 17) {
      // Version 17: Add float sensor IDs to irrigation_settings
      debugPrint('Applying version 17 migration: Add float sensor IDs to irrigation_settings');
      try {
        await db.execute('ALTER TABLE irrigation_settings ADD COLUMN upper_float_sensor_id INTEGER');
        await db.execute('ALTER TABLE irrigation_settings ADD COLUMN lower_float_sensor_id INTEGER');
      } catch (e) {
        debugPrint('Error applying version 17 migration: $e');
      }
    }

    if (oldVersion < 18) {
      // Version 18: Cleanup orphaned IO assignments and zone controls
      debugPrint('Applying version 18 migration: Cleanup orphaned IO assignments');
      try {
        // 1. Delete zone controls that belong to non-existent zones
        await db.execute('''
          DELETE FROM zone_controls 
          WHERE zone_id NOT IN (SELECT id FROM zones)
        ''');
        
        // 2. Delete assignments that belong to non-existent zone controls
        await db.execute('''
          DELETE FROM control_io_assignments 
          WHERE zone_control_id NOT IN (SELECT id FROM zone_controls)
        ''');
        
        // 3. Reset all IO channels to unassigned
        await db.update('io_channels', {'is_assigned': 0});
        
        // 4. Re-assign based on valid assignments
        final assignments = await db.query('control_io_assignments', columns: ['io_channel_id']);
        for (var a in assignments) {
          await db.update(
            'io_channels', 
            {'is_assigned': 1}, 
            where: 'id = ?', 
            whereArgs: [a['io_channel_id']]
          );
        }
        
        // 5. Also check irrigation schedules (old method)
        final schedules = await db.query('irrigation_schedules', columns: ['pump_id']);
        for (var s in schedules) {
          if (s['pump_id'] != null) {
            await db.update(
              'io_channels', 
              {'is_assigned': 1}, 
              where: 'id = ?', 
              whereArgs: [s['pump_id']]
            );
          }
        }
        
      } catch (e) {
        debugPrint('Error applying version 18 migration: $e');
      }
    }

    if (oldVersion < 19) {
      // Version 19: Retry cleanup of orphaned IO assignments with correct dependency order
      debugPrint('Applying version 19 migration: Cleanup orphaned IO assignments (Retry)');
      try {
        // 1. Delete dependencies of orphaned controls first (to avoid FK constraints)
        // Orphaned controls are those where zone_id is not in zones table
        
        await db.execute('''
          DELETE FROM control_io_assignments 
          WHERE zone_control_id IN (SELECT id FROM zone_controls WHERE zone_id NOT IN (SELECT id FROM zones))
        ''');
        
        await db.execute('''
          DELETE FROM control_settings 
          WHERE zone_control_id IN (SELECT id FROM zone_controls WHERE zone_id NOT IN (SELECT id FROM zones))
        ''');
        
        await db.execute('''
          DELETE FROM control_schedules 
          WHERE zone_control_id IN (SELECT id FROM zone_controls WHERE zone_id NOT IN (SELECT id FROM zones))
        ''');
        
        await db.execute('''
          DELETE FROM control_status_log 
          WHERE zone_control_id IN (SELECT id FROM zone_controls WHERE zone_id NOT IN (SELECT id FROM zones))
        ''');

        // 2. Now delete the orphaned zone controls
        await db.execute('''
          DELETE FROM zone_controls 
          WHERE zone_id NOT IN (SELECT id FROM zones)
        ''');
        
        // 3. Delete any remaining orphaned assignments (pointing to non-existent controls)
        await db.execute('''
          DELETE FROM control_io_assignments 
          WHERE zone_control_id NOT IN (SELECT id FROM zone_controls)
        ''');
        
        // 4. Reset all IO channels to unassigned
        await db.update('io_channels', {'is_assigned': 0});
        
        // 5. Re-assign based on valid assignments
        final assignments = await db.query('control_io_assignments', columns: ['io_channel_id']);
        for (var a in assignments) {
          await db.update(
            'io_channels', 
            {'is_assigned': 1}, 
            where: 'id = ?', 
            whereArgs: [a['io_channel_id']]
          );
        }
        
        // 6. Also check irrigation schedules (old method)
        final schedules = await db.query('irrigation_schedules', columns: ['pump_id']);
        for (var s in schedules) {
          if (s['pump_id'] != null) {
            await db.update(
              'io_channels', 
              {'is_assigned': 1}, 
              where: 'id = ?', 
              whereArgs: [s['pump_id']]
            );
          }
        }
        
      } catch (e) {
        debugPrint('Error applying version 19 migration: $e');
      }
    }

    if (oldVersion < 20) {
      // Version 20: Aggressive cleanup of orphaned assignments and controls
      debugPrint('Applying version 20 migration: Aggressive cleanup');
      try {
        // 1. Delete ALL assignments that point to controls that don't have a valid zone
        await db.execute('''
          DELETE FROM control_io_assignments 
          WHERE zone_control_id IN (
            SELECT id FROM zone_controls 
            WHERE zone_id NOT IN (SELECT id FROM zones)
          )
        ''');

        // 2. Delete ALL settings for orphaned controls
        await db.execute('''
          DELETE FROM control_settings 
          WHERE zone_control_id IN (
            SELECT id FROM zone_controls 
            WHERE zone_id NOT IN (SELECT id FROM zones)
          )
        ''');
        
        // 3. Delete ALL schedules for orphaned controls
        await db.execute('''
          DELETE FROM control_schedules 
          WHERE zone_control_id IN (
            SELECT id FROM zone_controls 
            WHERE zone_id NOT IN (SELECT id FROM zones)
          )
        ''');
        
        // 4. Delete ALL status logs for orphaned controls
        await db.execute('''
          DELETE FROM control_status_log 
          WHERE zone_control_id IN (
            SELECT id FROM zone_controls 
            WHERE zone_id NOT IN (SELECT id FROM zones)
          )
        ''');

        // 5. Delete the orphaned zone controls themselves
        await db.execute('''
          DELETE FROM zone_controls 
          WHERE zone_id NOT IN (SELECT id FROM zones)
        ''');

        // 6. Delete any lingering assignments pointing to non-existent controls
        await db.execute('''
          DELETE FROM control_io_assignments 
          WHERE zone_control_id NOT IN (SELECT id FROM zone_controls)
        ''');

        // 7. Reset ALL IO channels to unassigned
        await db.update('io_channels', {'is_assigned': 0});

        // 8. Re-calculate assignments based on what's left
        // From control_io_assignments
        final assignments = await db.query('control_io_assignments', columns: ['io_channel_id']);
        for (var a in assignments) {
          if (a['io_channel_id'] != null) {
             await db.update(
              'io_channels', 
              {'is_assigned': 1}, 
              where: 'id = ?', 
              whereArgs: [a['io_channel_id']]
            );
          }
        }
        
        // From irrigation_schedules (legacy)
        final schedules = await db.query('irrigation_schedules', columns: ['pump_id']);
        for (var s in schedules) {
          if (s['pump_id'] != null) {
            await db.update(
              'io_channels', 
              {'is_assigned': 1}, 
              where: 'id = ?', 
              whereArgs: [s['pump_id']]
            );
          }
        }

      } catch (e) {
        debugPrint('Error applying version 20 migration: $e');
      }
    }

    if (oldVersion < 21) {
      // Version 21: Ensure schedule and settings tables exist (fix for missing tables in v20)
      debugPrint('Applying version 21 migration: Create missing schedule/settings tables');
      try {
        await _createScheduleTables(db);
        await _createAerationTables(db);
      } catch (e) {
        debugPrint('Error applying version 21 migration: $e');
      }
    }

    if (oldVersion < 22) {
      // Version 22: Ensure default IO channels exist
      debugPrint('Applying version 22 migration: Create default IO channels');
      try {
        await _createDefaultIoChannels(db);
      } catch (e) {
        debugPrint('Error applying version 22 migration: $e');
      }
    }
    if (oldVersion < 25) {
      // Version 25: Add type to io_channels
      debugPrint('Applying version 25 migration: Add type to io_channels');
      try {
        await db.execute('ALTER TABLE io_channels ADD COLUMN type TEXT');
      } catch (e) {
        debugPrint('Error applying version 25 migration: $e');
      }
    }

    if (oldVersion < 26) {
      // Version 26: Add camera_index and model to cameras
      debugPrint('Applying version 26 migration: Add camera_index and model to cameras');
      try {
        await db.execute('ALTER TABLE cameras ADD COLUMN camera_index INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE cameras ADD COLUMN model TEXT');
      } catch (e) {
        debugPrint('Error applying version 26 migration: $e');
      }
    }

    if (oldVersion < 27) {
      // Version 27: Add only_when_lights_on to cameras
      debugPrint('Applying version 27 migration: Adding only_when_lights_on to cameras');
      try {
        await db.execute('ALTER TABLE cameras ADD COLUMN only_when_lights_on INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        debugPrint('Error applying version 27 migration: $e');
      }
    }

    
    if (oldVersion < 33) {
      // Version 33: Add Fertigation and Guardian systems
      debugPrint('Applying version 33 migration: Add Fertigation and Guardian systems');
      try {
        // Create new tables
        await _createAerationTables(db);
        await _createSensorHubTables(db);
    
        await _preloadSystemTemplates(db);
        
        // Add flags to zones table
        await db.execute('ALTER TABLE zones ADD COLUMN has_fertigation INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE zones ADD COLUMN has_guardian INTEGER DEFAULT 0');
      } catch (e) {
        debugPrint('Error applying version 33 migration: $e');
      }
    }

    if (oldVersion < 34) {
      // Version 34: Add Setpoint and Range to sensors
      debugPrint('Applying version 34 migration: Add Setpoint and Range to sensors');
      try {
        await db.execute('ALTER TABLE sensors ADD COLUMN setpoint_value REAL');
        await db.execute('ALTER TABLE sensors ADD COLUMN min_value REAL');
        await db.execute('ALTER TABLE sensors ADD COLUMN max_value REAL');
        await db.execute('ALTER TABLE sensors ADD COLUMN use_setpoint INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE sensors ADD COLUMN use_range INTEGER DEFAULT 0');
      } catch (e) {
        debugPrint('Error applying version 34 migration: $e');
      }
    }

    if (oldVersion < 35) {
      // Version 35: Add Guardian System tables
      debugPrint('Applying version 35 migration: Add Guardian System tables');
      try {
        // Guardian Settings
        await db.execute('''
          CREATE TABLE IF NOT EXISTS guardian_settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            zone_id INTEGER UNIQUE NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
            enabled INTEGER DEFAULT 0,
            api_key_configured INTEGER DEFAULT 0,
            check_interval_minutes INTEGER DEFAULT 60,
            vision_analysis_enabled INTEGER DEFAULT 1,
            vision_interval_hours INTEGER DEFAULT 24,
            notification_level TEXT DEFAULT 'warning' CHECK (notification_level IN ('info', 'warning', 'critical')),
            created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
            updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
          )
        ''');

        // Guardian Analyses (AI Reports)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS guardian_analyses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            zone_id INTEGER NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
            analysis_type TEXT NOT NULL CHECK (analysis_type IN ('quick', 'full', 'vision')),
            status TEXT NOT NULL,
            confidence REAL,
            summary TEXT,
            full_response TEXT,
            image_path TEXT,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
          )
        ''');

        // Guardian Alerts
        await db.execute('''
          CREATE TABLE IF NOT EXISTS guardian_alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            zone_id INTEGER NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
            severity TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
            category TEXT NOT NULL,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            reading_type TEXT,
            value REAL,
            acknowledged INTEGER DEFAULT 0,
            acknowledged_at INTEGER,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
          )
        ''');

        // Indexes
        await db.execute('CREATE INDEX IF NOT EXISTS idx_guardian_alerts_zone_time ON guardian_alerts(zone_id, created_at DESC)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_guardian_analyses_zone_time ON guardian_analyses(zone_id, created_at DESC)');

      } catch (e) {
        debugPrint('Error applying version 35 migration: $e');
      }
    }

    if (oldVersion < 36) {
      // Version 36: Fix missing sensor columns (Robust check)
      debugPrint('Applying version 36 migration: Fix missing sensor columns');
      try {
        // Check if columns exist
        final List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(sensors)');
        final columnNames = columns.map((c) => c['name'] as String).toList();

        if (!columnNames.contains('setpoint_value')) {
          await db.execute('ALTER TABLE sensors ADD COLUMN setpoint_value REAL');
        }
        if (!columnNames.contains('min_value')) {
          await db.execute('ALTER TABLE sensors ADD COLUMN min_value REAL');
        }
        if (!columnNames.contains('max_value')) {
          await db.execute('ALTER TABLE sensors ADD COLUMN max_value REAL');
        }
        if (!columnNames.contains('use_setpoint')) {
          await db.execute('ALTER TABLE sensors ADD COLUMN use_setpoint INTEGER DEFAULT 0');
        }
        if (!columnNames.contains('use_range')) {
          await db.execute('ALTER TABLE sensors ADD COLUMN use_range INTEGER DEFAULT 0');
        }
      } catch (e) {
        debugPrint('Error applying version 36 migration: $e');
      }
    }

    if (oldVersion < 37) {
      // Version 37: Add Voice and Camera settings to Guardian
      debugPrint('Applying version 37 migration: Add Voice and Camera settings');
      try {
        await db.execute('ALTER TABLE guardian_settings ADD COLUMN voice_enabled INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE guardian_settings ADD COLUMN wake_word TEXT DEFAULT "sprigrig"');
        await db.execute('ALTER TABLE guardian_settings ADD COLUMN microphone_device_id TEXT');
        await db.execute('ALTER TABLE guardian_settings ADD COLUMN speaker_device_id TEXT');
        await db.execute('ALTER TABLE guardian_settings ADD COLUMN proactive_voice INTEGER DEFAULT 1');
        await db.execute('ALTER TABLE guardian_settings ADD COLUMN camera_device_id TEXT');
        await db.execute('ALTER TABLE guardian_settings ADD COLUMN capture_on_schedule INTEGER DEFAULT 1');
      } catch (e) {
        debugPrint('Error applying version 37 migration: $e');
      }
    }
  }

  Future<void> _createScheduleTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS irrigation_schedules (
        id TEXT PRIMARY KEY,
        zone_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        days_json TEXT NOT NULL,
        pump_id INTEGER,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (zone_id) REFERENCES zones (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS lighting_schedules (
        id TEXT PRIMARY KEY,
        zone_id INTEGER NOT NULL,
        name TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        days_json TEXT,
        is_astral INTEGER DEFAULT 0,
        is_enabled INTEGER DEFAULT 1,
        created_at INTEGER DEFAULT (strftime('%s','now')),
        FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ventilation_schedules (
        id TEXT PRIMARY KEY,
        zone_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        speed INTEGER NOT NULL,
        days_json TEXT NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (zone_id) REFERENCES zones (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ventilation_settings (
        zone_id INTEGER PRIMARY KEY,
        mode TEXT NOT NULL,
        control_mode TEXT NOT NULL,
        always_on_speed REAL NOT NULL,
        FOREIGN KEY (zone_id) REFERENCES zones (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS lighting_settings (
        zone_id INTEGER PRIMARY KEY,
        mode TEXT NOT NULL,
        sync_mode TEXT NOT NULL,
        sunrise_offset INTEGER NOT NULL,
        sunset_offset INTEGER NOT NULL,
        FOREIGN KEY (zone_id) REFERENCES zones (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS irrigation_settings (
        zone_id INTEGER PRIMARY KEY,
        mode TEXT NOT NULL,
        sync_mode TEXT NOT NULL,
        sunrise_offset INTEGER NOT NULL,
        sunset_offset INTEGER NOT NULL,
        target_water_level REAL,
        refill_pump_id INTEGER,
        upper_float_sensor_id INTEGER,
        lower_float_sensor_id INTEGER,
        sensing_method TEXT DEFAULT 'digital',
        analog_sensor_id INTEGER,
        FOREIGN KEY (zone_id) REFERENCES zones (id)
      )
    ''');
  }

  Future<void> _createAerationTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS aeration_schedules (
        id TEXT PRIMARY KEY,
        zone_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        days_json TEXT NOT NULL,
        pump_id INTEGER,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (zone_id) REFERENCES zones (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS aeration_settings (
        zone_id INTEGER PRIMARY KEY,
        mode TEXT NOT NULL,
        always_on_enabled INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (zone_id) REFERENCES zones (id)
      )
    ''');
  }

  Future<void> _createSensorHubTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sensor_hubs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        modbus_address INTEGER NOT NULL UNIQUE,
        name TEXT NOT NULL,
        zone_id INTEGER,
        status TEXT DEFAULT 'offline',
        last_seen TEXT,
        firmware_version TEXT,
        hardware_revision TEXT,
        total_channels INTEGER DEFAULT 8,
        created_at TEXT NOT NULL,
        FOREIGN KEY (zone_id) REFERENCES zones (id)
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hub_diagnostics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hub_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        successful_reads INTEGER DEFAULT 0,
        communication_errors INTEGER DEFAULT 0,
        last_error_message TEXT,
        FOREIGN KEY (hub_id) REFERENCES sensor_hubs (id)
      )
    ''');
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        pin TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_login INTEGER
      )
    ''');
  }

  // Create all essential tables
  Future<void> _preloadSystemTemplates(Database db) async {
    // Check if any system templates exist
    final existing = await db.query('recipe_templates', where: 'is_system_template = ?', whereArgs: [1]);
    if (existing.isNotEmpty) return; // Already loaded

    // Helper to insert phases
    Future<void> insertPhases(int templateId, List<Map<String, dynamic>> phases) async {
      for (var phase in phases) {
        await db.insert('recipe_phases', {
          'template_id': templateId,
          'phase_name': phase['phase_name'],
          'phase_order': phase['phase_order'],
          'duration_days': phase['duration_days'],
          'light_hours_on': phase['light_hours_on'],
          'light_hours_off': phase['light_hours_off'],
          'light_intensity_percent': phase['light_intensity_percent'],
          'target_temp_day': phase['target_temp_day'],
          'target_temp_night': phase['target_temp_night'],
          'target_humidity': phase['target_humidity'],
          'target_ph_min': phase['target_ph_min'],
          'target_ph_max': phase['target_ph_max'],
          'target_ec_min': phase['target_ec_min'],
          'target_ec_max': phase['target_ec_max'],
          'watering_frequency_hours': phase['watering_frequency_hours'],
          'watering_duration_minutes': phase['watering_duration_minutes'],
          'aeration_on_minutes': phase['aeration_on_minutes'],
          'aeration_off_minutes': phase['aeration_off_minutes'],
          'notes': phase['notes'],
        });
      }
    }

    // 1. Cannabis
    int cannabisId = await db.insert('recipe_templates', {
      'name': 'Cannabis Standard',
      'category': 'cannabis',
      'description': 'Standard cannabis growth recipe',
      'total_cycle_days': 105, // Approx
      'is_system_template': 1,
      'created_by_user': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    await insertPhases(cannabisId, [
      {
        'phase_name': 'Germination',
        'phase_order': 1,
        'duration_days': 7,
        'light_hours_on': 24,
        'light_hours_off': 0,
        'light_intensity_percent': 25,
        'target_temp_day': 26.0,
        'target_temp_night': 26.0,
        'target_humidity': 80.0,
        'target_ph_min': 5.8,
        'target_ph_max': 6.2,
        'target_ec_min': 0.4,
        'target_ec_max': 0.8,
        'watering_frequency_hours': 24,
        'watering_duration_minutes': 2,
        'aeration_on_minutes': 15,
        'aeration_off_minutes': 45,
        'notes': 'High humidity is crucial.',
      },
      {
        'phase_name': 'Seedling',
        'phase_order': 2,
        'duration_days': 14,
        'light_hours_on': 18,
        'light_hours_off': 6,
        'light_intensity_percent': 50,
        'target_temp_day': 24.0,
        'target_temp_night': 20.0,
        'target_humidity': 70.0,
        'target_ph_min': 5.8,
        'target_ph_max': 6.2,
        'target_ec_min': 0.8,
        'target_ec_max': 1.2,
        'watering_frequency_hours': 12,
        'watering_duration_minutes': 5,
        'aeration_on_minutes': 15,
        'aeration_off_minutes': 45,
        'notes': 'Start mild nutrients.',
      },
      {
        'phase_name': 'Vegetative',
        'phase_order': 3,
        'duration_days': 42, // 6 weeks
        'light_hours_on': 18,
        'light_hours_off': 6,
        'light_intensity_percent': 75,
        'target_temp_day': 24.0,
        'target_temp_night': 20.0,
        'target_humidity': 60.0,
        'target_ph_min': 5.8,
        'target_ph_max': 6.2,
        'target_ec_min': 1.2,
        'target_ec_max': 1.8,
        'watering_frequency_hours': 6,
        'watering_duration_minutes': 10,
        'aeration_on_minutes': 30,
        'aeration_off_minutes': 30,
        'notes': 'Rapid growth phase.',
      },
      {
        'phase_name': 'Flowering',
        'phase_order': 4,
        'duration_days': 70, // 10 weeks
        'light_hours_on': 12,
        'light_hours_off': 12,
        'light_intensity_percent': 100,
        'target_temp_day': 22.0,
        'target_temp_night': 18.0,
        'target_humidity': 45.0,
        'target_ph_min': 6.0,
        'target_ph_max': 6.5,
        'target_ec_min': 1.8,
        'target_ec_max': 2.4,
        'watering_frequency_hours': 4,
        'watering_duration_minutes': 15,
        'aeration_on_minutes': 60,
        'aeration_off_minutes': 0,
        'notes': 'Bloom nutrients needed.',
      },
      {
        'phase_name': 'Flush/Harvest',
        'phase_order': 5,
        'duration_days': 14,
        'light_hours_on': 12,
        'light_hours_off': 12,
        'light_intensity_percent': 100,
        'target_temp_day': 20.0,
        'target_temp_night': 20.0,
        'target_humidity': 40.0,
        'target_ph_min': 6.0,
        'target_ph_max': 6.5,
        'target_ec_min': 0.0,
        'target_ec_max': 0.2,
        'watering_frequency_hours': 4,
        'watering_duration_minutes': 15,
        'aeration_on_minutes': 60,
        'aeration_off_minutes': 0,
        'notes': 'Plain water only.',
      },
    ]);

    // 2. Tomatoes
    int tomatoesId = await db.insert('recipe_templates', {
      'name': 'Tomatoes Standard',
      'category': 'tomatoes',
      'description': 'Standard tomato growth recipe',
      'total_cycle_days': 120,
      'is_system_template': 1,
      'created_by_user': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    await insertPhases(tomatoesId, [
      {
        'phase_name': 'Germination',
        'phase_order': 1,
        'duration_days': 10,
        'light_hours_on': 0, // Low light
        'light_hours_off': 24,
        'light_intensity_percent': 0,
        'target_temp_day': 24.0,
        'target_temp_night': 24.0,
        'target_humidity': 80.0,
        'target_ph_min': 5.8,
        'target_ph_max': 6.2,
        'target_ec_min': 0.5,
        'target_ec_max': 0.8,
        'watering_frequency_hours': 24,
        'watering_duration_minutes': 2,
        'aeration_on_minutes': 15,
        'aeration_off_minutes': 45,
        'notes': 'Keep moist and warm.',
      },
      {
        'phase_name': 'Seedling',
        'phase_order': 2,
        'duration_days': 21,
        'light_hours_on': 14,
        'light_hours_off': 10,
        'light_intensity_percent': 50,
        'target_temp_day': 22.0,
        'target_temp_night': 20.0,
        'target_humidity': 70.0,
        'target_ph_min': 5.8,
        'target_ph_max': 6.2,
        'target_ec_min': 1.0,
        'target_ec_max': 1.4,
        'watering_frequency_hours': 12,
        'watering_duration_minutes': 5,
        'aeration_on_minutes': 15,
        'aeration_off_minutes': 45,
        'notes': 'Develop roots.',
      },
      {
        'phase_name': 'Vegetative',
        'phase_order': 3,
        'duration_days': 35,
        'light_hours_on': 16,
        'light_hours_off': 8,
        'light_intensity_percent': 75,
        'target_temp_day': 24.0,
        'target_temp_night': 20.0,
        'target_humidity': 60.0,
        'target_ph_min': 5.8,
        'target_ph_max': 6.3,
        'target_ec_min': 2.0,
        'target_ec_max': 2.5,
        'watering_frequency_hours': 8,
        'watering_duration_minutes': 10,
        'aeration_on_minutes': 30,
        'aeration_off_minutes': 30,
        'notes': 'Structural growth.',
      },
      {
        'phase_name': 'Flowering/Fruit',
        'phase_order': 4,
        'duration_days': 70,
        'light_hours_on': 14,
        'light_hours_off': 10,
        'light_intensity_percent': 100,
        'target_temp_day': 22.0,
        'target_temp_night': 18.0,
        'target_humidity': 55.0,
        'target_ph_min': 6.0,
        'target_ph_max': 6.5,
        'target_ec_min': 2.5,
        'target_ec_max': 3.5,
        'watering_frequency_hours': 6,
        'watering_duration_minutes': 15,
        'aeration_on_minutes': 60,
        'aeration_off_minutes': 0,
        'notes': 'Support heavy feeding.',
      },
    ]);

    // 3. Leafy Greens
    int greensId = await db.insert('recipe_templates', {
      'name': 'Leafy Greens Mix',
      'category': 'leafy_greens',
      'description': 'Lettuce, spinach, kale',
      'total_cycle_days': 45,
      'is_system_template': 1,
      'created_by_user': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    await insertPhases(greensId, [
      {
        'phase_name': 'Germination',
        'phase_order': 1,
        'duration_days': 5,
        'light_hours_on': 0,
        'light_hours_off': 24,
        'light_intensity_percent': 0,
        'target_temp_day': 20.0,
        'target_temp_night': 20.0,
        'target_humidity': 75.0,
        'target_ph_min': 5.5,
        'target_ph_max': 6.5,
        'target_ec_min': 0.4,
        'target_ec_max': 0.8,
        'watering_frequency_hours': 24,
        'watering_duration_minutes': 2,
        'aeration_on_minutes': 15,
        'aeration_off_minutes': 45,
        'notes': 'Cooler temps preferred.',
      },
      {
        'phase_name': 'Growing',
        'phase_order': 2,
        'duration_days': 35,
        'light_hours_on': 14,
        'light_hours_off': 10,
        'light_intensity_percent': 70,
        'target_temp_day': 18.0,
        'target_temp_night': 16.0,
        'target_humidity': 65.0,
        'target_ph_min': 5.5,
        'target_ph_max': 6.5,
        'target_ec_min': 1.0,
        'target_ec_max': 1.6,
        'watering_frequency_hours': 12,
        'watering_duration_minutes': 10,
        'aeration_on_minutes': 30,
        'aeration_off_minutes': 30,
        'notes': 'Avoid bolting with cool temps.',
      },
    ]);

    // 4. Herbs
    int herbsId = await db.insert('recipe_templates', {
      'name': 'Kitchen Herbs',
      'category': 'herbs',
      'description': 'Basil, mint, cilantro',
      'total_cycle_days': 60,
      'is_system_template': 1,
      'created_by_user': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    await insertPhases(herbsId, [
      {
        'phase_name': 'Germination',
        'phase_order': 1,
        'duration_days': 10,
        'light_hours_on': 0,
        'light_hours_off': 24,
        'light_intensity_percent': 0,
        'target_temp_day': 22.0,
        'target_temp_night': 22.0,
        'target_humidity': 70.0,
        'target_ph_min': 5.5,
        'target_ph_max': 6.5,
        'target_ec_min': 0.4,
        'target_ec_max': 0.8,
        'watering_frequency_hours': 24,
        'watering_duration_minutes': 2,
        'aeration_on_minutes': 15,
        'aeration_off_minutes': 45,
        'notes': 'Consistent moisture.',
      },
      {
        'phase_name': 'Growing',
        'phase_order': 2,
        'duration_days': 50,
        'light_hours_on': 14,
        'light_hours_off': 10,
        'light_intensity_percent': 65,
        'target_temp_day': 22.0,
        'target_temp_night': 18.0,
        'target_humidity': 60.0,
        'target_ph_min': 5.5,
        'target_ph_max': 6.5,
        'target_ec_min': 1.2,
        'target_ec_max': 1.8,
        'watering_frequency_hours': 12,
        'watering_duration_minutes': 10,
        'aeration_on_minutes': 30,
        'aeration_off_minutes': 30,
        'notes': 'Harvest regularly.',
      },
    ]);

    // 5. Strawberries
    int strawberriesId = await db.insert('recipe_templates', {
      'name': 'Strawberries',
      'category': 'strawberries',
      'description': 'Sweet berries',
      'total_cycle_days': 90,
      'is_system_template': 1,
      'created_by_user': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    await insertPhases(strawberriesId, [
      {
        'phase_name': 'Establishment',
        'phase_order': 1,
        'duration_days': 21,
        'light_hours_on': 16,
        'light_hours_off': 8,
        'light_intensity_percent': 60,
        'target_temp_day': 20.0,
        'target_temp_night': 18.0,
        'target_humidity': 70.0,
        'target_ph_min': 5.5,
        'target_ph_max': 6.5,
        'target_ec_min': 1.0,
        'target_ec_max': 1.4,
        'watering_frequency_hours': 12,
        'watering_duration_minutes': 5,
        'aeration_on_minutes': 15,
        'aeration_off_minutes': 45,
        'notes': 'Root development.',
      },
      {
        'phase_name': 'Vegetative',
        'phase_order': 2,
        'duration_days': 35,
        'light_hours_on': 16,
        'light_hours_off': 8,
        'light_intensity_percent': 75,
        'target_temp_day': 22.0,
        'target_temp_night': 18.0,
        'target_humidity': 65.0,
        'target_ph_min': 5.5,
        'target_ph_max': 6.5,
        'target_ec_min': 1.5,
        'target_ec_max': 2.0,
        'watering_frequency_hours': 8,
        'watering_duration_minutes': 10,
        'aeration_on_minutes': 30,
        'aeration_off_minutes': 30,
        'notes': 'Leaf growth.',
      },
      {
        'phase_name': 'Flowering/Fruit',
        'phase_order': 3,
        'duration_days': 50,
        'light_hours_on': 14,
        'light_hours_off': 10,
        'light_intensity_percent': 100,
        'target_temp_day': 20.0,
        'target_temp_night': 16.0,
        'target_humidity': 60.0,
        'target_ph_min': 5.5,
        'target_ph_max': 6.5,
        'target_ec_min': 1.8,
        'target_ec_max': 2.5,
        'watering_frequency_hours': 6,
        'watering_duration_minutes': 10,
        'aeration_on_minutes': 60,
        'aeration_off_minutes': 0,
        'notes': 'Cooler nights help sweetness.',
      },
    ]);

    // 6. Peppers
    int peppersId = await db.insert('recipe_templates', {
      'name': 'Hot Peppers',
      'category': 'peppers',
      'description': 'Chili and bell peppers',
      'total_cycle_days': 120,
      'is_system_template': 1,
      'created_by_user': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    await insertPhases(peppersId, [
      {
        'phase_name': 'Germination',
        'phase_order': 1,
        'duration_days': 10,
        'light_hours_on': 0,
        'light_hours_off': 24,
        'light_intensity_percent': 0,
        'target_temp_day': 26.0,
        'target_temp_night': 26.0,
        'target_humidity': 80.0,
        'target_ph_min': 5.8,
        'target_ph_max': 6.2,
        'target_ec_min': 0.4,
        'target_ec_max': 0.8,
        'watering_frequency_hours': 24,
        'watering_duration_minutes': 2,
        'aeration_on_minutes': 15,
        'aeration_off_minutes': 45,
        'notes': 'Needs warmth.',
      },
      {
        'phase_name': 'Seedling',
        'phase_order': 2,
        'duration_days': 25,
        'light_hours_on': 14,
        'light_hours_off': 10,
        'light_intensity_percent': 50,
        'target_temp_day': 24.0,
        'target_temp_night': 22.0,
        'target_humidity': 70.0,
        'target_ph_min': 5.8,
        'target_ph_max': 6.2,
        'target_ec_min': 1.0,
        'target_ec_max': 1.4,
        'watering_frequency_hours': 12,
        'watering_duration_minutes': 5,
        'aeration_on_minutes': 15,
        'aeration_off_minutes': 45,
        'notes': 'Slow starters.',
      },
      {
        'phase_name': 'Vegetative',
        'phase_order': 3,
        'duration_days': 35,
        'light_hours_on': 16,
        'light_hours_off': 8,
        'light_intensity_percent': 75,
        'target_temp_day': 24.0,
        'target_temp_night': 20.0,
        'target_humidity': 60.0,
        'target_ph_min': 5.8,
        'target_ph_max': 6.3,
        'target_ec_min': 2.0,
        'target_ec_max': 2.5,
        'watering_frequency_hours': 8,
        'watering_duration_minutes': 10,
        'aeration_on_minutes': 30,
        'aeration_off_minutes': 30,
        'notes': 'Bushy growth.',
      },
      {
        'phase_name': 'Flowering/Fruit',
        'phase_order': 4,
        'duration_days': 80,
        'light_hours_on': 14,
        'light_hours_off': 10,
        'light_intensity_percent': 100,
        'target_temp_day': 22.0,
        'target_temp_night': 18.0,
        'target_humidity': 55.0,
        'target_ph_min': 6.0,
        'target_ph_max': 6.5,
        'target_ec_min': 2.5,
        'target_ec_max': 3.0,
        'watering_frequency_hours': 6,
        'watering_duration_minutes': 15,
        'aeration_on_minutes': 60,
        'aeration_off_minutes': 0,
        'notes': 'Long fruiting period.',
      },
    ]);

    // 7. Microgreens
    int microgreensId = await db.insert('recipe_templates', {
      'name': 'Microgreens Mix',
      'category': 'microgreens',
      'description': 'Quick harvest greens',
      'total_cycle_days': 12,
      'is_system_template': 1,
      'created_by_user': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    await insertPhases(microgreensId, [
      {
        'phase_name': 'Blackout',
        'phase_order': 1,
        'duration_days': 3,
        'light_hours_on': 0,
        'light_hours_off': 24,
        'light_intensity_percent': 0,
        'target_temp_day': 22.0,
        'target_temp_night': 22.0,
        'target_humidity': 80.0,
        'target_ph_min': 6.0,
        'target_ph_max': 6.5,
        'target_ec_min': 0.0,
        'target_ec_max': 0.5,
        'watering_frequency_hours': 24,
        'watering_duration_minutes': 2,
        'aeration_on_minutes': 0,
        'aeration_off_minutes': 0,
        'notes': 'Keep covered/dark.',
      },
      {
        'phase_name': 'Growing',
        'phase_order': 2,
        'duration_days': 7,
        'light_hours_on': 16,
        'light_hours_off': 8,
        'light_intensity_percent': 60,
        'target_temp_day': 20.0,
        'target_temp_night': 18.0,
        'target_humidity': 70.0,
        'target_ph_min': 6.0,
        'target_ph_max': 6.5,
        'target_ec_min': 0.5,
        'target_ec_max': 1.0,
        'watering_frequency_hours': 12,
        'watering_duration_minutes': 5,
        'aeration_on_minutes': 15,
        'aeration_off_minutes': 45,
        'notes': 'Harvest when first true leaves appear.',
      },
    ]);

    // 8. Cucumbers
    int cucumbersId = await db.insert('recipe_templates', {
      'name': 'Cucumbers',
      'category': 'cucumbers',
      'description': 'Slicing or pickling cucumbers',
      'total_cycle_days': 90,
      'is_system_template': 1,
      'created_by_user': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    await insertPhases(cucumbersId, [
      {
        'phase_name': 'Germination',
        'phase_order': 1,
        'duration_days': 7,
        'light_hours_on': 0,
        'light_hours_off': 24,
        'light_intensity_percent': 0,
        'target_temp_day': 26.0,
        'target_temp_night': 26.0,
        'target_humidity': 80.0,
        'target_ph_min': 5.8,
        'target_ph_max': 6.2,
        'target_ec_min': 0.5,
        'target_ec_max': 1.0,
        'watering_frequency_hours': 24,
        'watering_duration_minutes': 2,
        'aeration_on_minutes': 15,
        'aeration_off_minutes': 45,
        'notes': 'High heat.',
      },
      {
        'phase_name': 'Seedling',
        'phase_order': 2,
        'duration_days': 18,
        'light_hours_on': 14,
        'light_hours_off': 10,
        'light_intensity_percent': 50,
        'target_temp_day': 24.0,
        'target_temp_night': 22.0,
        'target_humidity': 70.0,
        'target_ph_min': 5.8,
        'target_ph_max': 6.2,
        'target_ec_min': 1.2,
        'target_ec_max': 1.5,
        'watering_frequency_hours': 12,
        'watering_duration_minutes': 5,
        'aeration_on_minutes': 15,
        'aeration_off_minutes': 45,
        'notes': 'Rapid growth.',
      },
      {
        'phase_name': 'Vegetative',
        'phase_order': 3,
        'duration_days': 25,
        'light_hours_on': 16,
        'light_hours_off': 8,
        'light_intensity_percent': 80,
        'target_temp_day': 24.0,
        'target_temp_night': 20.0,
        'target_humidity': 65.0,
        'target_ph_min': 5.8,
        'target_ph_max': 6.3,
        'target_ec_min': 1.8,
        'target_ec_max': 2.2,
        'watering_frequency_hours': 8,
        'watering_duration_minutes': 10,
        'aeration_on_minutes': 30,
        'aeration_off_minutes': 30,
        'notes': 'Vining.',
      },
      {
        'phase_name': 'Flowering/Fruit',
        'phase_order': 4,
        'duration_days': 60,
        'light_hours_on': 14,
        'light_hours_off': 10,
        'light_intensity_percent': 100,
        'target_temp_day': 22.0,
        'target_temp_night': 18.0,
        'target_humidity': 60.0,
        'target_ph_min': 6.0,
        'target_ph_max': 6.5,
        'target_ec_min': 2.2,
        'target_ec_max': 2.8,
        'watering_frequency_hours': 6,
        'watering_duration_minutes': 15,
        'aeration_on_minutes': 60,
        'aeration_off_minutes': 0,
        'notes': 'Heavy water consumers.',
      },
    ]);
  }

  Future<void> _createFertigationTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fertigation_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zone_id INTEGER UNIQUE,
        enabled INTEGER DEFAULT 0,
        reservoir_liters REAL,
        mixing_time_seconds INTEGER DEFAULT 300,
        check_interval_seconds INTEGER DEFAULT 900,
        ph_enabled INTEGER DEFAULT 1,
        ec_enabled INTEGER DEFAULT 1,
        ph_target_min REAL DEFAULT 5.8,
        ph_target_max REAL DEFAULT 6.2,
        ec_target REAL DEFAULT 1.4,
        use_recipe_targets INTEGER DEFAULT 1,
        max_dose_ml REAL DEFAULT 50,
        max_doses_per_hour INTEGER DEFAULT 4,
        created_at INTEGER,
        updated_at INTEGER,
        FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS fertigation_pumps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zone_id INTEGER,
        name TEXT,
        pump_type TEXT,
        relay_channel INTEGER,
        relay_module_address INTEGER,
        ml_per_second REAL,
        enabled INTEGER DEFAULT 1,
        created_at INTEGER,
        updated_at INTEGER,
        FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS fertigation_probes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zone_id INTEGER,
        probe_type TEXT,
        hub_address INTEGER,
        input_channel INTEGER,
        input_type TEXT,
        range_min REAL,
        range_max REAL,
        calibration_offset REAL DEFAULT 0,
        calibration_slope REAL DEFAULT 1,
        enabled INTEGER DEFAULT 1,
        created_at INTEGER,
        updated_at INTEGER,
        FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS fertigation_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zone_id INTEGER,
        probe_id INTEGER,
        value REAL,
        temperature REAL,
        timestamp INTEGER,
        FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE,
        FOREIGN KEY (probe_id) REFERENCES fertigation_probes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS fertigation_dose_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zone_id INTEGER,
        pump_id INTEGER,
        dose_ml REAL,
        duration_seconds REAL,
        trigger TEXT,
        reading_before REAL,
        reading_after REAL,
        timestamp INTEGER,
        FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE,
        FOREIGN KEY (pump_id) REFERENCES fertigation_pumps(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS fertigation_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zone_id INTEGER,
        name TEXT,
        schedule_type TEXT,
        time TEXT,
        days_of_week TEXT,
        enabled INTEGER DEFAULT 1,
        FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createGuardianTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS guardian_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zone_id INTEGER UNIQUE,
        enabled INTEGER DEFAULT 0,
        api_key TEXT,
        check_interval_hours INTEGER DEFAULT 24,
        vision_enabled INTEGER DEFAULT 1,
        data_analysis_enabled INTEGER DEFAULT 1,
        alert_sensitivity TEXT DEFAULT 'medium',
        created_at INTEGER,
        updated_at INTEGER,
        FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS guardian_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zone_id INTEGER,
        report_type TEXT,
        alerts_json TEXT,
        plant_health TEXT,
        environment_summary TEXT,
        recipe_compliance TEXT,
        recommendations TEXT,
        watching TEXT,
        full_response TEXT,
        grow_id INTEGER,
        grow_day INTEGER,
        recipe_id INTEGER,
        recipe_phase TEXT,
        image_ids TEXT,
        prompt_tokens INTEGER,
        completion_tokens INTEGER,
        cost_cents REAL,
        created_at INTEGER,
        FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS guardian_alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zone_id INTEGER,
        report_id INTEGER,
        severity TEXT,
        category TEXT,
        title TEXT,
        message TEXT,
        recommendation TEXT,
        source TEXT,
        acknowledged INTEGER DEFAULT 0,
        acknowledged_at INTEGER,
        created_at INTEGER,
        FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE,
        FOREIGN KEY (report_id) REFERENCES guardian_reports(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS guardian_baseline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zone_id INTEGER,
        metric TEXT,
        context TEXT,
        value_avg REAL,
        value_min REAL,
        value_max REAL,
        std_dev REAL,
        sample_count INTEGER,
        last_calculated INTEGER,
        FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS guardian_equipment_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zone_id INTEGER,
        note TEXT,
        category TEXT,
        created_at INTEGER,
        FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS guardian_conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zone_id INTEGER,
        question TEXT,
        response TEXT,
        context_json TEXT,
        image_id INTEGER,
        tokens_used INTEGER,
        created_at INTEGER,
        FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE
      )
    ''');
  }

  // Create all essential tables
  Future<void> _createAllTables(Database db) async {
    try {
      debugPrint('Creating all database tables...');

      // System config table (needed to detect first run)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS system_config (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          system_type TEXT NOT NULL DEFAULT 'soil',
          facility_scale TEXT NOT NULL DEFAULT 'home',
          zone_count INTEGER NOT NULL DEFAULT 1,
          zones TEXT,
          hardware_requirements TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Location settings table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS location_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          timezone TEXT NOT NULL,
          location_name TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Zones table - CREATE THIS FIRST before anything references it
      await db.execute('''
        CREATE TABLE IF NOT EXISTS zones (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          grow_id INTEGER,
          name TEXT NOT NULL,
          enabled INTEGER NOT NULL DEFAULT 1,
          has_irrigation INTEGER DEFAULT 0,
          has_lighting INTEGER DEFAULT 0,
          has_hvac INTEGER DEFAULT 0,
          has_aeration INTEGER DEFAULT 0,
          has_seedling_mat INTEGER DEFAULT 0,
          has_cameras INTEGER DEFAULT 0,
          grow_method TEXT,
          lighting_mode TEXT DEFAULT 'Manual',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Grows table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS grows (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plant_id INTEGER,
          grow_mode_id INTEGER,
          name TEXT NOT NULL,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          status TEXT NOT NULL DEFAULT 'active',
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Plants table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS plants (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          default_water_duration INTEGER,
          default_water_interval INTEGER,
          default_temperature_min REAL,
          default_temperature_max REAL,
          default_humidity_min REAL,
          default_humidity_max REAL,
          default_light_hours INTEGER,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Grow modes table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS grow_modes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          is_system INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Recipe Templates table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recipe_templates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT CHECK (category IN ('cannabis','tomatoes','leafy_greens','herbs','strawberries','peppers','microgreens','cucumbers','custom')),
          description TEXT,
          total_cycle_days INTEGER,
          is_system_template INTEGER DEFAULT 0,
          created_by_user INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
        );
      ''');

      // Recipe Phases table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recipe_phases (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          template_id INTEGER REFERENCES recipe_templates(id) ON DELETE CASCADE,
          phase_name TEXT NOT NULL,
          phase_order INTEGER NOT NULL,
          duration_days INTEGER NOT NULL,
          light_hours_on INTEGER,
          light_hours_off INTEGER,
          light_intensity_percent REAL,
          target_temp_day REAL,
          target_temp_night REAL,
          target_humidity REAL,
          target_ph_min REAL,
          target_ph_max REAL,
          target_ec_min REAL,
          target_ec_max REAL,
          watering_frequency_hours INTEGER,
          watering_duration_minutes INTEGER,
          aeration_on_minutes INTEGER,
          aeration_off_minutes INTEGER,
          notes TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
        );
      ''');

      // Zone Crops table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS zone_crops (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          zone_id INTEGER REFERENCES zones(id) ON DELETE CASCADE,
          crop_name TEXT NOT NULL,
          template_id INTEGER REFERENCES recipe_templates(id),
          current_phase_id INTEGER REFERENCES recipe_phases(id),
          phase_start_date TEXT,
          grow_start_date TEXT,
          expected_harvest_date TEXT,
          use_recipe_profile INTEGER DEFAULT 1,
          is_active INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
        );
      ''');

      // Sensors table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sensors (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          zone_id INTEGER NOT NULL,
          sensor_type TEXT NOT NULL,
          name TEXT NOT NULL,
          address TEXT,
          calibration_offset REAL DEFAULT 0.0,
          scale_factor REAL DEFAULT 1.0,
          display_order INTEGER DEFAULT 0,
          enabled INTEGER NOT NULL DEFAULT 1,
          hub_id INTEGER REFERENCES sensor_hubs(id),
          input_channel INTEGER CHECK (input_channel BETWEEN 1 AND 8),
          input_type TEXT CHECK (input_type IN ('i2c', 'spi', 'analog_0_10v', 'analog_4_20ma')),
          i2c_address TEXT,
          spi_cs_pin INTEGER,
          sample_rate_seconds INTEGER DEFAULT 60,
          is_active INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (zone_id) REFERENCES zones (id)
        )
      ''');

      // Sensor Hubs table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sensor_hubs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          modbus_address INTEGER UNIQUE NOT NULL CHECK (modbus_address BETWEEN 1 AND 247),
          name TEXT NOT NULL,
          zone_id INTEGER REFERENCES zones(id),
          status TEXT DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'error', 'maintenance')),
          last_seen TEXT,
          firmware_version TEXT,
          hardware_revision TEXT,
          total_channels INTEGER DEFAULT 8,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Sensor Calibrations table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sensor_calibrations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sensor_id INTEGER REFERENCES sensors(id) ON DELETE CASCADE,
          parameter_name TEXT NOT NULL,
          offset_value REAL DEFAULT 0.0,
          scale_factor REAL DEFAULT 1.0,
          reference_low REAL,
          reference_high REAL,
          measured_low REAL,
          measured_high REAL,
          calibration_date TEXT DEFAULT CURRENT_TIMESTAMP,
          next_calibration_due TEXT,
          calibrated_by TEXT,
          notes TEXT
        )
      ''');

      // Hub Diagnostics table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS hub_diagnostics (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          hub_id INTEGER REFERENCES sensor_hubs(id) ON DELETE CASCADE,
          timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
          communication_errors INTEGER DEFAULT 0,
          successful_reads INTEGER DEFAULT 0,
          average_response_time_ms REAL,
          last_error_message TEXT
        )
      ''');

      // Sensor readings table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sensor_readings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sensor_id INTEGER NOT NULL,
          reading_type TEXT NOT NULL,
          value REAL NOT NULL,
          timestamp INTEGER NOT NULL,
          FOREIGN KEY (sensor_id) REFERENCES sensors (id)
        )
      ''');

      // Watering timers table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS watering_timers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          zone_id INTEGER NOT NULL,
          type TEXT NOT NULL,
          interval_hours INTEGER,
          offset_minutes INTEGER,
          start_time TEXT,
          duration_seconds INTEGER NOT NULL,
          days_of_week TEXT,
          enabled INTEGER NOT NULL DEFAULT 1,
          last_run INTEGER,
          next_run INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (zone_id) REFERENCES zones (id)
        )
      ''');

      // IO channels table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS io_channels (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          channel_number INTEGER NOT NULL,
          module_number INTEGER NOT NULL,
          is_input INTEGER DEFAULT 0,
          type TEXT,
          name TEXT,
          is_assigned INTEGER DEFAULT 0,
          created_at INTEGER DEFAULT (strftime('%s','now')),
          updated_at INTEGER DEFAULT (strftime('%s','now')),
          UNIQUE(module_number, channel_number)
        )
      ''');

      // Seedling Mat Settings table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS seedling_mat_settings (
          zone_id INTEGER PRIMARY KEY,
          enabled INTEGER DEFAULT 0,
          mode TEXT DEFAULT 'manual',
          target_temp REAL DEFAULT 24.0,
          auto_off_enabled INTEGER DEFAULT 0,
          auto_off_days INTEGER DEFAULT 14,
          sensor_id INTEGER,
          created_at INTEGER,
          updated_at INTEGER,
          FOREIGN KEY (zone_id) REFERENCES zones (id) ON DELETE CASCADE
        )
      ''');

      // Astral Simulation table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS astral_simulation (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          zone_id INTEGER NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
          enabled INTEGER DEFAULT 0,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          location_name TEXT,
          timezone TEXT,
          simulation_mode TEXT DEFAULT 'full_year',
          include_spring INTEGER DEFAULT 1,
          include_summer INTEGER DEFAULT 1,
          include_fall INTEGER DEFAULT 1,
          include_winter INTEGER DEFAULT 1,
          range_start_month INTEGER,
          range_start_day INTEGER,
          range_end_month INTEGER,
          range_end_day INTEGER,
          fixed_month INTEGER,
          fixed_day INTEGER,
          time_compression REAL DEFAULT 1.0,
          simulation_start_date INTEGER,
          current_simulated_date INTEGER,
          sunrise_offset_minutes INTEGER DEFAULT 0,
          sunset_offset_minutes INTEGER DEFAULT 0,
          use_intensity_curve INTEGER DEFAULT 0,
          dawn_duration_minutes INTEGER DEFAULT 30,
          dusk_duration_minutes INTEGER DEFAULT 30,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
        )
      ''');

      // Astral Daily Cache table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS astral_daily_cache (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          zone_id INTEGER NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
          simulated_date TEXT NOT NULL,
          sunrise_time TEXT NOT NULL,
          sunset_time TEXT NOT NULL,
          day_length_minutes INTEGER NOT NULL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
          UNIQUE(zone_id, simulated_date)
        )
      ''');

      // Users table
      await _createUsersTable(db);

      // Control types table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS control_types (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          icon TEXT
        )
      ''');

      // Zone controls table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS zone_controls (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          zone_id INTEGER NOT NULL,
          control_type_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          enabled INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (zone_id) REFERENCES zones (id),
          FOREIGN KEY (control_type_id) REFERENCES control_types (id)
        )
      ''');

      // Control settings table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS control_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          zone_control_id INTEGER NOT NULL,
          setting_name TEXT NOT NULL,
          setting_value TEXT NOT NULL,
          setting_unit TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (zone_control_id) REFERENCES zone_controls (id)
        )
      ''');

      // Control IO assignments table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS control_io_assignments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          zone_control_id INTEGER NOT NULL,
          io_channel_id INTEGER NOT NULL,
          function TEXT NOT NULL,
          invert_logic INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (zone_control_id) REFERENCES zone_controls (id),
          FOREIGN KEY (io_channel_id) REFERENCES io_channels (id)
        )
      ''');

      // Control schedules table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS control_schedules (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          zone_control_id INTEGER NOT NULL,
          schedule_type TEXT NOT NULL,
          start_time TEXT,
          end_time TEXT,
          days_of_week TEXT,
          astral_event TEXT,
          offset_minutes INTEGER,
          trigger_threshold REAL,
          interval_minutes INTEGER,
          duration_minutes INTEGER,
          enabled INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (zone_control_id) REFERENCES zone_controls (id)
        )
      ''');

      // Control status log table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS control_status_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          zone_control_id INTEGER NOT NULL,
          state TEXT NOT NULL,
          reason TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          FOREIGN KEY (zone_control_id) REFERENCES zone_controls (id)
        )
      ''');

      // Timer log table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS timer_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timer_id INTEGER NOT NULL,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          success INTEGER,
          notes TEXT,
          FOREIGN KEY (timer_id) REFERENCES watering_timers (id)
        )
      ''');

      // Cameras table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cameras (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          device_path TEXT NOT NULL,
          camera_index INTEGER DEFAULT 0,
          model TEXT,
          resolution_width INTEGER NOT NULL,
          resolution_height INTEGER NOT NULL,
          capture_interval_hours REAL NOT NULL DEFAULT 24.0,
          enabled INTEGER NOT NULL DEFAULT 1,
          only_when_lights_on INTEGER NOT NULL DEFAULT 0,
          auto_cleanup_enabled INTEGER DEFAULT 0,
          retention_days INTEGER,
          max_photos INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Camera assignments table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS camera_assignments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          camera_id INTEGER NOT NULL,
          zone_id INTEGER NOT NULL,
          view_type TEXT DEFAULT 'default',
          created_at INTEGER,
          FOREIGN KEY (camera_id) REFERENCES cameras (id) ON DELETE CASCADE,
          FOREIGN KEY (zone_id) REFERENCES zones (id) ON DELETE CASCADE,
          UNIQUE(camera_id, zone_id)
        )
      ''');   // Images table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS images (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          camera_id INTEGER NOT NULL,
          grow_id INTEGER NOT NULL,
          file_path TEXT NOT NULL,
          thumbnail_path TEXT,
          timestamp INTEGER NOT NULL,
          grow_day INTEGER NOT NULL,
          grow_hour INTEGER NOT NULL,
          notes TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (camera_id) REFERENCES cameras (id),
          FOREIGN KEY (grow_id) REFERENCES grows (id)
        )
      ''');

      // Grow recipes table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS grow_recipes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          plant_type TEXT NOT NULL,
          grow_mode_id INTEGER NOT NULL,
          is_system INTEGER NOT NULL DEFAULT 0,
          created_by_user_id INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (grow_mode_id) REFERENCES grow_modes (id)
        )
      ''');

      // Recipe settings table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recipe_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          recipe_id INTEGER NOT NULL,
          control_type_id INTEGER NOT NULL,
          setting_name TEXT NOT NULL,
          setting_value TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (recipe_id) REFERENCES grow_recipes (id),
          FOREIGN KEY (control_type_id) REFERENCES control_types (id)
        )
      ''');

      // Settings table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT NOT NULL UNIQUE,
          value TEXT NOT NULL,
          data_type TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Create schedule and settings tables
      await _createScheduleTables(db);
      await _createAerationTables(db);

      // Insert default grow modes ONLY if they don't exist
      final existingModes = await db.query('grow_modes');
      if (existingModes.isEmpty) {
        await db.insert('grow_modes', {
          'id': 1,
          'name': 'soil',
          'description': 'Soil-based growing',
          'is_system': 1,
        });

        await db.insert('grow_modes', {
          'id': 2,
          'name': 'hydroponic',
          'description': 'Hydroponic growing',
          'is_system': 1,
        });

        


        // Preload system recipe templates
        await _preloadSystemTemplates(db);

        await db.insert('grow_modes', {
          'id': 3,
          'name': 'aeroponic',
          'description': 'Aeroponic growing',
          'is_system': 1,
        });

        await db.insert('grow_modes', {
          'id': 4,
          'name': 'drip',
          'description': 'Drip irrigation',
          'is_system': 1,
        });

        await db.insert('grow_modes', {
          'id': 5,
          'name': 'ebb_and_flow',
          'description': 'Ebb and Flow (Flood and Drain)',
          'is_system': 1,
        });

        await db.insert('grow_modes', {
          'id': 6,
          'name': 'nft',
          'description': 'Nutrient Film Technique',
          'is_system': 1,
        });
      }

      // Insert default control types ONLY if they don't exist
      final existingControlTypes = await db.query('control_types');
      if (existingControlTypes.isEmpty) {
        final controlTypes = [
          {
            'name': 'lighting',
            'description': 'Grow lights and lighting control',
          },
          {'name': 'ventilation', 'description': 'Fans and air circulation'},
          {'name': 'heating', 'description': 'Heating elements'},
          {'name': 'humidity', 'description': 'Humidifiers and dehumidifiers'},
          {'name': 'water_pump', 'description': 'Water pumps and irrigation'},
          {'name': 'nutrient_pump', 'description': 'Nutrient solution pumps'},
          {'name': 'ph_control', 'description': 'pH adjustment systems'},
          {'name': 'ec_control', 'description': 'EC/nutrient control'},
          {
            'name': 'vent_actuator',
            'description': 'Vent opening/closing systems',
          },
        ];

        for (int i = 0; i < controlTypes.length; i++) {
          await db.insert('control_types', {
            'id': i + 1,
            'name': controlTypes[i]['name'],
            'description': controlTypes[i]['description'],
          });
        }
      }

      // Create default IO channels
      await _createDefaultIoChannels(db);

      // Create Fertigation and Guardian tables
      await _createFertigationTables(db);
      await _createGuardianTables(db);
      await _createSensorHubTables(db);

      debugPrint('All database tables created successfully');
    } catch (e) {
      debugPrint('Error creating tables: $e');
      rethrow;
    }
  }

  // IO CHANNEL METHODS

  Future<List<IoChannel>> getAllIoChannels() async {
    final db = await database;
    
    // Left join to get assignment details
    final result = await db.rawQuery('''
      SELECT 
        io.*, 
        zc.name as assigned_to_name
      FROM io_channels io
      LEFT JOIN control_io_assignments cia ON io.id = cia.io_channel_id
      LEFT JOIN zone_controls zc ON cia.zone_control_id = zc.id
      ORDER BY io.module_number, io.channel_number
    ''');
    
    return result.map((map) => IoChannel.fromMap(map)).toList();
  }

  Future<void> generateRelayChannels(int channelCount) async {
    final db = await database;
    await db.transaction((txn) async {
      // Clear existing relay channels (Module 1)
      // Note: This might break existing assignments if we just delete. 
      // Ideally we should only add/remove difference, but for now we'll assume re-config clears assignments or we handle it carefully.
      // A safer approach is to UPSERT.
      
      for (int i = 1; i <= channelCount; i++) {
        await txn.execute('''
          INSERT INTO io_channels (channel_number, module_number, is_input, type, name)
          VALUES (?, 1, 0, 'relay', 'Relay #$i')
          ON CONFLICT(module_number, channel_number) DO UPDATE SET
          type = 'relay'
        ''', [i]);
      }
      
      // Remove channels that are no longer valid (e.g. going from 16 to 8)
      await txn.delete('io_channels', 
        where: 'module_number = 1 AND channel_number > ?', 
        whereArgs: [channelCount]
      );
    });
  }

  Future<void> generateHubChannels(int hubAddress) async {
    final db = await database;
    final moduleNum = hubAddress + 100;
    
    await db.transaction((txn) async {
      // 4-20mA Inputs (Ch 1-2)
      for (int i = 1; i <= 2; i++) {
        await txn.execute('''
          INSERT INTO io_channels (channel_number, module_number, is_input, type, name)
          VALUES (?, ?, 1, 'ai_4_20', '4-20mA In #$i')
          ON CONFLICT(module_number, channel_number) DO NOTHING
        ''', [i, moduleNum]);
      }
      
      // 0-10V Inputs (Ch 3-4)
      for (int i = 3; i <= 4; i++) {
        await txn.execute('''
          INSERT INTO io_channels (channel_number, module_number, is_input, type, name)
          VALUES (?, ?, 1, 'ai_0_10', '0-10V In #$i')
          ON CONFLICT(module_number, channel_number) DO NOTHING
        ''', [i, moduleNum]);
      }
      
      // Digital Inputs (Ch 9-12 mapped to DI 1-4 for simplicity in numbering, or use separate numbering scheme)
      // Let's use Ch 9-12 for DIs to avoid overlap with Analog Inputs 1-4.
      for (int i = 1; i <= 4; i++) {
        await txn.execute('''
          INSERT INTO io_channels (channel_number, module_number, is_input, type, name)
          VALUES (?, ?, 1, 'di', 'Digital In #$i')
          ON CONFLICT(module_number, channel_number) DO NOTHING
        ''', [i + 8, moduleNum]);
      }
      
      // Analog Outputs (Ch 1-2 Output)
      // We can reuse channel numbers if is_input differs, but unique constraint is (module, channel).
      // So we need distinct channel numbers for outputs. Let's use 21-22.
      for (int i = 1; i <= 2; i++) {
        await txn.execute('''
          INSERT INTO io_channels (channel_number, module_number, is_input, type, name)
          VALUES (?, ?, 0, 'ao_0_10', '0-10V Out #$i')
          ON CONFLICT(module_number, channel_number) DO NOTHING
        ''', [i + 20, moduleNum]);
      }
    });
  }

  // FERTIGATION METHODS

  Future<FertigationConfig?> getFertigationConfig(int zoneId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fertigation_config',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
    );
    if (maps.isNotEmpty) {
      return FertigationConfig.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveFertigationConfig(FertigationConfig config) async {
    final db = await database;
    // Check if exists
    final exists = await getFertigationConfig(config.zoneId);
    if (exists != null) {
      await db.update(
        'fertigation_config',
        config.toMap(),
        where: 'zone_id = ?',
        whereArgs: [config.zoneId],
      );
    } else {
      await db.insert('fertigation_config', config.toMap());
    }
  }

  Future<List<FertigationPump>> getFertigationPumps(int zoneId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fertigation_pumps',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
    );
    return List.generate(maps.length, (i) => FertigationPump.fromMap(maps[i]));
  }

  Future<void> saveFertigationPump(FertigationPump pump) async {
    final db = await database;
    if (pump.id != null) {
      await db.update(
        'fertigation_pumps',
        pump.toMap(),
        where: 'id = ?',
        whereArgs: [pump.id],
      );
    } else {
      await db.insert('fertigation_pumps', pump.toMap());
    }
  }

  Future<void> deleteFertigationPump(int id) async {
    final db = await database;
    await db.delete('fertigation_pumps', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FertigationProbe>> getFertigationProbes(int zoneId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fertigation_probes',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
    );
    return List.generate(maps.length, (i) => FertigationProbe.fromMap(maps[i]));
  }

  Future<void> saveFertigationProbe(FertigationProbe probe) async {
    final db = await database;
    if (probe.id != null) {
      await db.update(
        'fertigation_probes',
        probe.toMap(),
        where: 'id = ?',
        whereArgs: [probe.id],
      );
    } else {
      await db.insert('fertigation_probes', probe.toMap());
    }
  }

  Future<void> deleteFertigationProbe(int id) async {
    final db = await database;
    await db.delete('fertigation_probes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FertigationSchedule>> getFertigationSchedules(int zoneId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fertigation_schedules',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
    );
    return List.generate(maps.length, (i) => FertigationSchedule.fromMap(maps[i]));
  }

  Future<void> saveFertigationSchedule(FertigationSchedule schedule) async {
    final db = await database;
    if (schedule.id != null) {
      await db.update(
        'fertigation_schedules',
        schedule.toMap(),
        where: 'id = ?',
        whereArgs: [schedule.id],
      );
    } else {
      await db.insert('fertigation_schedules', schedule.toMap());
    }
  }

  Future<void> deleteFertigationSchedule(int id) async {
    final db = await database;
    await db.delete('fertigation_schedules', where: 'id = ?', whereArgs: [id]);
  }

  // GUARDIAN METHODS

  Future<GuardianConfig?> getGuardianConfig(int zoneId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'guardian_config',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
    );
    if (maps.isNotEmpty) {
      return GuardianConfig.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveGuardianConfig(GuardianConfig config) async {
    final db = await database;
    final exists = await getGuardianConfig(config.zoneId);
    if (exists != null) {
      await db.update(
        'guardian_config',
        config.toMap(),
        where: 'zone_id = ?',
        whereArgs: [config.zoneId],
      );
    } else {
      await db.insert('guardian_config', config.toMap());
    }
  }

  Future<List<GuardianReport>> getGuardianReports(int zoneId, {int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'guardian_reports',
      where: 'zone_id = ?',
      orderBy: 'created_at DESC',
      limit: limit,
      whereArgs: [zoneId],
    );
    return List.generate(maps.length, (i) => GuardianReport.fromMap(maps[i]));
  }

  // GUARDIAN ACTION LOGGING METHODS

  Future<void> insertGuardianActionLog({
    required int zoneId,
    required String actionType,
    required String category,
    required String description,
    required Map<String, dynamic> parameters,
    String? reasoning,
    required bool success,
    String? error,
    required int timestamp,
  }) async {
    final db = await database;
    await db.insert('guardian_action_log', {
      'zone_id': zoneId,
      'action_type': actionType,
      'category': category,
      'description': description,
      'parameters': jsonEncode(parameters),
      'reasoning': reasoning,
      'success': success ? 1 : 0,
      'error': error,
      'timestamp': timestamp,
    });
  }

  Future<List<GuardianActionLog>> getGuardianActionLogs(int zoneId, {int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'guardian_action_log',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return maps.map((map) {
      // Parse JSON parameters
      final params = map['parameters'] != null 
          ? jsonDecode(map['parameters'] as String) as Map<String, dynamic>
          : <String, dynamic>{};
      
      return GuardianActionLog(
        id: map['id'] as int,
        zoneId: map['zone_id'] as int,
        actionType: map['action_type'] as String,
        category: map['category'] as String,
        description: map['description'] as String,
        parameters: params,
        reasoning: map['reasoning'] as String?,
        success: (map['success'] as int) == 1,
        error: map['error'] as String?,
        timestamp: map['timestamp'] as int,
      );
    }).toList();
  }

  Future<void> updateFertigationTarget(int zoneId, String targetKey, double value) async {
    final db = await database;
    await db.update(
      'fertigation_settings',
      {targetKey: value, 'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000},
      where: 'zone_id = ?',
      whereArgs: [zoneId],
    );
  }

  Future<List<GuardianAlert>> getGuardianAlerts(int zoneId, {bool unacknowledgedOnly = false}) async {
    final db = await database;
    final whereClause = unacknowledgedOnly 
        ? 'zone_id = ? AND acknowledged = 0' 
        : 'zone_id = ?';
    
    final List<Map<String, dynamic>> maps = await db.query(
      'guardian_alerts',
      where: whereClause,
      orderBy: 'created_at DESC',
      whereArgs: [zoneId],
    );
    return List.generate(maps.length, (i) => GuardianAlert.fromMap(maps[i]));
  }

  Future<void> acknowledgeGuardianAlert(int alertId) async {
    final db = await database;
    await db.update(
      'guardian_alerts',
      {
        'acknowledged': 1,
        'acknowledged_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  // PLANT METHODS

  Future<List<Plant>> getPlants() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('plants');

    return List.generate(maps.length, (i) {
      return Plant.fromMap(maps[i]);
    });
  }

  Future<List<Plant>> getPlantsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plants',
      where: 'category = ?',
      whereArgs: [category],
    );

    return List.generate(maps.length, (i) {
      return Plant.fromMap(maps[i]);
    });
  }

  Future<Plant?> getPlant(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plants',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Plant.fromMap(maps.first);
    }

    return null;
  }

  Future<int> insertPlant(Plant plant) async {
    final db = await database;
    return await db.insert('plants', plant.toMap());
  }



  Future<int> updatePlant(Plant plant) async {
    final db = await database;
    return await db.update(
      'plants',
      plant.toMap(),
      where: 'id = ?',
      whereArgs: [plant.id],
    );
  }

  Future<int> deletePlant(int id) async {
    final db = await database;
    return await db.delete('plants', where: 'id = ?', whereArgs: [id]);
  }

  // GROW METHODS

  Future<List<Grow>> getGrows() async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'grows',
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) {
        return Grow.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error loading grows: $e');
      return [];
    }
  }

  Future<List<Grow>> getActiveGrows() async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'grows',
        where: 'status = ?',
        whereArgs: ['active'],
      );

      return List.generate(maps.length, (i) {
        return Grow.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error in getActiveGrows: $e');
      // Return empty list if there's an error
      return [];
    }
  }

  Future<Grow?> getGrow(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'grows',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Grow.fromMap(maps.first);
    }

    return null;
  }

  Future<int> insertGrow(Grow grow) async {
    final db = await database;
    return await db.insert('grows', grow.toMap());
  }

  Future<int> updateGrow(Grow grow) async {
    final db = await database;
    return await db.update(
      'grows',
      grow.toMap(),
      where: 'id = ?',
      whereArgs: [grow.id],
    );
  }

  Future<int> completeGrow(int id) async {
    final db = await database;
    return await db.update(
      'grows',
      {
        'status': 'completed',
        'end_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> archiveGrow(int id) async {
    final db = await database;
    return await db.update(
      'grows',
      {
        'status': 'archived',
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String?> getGrowModeName(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'grow_modes',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['name'] as String;
    }
    return null;
  }

  // ZONE METHODS

  Future<List<Zone>> getZones({int? growId}) async {
    final db = await database;

    try {
      List<Map<String, dynamic>> maps;
      if (growId != null) {
        maps = await db.query(
          'zones',
          where: 'grow_id = ?',
          whereArgs: [growId],
          orderBy: 'created_at DESC',
        );
      } else {
        maps = await db.query('zones', orderBy: 'created_at DESC');
      }

      return List.generate(maps.length, (i) {
        return Zone.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error in getZones: $e');

      // If there's a table error, try to recreate it
      if (e.toString().contains('no such table') ||
          e.toString().contains('no such column')) {
        try {
          await _ensureZonesTableExists(db);
          // Retry the query
          List<Map<String, dynamic>> maps;
          if (growId != null) {
            maps = await db.query(
              'zones',
              where: 'grow_id = ?',
              whereArgs: [growId],
              orderBy: 'created_at DESC',
            );
          } else {
            maps = await db.query('zones', orderBy: 'created_at DESC');
          }
          return List.generate(maps.length, (i) {
            return Zone.fromMap(maps[i]);
          });
        } catch (e2) {
          debugPrint('Error recreating zones table: $e2');
        }
      }

      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  Future<int> updateZone(
    int id, 
    String name, 
    int enabled, {
    int? growId,
    String? growMethod,
    bool? hasIrrigation,
    bool? hasLighting,
    bool? hasHvac,
    bool? hasAeration,
    bool? hasCameras,
    bool? hasFertigation,
    bool? hasGuardian,
  }) async {
    final db = await database;
    
    final Map<String, dynamic> values = {
      'name': name,
      'enabled': enabled,
      'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };

    if (growId != null) values['grow_id'] = growId;
    if (growMethod != null) values['grow_method'] = growMethod;
    if (hasIrrigation != null) values['has_irrigation'] = hasIrrigation ? 1 : 0;
    if (hasLighting != null) values['has_lighting'] = hasLighting ? 1 : 0;
    if (hasHvac != null) values['has_hvac'] = hasHvac ? 1 : 0;
    if (hasAeration != null) values['has_aeration'] = hasAeration ? 1 : 0;
    if (hasCameras != null) values['has_cameras'] = hasCameras ? 1 : 0;
    if (hasFertigation != null) values['has_fertigation'] = hasFertigation ? 1 : 0;
    if (hasGuardian != null) values['has_guardian'] = hasGuardian ? 1 : 0;

    return await db.update(
      'zones',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _ensureZonesTableExists(Database db) async {
    try {
      // Check if table exists and has correct schema
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='zones'",
      );

      if (tables.isEmpty) {
        // Table doesn't exist, create it
        await db.execute('''
          CREATE TABLE zones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            grow_id INTEGER,
            name TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            has_irrigation INTEGER NOT NULL DEFAULT 0,
            has_lighting INTEGER NOT NULL DEFAULT 0,
            has_ventilation INTEGER NOT NULL DEFAULT 0,
            has_aeration INTEGER NOT NULL DEFAULT 0,
            has_cameras INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY (grow_id) REFERENCES grows(id)
          )
        ''');
        debugPrint('Created zones table');
      } else {
        // Table exists, check if it has the correct columns
        final columns = await db.rawQuery("PRAGMA table_info(zones)");
        final columnNames =
            columns.map((col) => col['name'] as String).toList();

        // Check for required columns
        final requiredColumns = [
          'id',
          'grow_id',
          'name',
          'enabled',
          'has_irrigation',
          'has_lighting',
          'has_hvac',
          'has_aeration',
          'has_cameras',
          'created_at',
          'updated_at',
        ];
        final missingColumns =
            requiredColumns.where((col) => !columnNames.contains(col)).toList();

        if (missingColumns.isNotEmpty) {
          debugPrint('Missing columns in zones table: $missingColumns');
          // Add missing columns instead of dropping the table
          for (final col in missingColumns) {
            try {
              String columnDef;
              if (col == 'grow_id') {
                columnDef = 'INTEGER';
              } else if (col == 'name') {
                columnDef = 'TEXT NOT NULL DEFAULT ""';
              } else if (col == 'created_at' || col == 'updated_at') {
                columnDef = 'INTEGER NOT NULL DEFAULT 0';
              } else {
                // For has_irrigation, has_lighting, has_ventilation, has_aeration, has_cameras, enabled
                columnDef = 'INTEGER NOT NULL DEFAULT 0';
              }
              await db.execute('ALTER TABLE zones ADD COLUMN $col $columnDef');
              debugPrint('Added column $col to zones table');
            } catch (e) {
              debugPrint('Error adding column $col: $e');
            }
          }
          debugPrint('Added missing columns to zones table');
        }
      }
    } catch (e) {
      debugPrint('Error ensuring zones table exists: $e');
      rethrow;
    }
  }

  Future<Zone?> getZone(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'zones',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Zone.fromMap(maps.first);
    }

    return null;
  }

  // SCHEDULE METHODS

  // Irrigation
  Future<List<IrrigationSchedule>> getIrrigationSchedules(int zoneId) async {
    final db = await database;
    final maps = await db.query('irrigation_schedules', where: 'zone_id = ?', whereArgs: [zoneId]);
    return List.generate(maps.length, (i) => IrrigationSchedule.fromMap(maps[i]));
  }

  Future<void> insertIrrigationSchedule(IrrigationSchedule schedule, int zoneId) async {
    final db = await database;
    await db.insert('irrigation_schedules', schedule.toMap(zoneId), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteIrrigationSchedule(String id) async {
    final db = await database;
    await db.delete('irrigation_schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateIrrigationSchedule(IrrigationSchedule schedule) async {
    final db = await database;
    // We need the zone_id to update, but the model doesn't store it directly in toMap unless passed.
    // However, update only needs the ID and the fields to change.
    // But toMap requires zoneId.
    // Let's fetch the existing record to get the zone_id, or just update specific fields?
    // Better: Update the model toMap to be flexible or just use raw update.
    // Actually, toMap takes zoneId. We can get it from the DB first or just assume we are updating fields that don't include zone_id.
    // But wait, toMap returns a map with zone_id.
    
    // Let's just query the existing one to get the zone_id
    final existing = await db.query('irrigation_schedules', columns: ['zone_id'], where: 'id = ?', whereArgs: [schedule.id]);
    if (existing.isEmpty) return;
    final zoneId = existing.first['zone_id'] as int;
    
    await db.update(
      'irrigation_schedules',
      schedule.toMap(zoneId),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<Map<String, dynamic>?> getIrrigationSettings(int? zoneId) async {
    if (zoneId == null) return null;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'irrigation_settings',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<void> saveIrrigationSettings(
    int? zoneId,
    String mode,
    String syncMode,
    int sunriseOffset,
    int sunsetOffset, {
    double? targetWaterLevel,
    int? refillPumpId,
    int? upperFloatSensorId,
    int? lowerFloatSensorId,
    String? sensingMethod,
    int? analogSensorId,
  }) async {
    if (zoneId == null) return;
    final db = await database;
    
    await db.insert(
      'irrigation_settings',
      {
        'zone_id': zoneId,
        'mode': mode,
        'sync_mode': syncMode,
        'sunrise_offset': sunriseOffset,
        'sunset_offset': sunsetOffset,
        'target_water_level': targetWaterLevel,
        'refill_pump_id': refillPumpId,
        'upper_float_sensor_id': upperFloatSensorId,
        'lower_float_sensor_id': lowerFloatSensorId,
        'sensing_method': sensingMethod,
        'analog_sensor_id': analogSensorId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Lighting
  Future<List<LightingSchedule>> getLightingSchedules(int zoneId) async {
    final db = await database;
    final maps = await db.query('lighting_schedules', where: 'zone_id = ?', whereArgs: [zoneId]);
    return List.generate(maps.length, (i) => LightingSchedule.fromMap(maps[i]));
  }

  Future<void> insertLightingSchedule(LightingSchedule schedule, int zoneId) async {
    final db = await database;
    await db.insert('lighting_schedules', schedule.toMap(zoneId), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteLightingSchedule(String id) async {
    final db = await database;
    await db.delete('lighting_schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateLightingSchedule(LightingSchedule schedule) async {
    final db = await database;
    final existing = await db.query('lighting_schedules', columns: ['zone_id'], where: 'id = ?', whereArgs: [schedule.id]);
    if (existing.isEmpty) return;
    final zoneId = existing.first['zone_id'] as int;

    await db.update(
      'lighting_schedules',
      schedule.toMap(zoneId),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<Map<String, dynamic>?> getLightingSettings(int zoneId) async {
    final db = await database;
    final maps = await db.query('lighting_settings', where: 'zone_id = ?', whereArgs: [zoneId]);
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<void> saveLightingSettings(int zoneId, String mode, String syncMode, int sunriseOffset, int sunsetOffset) async {
    final db = await database;
    await db.insert('lighting_settings', {
      'zone_id': zoneId,
      'mode': mode,
      'sync_mode': syncMode,
      'sunrise_offset': sunriseOffset,
      'sunset_offset': sunsetOffset,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Ventilation
  Future<List<HvacSchedule>> getHvacSchedules(int zoneId) async {
    final db = await database;
    final maps = await db.query('ventilation_schedules', where: 'zone_id = ?', whereArgs: [zoneId]);
    return List.generate(maps.length, (i) => HvacSchedule.fromMap(maps[i]));
  }

  Future<List<HvacSchedule>> getVentilationSchedules(int zoneId) async {
    return getHvacSchedules(zoneId);
  }

  Future<void> insertHvacSchedule(HvacSchedule schedule, int zoneId) async {
    final db = await database;
    await db.insert('ventilation_schedules', schedule.toMap(zoneId), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteHvacSchedule(String id) async {
    final db = await database;
    await db.delete('ventilation_schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateHvacSchedule(HvacSchedule schedule) async {
    final db = await database;
    final existing = await db.query('ventilation_schedules', columns: ['zone_id'], where: 'id = ?', whereArgs: [schedule.id]);
    if (existing.isEmpty) return;
    final zoneId = existing.first['zone_id'] as int;

    await db.update(
      'ventilation_schedules',
      schedule.toMap(zoneId),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<Map<String, dynamic>?> getHvacSettings(int zoneId) async {
    final db = await database;
    final maps = await db.query('ventilation_settings', where: 'zone_id = ?', whereArgs: [zoneId]);
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<void> saveHvacSettings(int zoneId, String mode, String controlMode, double alwaysOnSpeed) async {
    final db = await database;
    await db.insert('ventilation_settings', {
      'zone_id': zoneId,
      'mode': mode,
      'control_mode': controlMode,
      'always_on_speed': alwaysOnSpeed,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }



  Future<int> createZone(
    int? growId, 
    String name, {
    String? growMethod,
    bool hasIrrigation = false,
    bool hasLighting = false,
    bool hasHvac = false,
    bool hasAeration = false,
    bool hasCameras = false,
  }) async {
    final db = await database;
    final Map<String, dynamic> values = {
      'grow_id': growId,
      'name': name,
      'enabled': 1,
      'has_irrigation': hasIrrigation ? 1 : 0,
      'has_lighting': hasLighting ? 1 : 0,
      'has_hvac': hasHvac ? 1 : 0,
      'has_aeration': hasAeration ? 1 : 0,
      'has_cameras': hasCameras ? 1 : 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };

    if (growMethod != null) values['grow_method'] = growMethod;

    return await db.insert('zones', values);
  }



  Future<int> toggleZone(int id, bool enabled) async {
    final db = await database;

    try {
      return await db.update(
        'zones',
        {
          'enabled': enabled ? 1 : 0,
          'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error toggling zone: $e');
      rethrow;
    }
  }

  Future<void> deleteZone(int id) async {
    final db = await database;

    // Use transaction to ensure all related data is removed
    await db.transaction((txn) async {
      // 1. Release IO channels assigned to zone controls
      final List<Map<String, dynamic>> controls = await txn.query(
        'zone_controls',
        columns: ['id'],
        where: 'zone_id = ?',
        whereArgs: [id],
      );

      for (var control in controls) {
        int controlId = control['id'];
        
        // Get assignments for this control
        final List<Map<String, dynamic>> assignments = await txn.query(
          'control_io_assignments',
          columns: ['io_channel_id'],
          where: 'zone_control_id = ?',
          whereArgs: [controlId],
        );

        for (var assignment in assignments) {
          int channelId = assignment['io_channel_id'];
          // Mark channel as unassigned
          await txn.update(
            'io_channels',
            {'is_assigned': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000},
            where: 'id = ?',
            whereArgs: [channelId],
          );
        }
        
        // Delete assignments explicitly
        await txn.delete(
          'control_io_assignments',
          where: 'zone_control_id = ?',
          whereArgs: [controlId],
        );
        
        // Delete control settings, schedules, logs
        await txn.delete('control_settings', where: 'zone_control_id = ?', whereArgs: [controlId]);
        await txn.delete('control_schedules', where: 'zone_control_id = ?', whereArgs: [controlId]);
        await txn.delete('control_status_log', where: 'zone_control_id = ?', whereArgs: [controlId]);
      }

      // Delete zone controls
      await txn.delete(
        'zone_controls',
        where: 'zone_id = ?',
        whereArgs: [id],
      );
      
      // Delete irrigation schedules
      await txn.delete(
        'irrigation_schedules',
        where: 'zone_id = ?',
        whereArgs: [id],
      );

      // Delete related sensors
      await txn.delete('sensors', where: 'zone_id = ?', whereArgs: [id]);

      // Delete camera assignments
      await txn.delete(
        'camera_assignments',
        where: 'zone_id = ?',
        whereArgs: [id],
      );
      
      // Delete zone crops
      await txn.delete('zone_crops', where: 'zone_id = ?', whereArgs: [id]);
      
      // Delete irrigation settings
      await txn.delete('irrigation_settings', where: 'zone_id = ?', whereArgs: [id]);
      
      // Delete ventilation settings
      await txn.delete('ventilation_settings', where: 'zone_id = ?', whereArgs: [id]);
      
      // Delete lighting settings
      await txn.delete('lighting_settings', where: 'zone_id = ?', whereArgs: [id]);
      
      // Delete aeration settings
      await txn.delete('aeration_settings', where: 'zone_id = ?', whereArgs: [id]);
      
      // Delete aeration schedules
      await txn.delete('aeration_schedules', where: 'zone_id = ?', whereArgs: [id]);

      // Delete the zone itself
      await txn.delete('zones', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Get zone control summary
  Future<List<ZoneControlSummary>> getZoneControlSummary(int zoneId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        zc.id, 
        zc.name,
        COALESCE(ct.name, 'unknown') as type,
        zc.enabled
      FROM zone_controls zc
      LEFT JOIN control_types ct ON zc.control_type_id = ct.id
      WHERE zc.zone_id = ?
    ''',
      [zoneId],
    );

    return List.generate(maps.length, (i) {
      return ZoneControlSummary(
        id: maps[i]['id'],
        name: maps[i]['name'] ?? 'Unnamed Control',
        type: maps[i]['type'] ?? 'unknown',
        enabled: maps[i]['enabled'] == 1,
      );
    });
  }

  // IO CHANNEL METHODS




  Future<List<IoChannel>> getAvailableIoChannels() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'io_channels',
      where: 'is_assigned = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) {
      return IoChannel.fromMap(maps[i]);
    });
  }

  Future<void> assignIoChannel(int channelId, bool isAssigned) async {
    final db = await database;

    await db.update(
      'io_channels',
      {
        'is_assigned': isAssigned ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [channelId],
    );
  }

  Future<void> addIoModule(int moduleNumber, int channelCount) async {
    final db = await database;

    // Get the highest channel number for this module
    final List<Map<String, dynamic>> maps = await db.query(
      'io_channels',
      where: 'module_number = ?',
      whereArgs: [moduleNumber],
      orderBy: 'channel_number DESC',
      limit: 1,
    );

    int startChannel = 0;
    if (maps.isNotEmpty) {
      startChannel = (maps.first['channel_number'] as int) + 1;
    }
    // Add new channels
    final batch = db.batch();
    for (int i = 0; i < channelCount; i++) {
      batch.insert('io_channels', {
        'channel_number': startChannel + i,
        'module_number': moduleNumber,
        'is_input': 0,
        'name': 'Channel ${startChannel + i + 1}',
        'is_assigned': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
    }
    await batch.commit();
  }

  // ZONE CONTROL METHODS

  Future<List<EnvironmentalControl>> getZoneControls(int zoneId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        zc.id, 
        zc.zone_id,
        zc.control_type_id,
        zc.name,
        zc.enabled,
        ct.name as type_name
      FROM zone_controls zc
      LEFT JOIN control_types ct ON zc.control_type_id = ct.id
      WHERE zc.zone_id = ?
    ''',
      [zoneId],
    );

    return List.generate(maps.length, (i) {
      return EnvironmentalControl.fromMap(maps[i]);
    });
  }

  Future<EnvironmentalControl?> getZoneControl(int controlId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        zc.id, 
        zc.zone_id,
        zc.control_type_id,
        zc.name,
        zc.enabled,
        ct.name as type_name
      FROM zone_controls zc
      JOIN control_types ct ON zc.control_type_id = ct.id
      WHERE zc.id = ?
    ''',
      [controlId],
    );

    if (maps.isNotEmpty) {
      return EnvironmentalControl.fromMap(maps.first);
    }

    return null;
  }

  Future<int> createZoneControl(
    int zoneId,
    int controlTypeId,
    String name, {
    bool enabled = true,
  }) async {
    final db = await database;

    return await db.insert('zone_controls', {
      'zone_id': zoneId,
      'control_type_id': controlTypeId,
      'name': name,
      'enabled': enabled ? 1 : 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  Future<int> updateZoneControlName(int controlId, String name) async {
    final db = await database;

    return await db.update(
      'zone_controls',
      {
        'name': name,
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [controlId],
    );
  }

  Future<int> toggleZoneControl(int controlId, bool enabled) async {
    final db = await database;

    // Log the state change
    int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await db.insert('control_status_log', {
      'zone_control_id': controlId,
      'state': enabled ? 'on' : 'off',
      'reason': 'manual',
      'timestamp': timestamp,
    });

    return await db.update(
      'zone_controls',
      {'enabled': enabled ? 1 : 0, 'updated_at': timestamp},
      where: 'id = ?',
      whereArgs: [controlId],
    );
  }

  Future<void> deleteZoneControl(int controlId) async {
    final db = await database;

    // Use transaction to ensure all related data is removed
    await db.transaction((txn) async {
      // Release IO channels first
      final List<Map<String, dynamic>> assignments = await txn.query(
        'control_io_assignments',
        columns: ['io_channel_id'],
        where: 'zone_control_id = ?',
        whereArgs: [controlId],
      );

      for (var assignment in assignments) {
        int channelId = assignment['io_channel_id'];
        // Mark channel as unassigned
        await txn.update(
          'io_channels',
          {'is_assigned': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000},
          where: 'id = ?',
          whereArgs: [channelId],
        );
      }

      // Delete control settings
      await txn.delete(
        'control_settings',
        where: 'zone_control_id = ?',
        whereArgs: [controlId],
      );

      // Delete control schedules
      await txn.delete(
        'control_schedules',
        where: 'zone_control_id = ?',
        whereArgs: [controlId],
      );

      // Delete control IO assignments
      await txn.delete(
        'control_io_assignments',
        where: 'zone_control_id = ?',
        whereArgs: [controlId],
      );

      // Delete control status logs
      await txn.delete(
        'control_status_log',
        where: 'zone_control_id = ?',
        whereArgs: [controlId],
      );

      // Delete the control itself
      await txn.delete(
        'zone_controls',
        where: 'id = ?',
        whereArgs: [controlId],
      );
    });
  }

  // CONTROL SETTINGS METHODS

  Future<List<ControlSetting>> getControlSettings(int controlId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'control_settings',
      where: 'zone_control_id = ?',
      whereArgs: [controlId],
    );

    return List.generate(maps.length, (i) {
      return ControlSetting.fromMap(maps[i]);
    });
  }

  Future<ControlSetting?> getControlSetting(
    int controlId,
    String settingName,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'control_settings',
      where: 'zone_control_id = ? AND setting_name = ?',
      whereArgs: [controlId, settingName],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ControlSetting.fromMap(maps.first);
    }

    return null;
  }

  Future<void> updateControlSetting(
    int controlId,
    String settingName,
    String value, {
    String? unit,
  }) async {
    final db = await database;

    // Check if setting exists
    final List<Map<String, dynamic>> maps = await db.query(
      'control_settings',
      where: 'zone_control_id = ? AND setting_name = ?',
      whereArgs: [controlId, settingName],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      // Update existing setting
      await db.update(
        'control_settings',
        {
          'setting_value': value,
          'setting_unit': unit,
          'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'zone_control_id = ? AND setting_name = ?',
        whereArgs: [controlId, settingName],
      );
    } else {
      // Create new setting
      await db.insert('control_settings', {
        'zone_control_id': controlId,
        'setting_name': settingName,
        'setting_value': value,
        'setting_unit': unit,
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
    }
  }

  // CONTROL IO ASSIGNMENTS METHODS

  Future<List<IoAssignment>> getControlIoAssignments(int controlId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        cia.id,
        cia.zone_control_id,
        cia.io_channel_id,
        cia.function,
        cia.invert_logic,
        ic.channel_number,
        ic.module_number,
        ic.is_input,
        ic.name as channel_name
      FROM control_io_assignments cia
      JOIN io_channels ic ON cia.io_channel_id = ic.id
      WHERE cia.zone_control_id = ?
    ''',
      [controlId],
    );

    return List.generate(maps.length, (i) {
      return IoAssignment.fromMap(maps[i]);
    });
  }

  Future<int> assignControlIo(
    int controlId,
    int channelId,
    String function, {
    bool invertLogic = false,
  }) async {
    final db = await database;

    int assignmentId = await db.insert('control_io_assignments', {
      'zone_control_id': controlId,
      'io_channel_id': channelId,
      'function': function,
      'invert_logic': invertLogic ? 1 : 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });

    // Mark the channel as assigned
    await assignIoChannel(channelId, true);

    return assignmentId;
  }

  Future<void> updateIoAssignment(
    int assignmentId, {
    int? channelId,
    String? function,
    bool? invertLogic,
  }) async {
    final db = await database;

    Map<String, dynamic> updateData = {
      'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };

    if (channelId != null) {
      // Get the old channel ID first
      final List<Map<String, dynamic>> maps = await db.query(
        'control_io_assignments',
        columns: ['io_channel_id'],
        where: 'id = ?',
        whereArgs: [assignmentId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        final oldChannelId = maps.first['io_channel_id'] as int;

        // Mark the old channel as unassigned
        await assignIoChannel(oldChannelId, false);

        // Mark the new channel as assigned
        await assignIoChannel(channelId, true);

        updateData['io_channel_id'] = channelId;
      }
    }

    if (function != null) {
      updateData['function'] = function;
    }

    if (invertLogic != null) {
      updateData['invert_logic'] = invertLogic ? 1 : 0;
    }

    await db.update(
      'control_io_assignments',
      updateData,
      where: 'id = ?',
      whereArgs: [assignmentId],
    );
  }

  Future<void> deleteIoAssignment(int assignmentId) async {
    final db = await database;

    // Get the channel ID first
    final List<Map<String, dynamic>> maps = await db.query(
      'control_io_assignments',
      columns: ['io_channel_id'],
      where: 'id = ?',
      whereArgs: [assignmentId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final channelId = maps.first['io_channel_id'] as int;

      // Mark the channel as unassigned
      await assignIoChannel(channelId, false);

      // Delete the assignment
      await db.delete(
        'control_io_assignments',
        where: 'id = ?',
        whereArgs: [assignmentId],
      );
    }
  }

  // CONTROL SCHEDULES METHODS

  Future<List<ControlSchedule>> getControlSchedules(int controlId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'control_schedules',
      where: 'zone_control_id = ?',
      whereArgs: [controlId],
    );

    return List.generate(maps.length, (i) {
      return ControlSchedule.fromMap(maps[i]);
    });
  }

  Future<ControlSchedule?> getControlSchedule(int scheduleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'control_schedules',
      where: 'id = ?',
      whereArgs: [scheduleId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ControlSchedule.fromMap(maps.first);
    }

    return null;
  }

  Future<int> createControlSchedule(ControlSchedule schedule) async {
    final db = await database;

    Map<String, dynamic> scheduleMap = schedule.toMap();
    scheduleMap.remove('id'); // Remove id for insert
    scheduleMap['created_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    scheduleMap['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.insert('control_schedules', scheduleMap);
  }

  Future<int> updateControlSchedule(ControlSchedule schedule) async {
    final db = await database;

    Map<String, dynamic> scheduleMap = schedule.toMap();
    scheduleMap['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.update(
      'control_schedules',
      scheduleMap,
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> toggleSchedule(int scheduleId, bool enabled) async {
    final db = await database;

    return await db.update(
      'control_schedules',
      {
        'enabled': enabled ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }

  Future<int> deleteSchedule(int scheduleId) async {
    final db = await database;

    return await db.delete(
      'control_schedules',
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }

  // SENSOR METHODS

  Future<List<Sensor>> getZoneSensors(int zoneId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sensors',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
      orderBy: 'display_order ASC, id ASC',
    );

    return List.generate(maps.length, (i) {
      return Sensor.fromMap(maps[i]);
    });
  }

  Future<Sensor?> getSensor(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sensors',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Sensor.fromMap(maps.first);
    }

    return null;
  }

  Future<int> addSensor(Sensor sensor) async {
    final db = await database;

    Map<String, dynamic> sensorMap = sensor.toMap();
    sensorMap.remove('id'); // Remove id for insert
    sensorMap['created_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    sensorMap['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.insert('sensors', sensorMap);
  }

  Future<int> updateSensor(Sensor sensor) async {
    final db = await database;

    Map<String, dynamic> sensorMap = sensor.toMap();
    sensorMap['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.update(
      'sensors',
      sensorMap,
      where: 'id = ?',
      whereArgs: [sensor.id],
    );
  }

  Future<int> deleteSensor(int sensorId) async {
    final db = await database;

    // Delete sensor readings first
    await db.delete(
      'sensor_readings',
      where: 'sensor_id = ?',
      whereArgs: [sensorId],
    );

    // Delete the sensor
    return await db.delete('sensors', where: 'id = ?', whereArgs: [sensorId]);
  }

  Future<int> logSensorReading(
    int sensorId,
    String readingType,
    double value, {
    int? timestamp,
  }) async {
    final db = await database;

    return await db.insert('sensor_readings', {
      'sensor_id': sensorId,
      'reading_type': readingType,
      'value': value,
      'timestamp': timestamp ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
    });
  }

  Future<List<SensorReading>> getSensorReadings(
    int sensorId,
    String readingType, {
    int? limit,
    int? startTime,
    int? endTime,
  }) async {
    final db = await database;

    String whereClause = 'sensor_id = ? AND reading_type = ?';
    List<dynamic> whereArgs = [sensorId, readingType];

    if (startTime != null) {
      whereClause += ' AND timestamp >= ?';
      whereArgs.add(startTime);
    }

    if (endTime != null) {
      whereClause += ' AND timestamp <= ?';
      whereArgs.add(endTime);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'sensor_readings',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return SensorReading.fromMap(maps[i]);
    });
  }

  Future<Sensor?> getSensorById(int sensorId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sensors',
      where: 'id = ?',
      whereArgs: [sensorId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Sensor.fromMap(maps.first);
    }

    return null;
  }

  Future<void> updateSensorOrder(List<Sensor> sensors) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < sensors.length; i++) {
      batch.update(
        'sensors',
        {'display_order': i},
        where: 'id = ?',
        whereArgs: [sensors[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  // WATERING TIMER METHODS

  Future<List<WateringTimer>> getZoneTimers(int zoneId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'watering_timers',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
    );

    return List.generate(maps.length, (i) {
      return WateringTimer.fromMap(maps[i]);
    });
  }

  Future<List<WateringTimer>> getAllActiveTimers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT wt.*
      FROM watering_timers wt
      JOIN zones z ON wt.zone_id = z.id
      WHERE wt.enabled = 1 AND z.enabled = 1
    ''');

    return List.generate(maps.length, (i) {
      return WateringTimer.fromMap(maps[i]);
    });
  }

  Future<int> createWateringTimer(WateringTimer timer) async {
    final db = await database;

    Map<String, dynamic> timerMap = timer.toMap();
    timerMap.remove('id'); // Remove id for insert
    timerMap['created_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    timerMap['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.insert('watering_timers', timerMap);
  }

  Future<int> updateWateringTimer(WateringTimer timer) async {
    final db = await database;

    Map<String, dynamic> timerMap = timer.toMap();
    timerMap['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.update(
      'watering_timers',
      timerMap,
      where: 'id = ?',
      whereArgs: [timer.id],
    );
  }

  Future<int> updateTimerNextRun(int timerId, int nextRun) async {
    final db = await database;

    return await db.update(
      'watering_timers',
      {
        'next_run': nextRun,
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [timerId],
    );
  }

  Future<int> logTimerExecution(
    int timerId,
    int startTime, {
    int? endTime,
    bool? success,
    String? notes,
  }) async {
    final db = await database;

    // Update last_run in the timer
    await db.update(
      'watering_timers',
      {
        'last_run': startTime,
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [timerId],
    );

    // Log the execution
    return await db.insert('timer_log', {
      'timer_id': timerId,
      'start_time': startTime,
      'end_time': endTime,
      'success': success != null ? (success ? 1 : 0) : null,
      'notes': notes,
    });
  }

  Future<int> deleteWateringTimer(int timerId) async {
    final db = await database;

    // Delete timer logs first
    await db.delete('timer_log', where: 'timer_id = ?', whereArgs: [timerId]);

    // Delete the timer
    return await db.delete(
      'watering_timers',
      where: 'id = ?',
      whereArgs: [timerId],
    );
  }

  // GROW MODE METHODS

  Future<List<GrowMode>> getGrowModes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('grow_modes');

    return List.generate(maps.length, (i) {
      return GrowMode.fromMap(maps[i]);
    });
  }

  Future<GrowMode?> getGrowMode(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'grow_modes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return GrowMode.fromMap(maps.first);
    }

    return null;
  }


  // SYSTEM CONFIG METHODS

  Future<SystemConfig?> getSystemConfig() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('system_config');

    if (maps.isEmpty) {
      return null;
    }

    return SystemConfig.fromMap(maps.first);
  }

  Future<void> saveSystemConfig(SystemConfig config) async {
    final db = await database;

    // Check if config already exists
    final List<Map<String, dynamic>> maps = await db.query('system_config');

    final configMap = config.toMap();
    configMap['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (maps.isEmpty) {
      // Insert new config
      configMap['created_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await db.insert('system_config', configMap);
    } else {
      // Update existing config
      await db.update(
        'system_config',
        configMap,
        where: 'id = ?',
        whereArgs: [maps.first['id']],
      );
    }
  }

  Future<void> completeSetup() async {
    // Check how many zones we have to populate zoneCount
    final zones = await getZones();
    
    final config = SystemConfig(
      id: 1, 
      systemType: 'standard', // Default value
      facilityScale: 'home', // Default value
      zoneCount: zones.length,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    await saveSystemConfig(config);
  }

  // LOCATION SETTINGS METHODS

  Future<LocationSettings?> getLocationSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('location_settings');

    if (maps.isEmpty) {
      return null;
    }

    return LocationSettings.fromMap(maps.first);
  }

  Future<void> saveLocationSettings(LocationSettings settings) async {
    final db = await database;

    // Check if settings already exist
    final List<Map<String, dynamic>> maps = await db.query('location_settings');

    final settingsMap = settings.toMap();
    settingsMap['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (maps.isEmpty) {
      // Insert new settings
      settingsMap['created_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await db.insert('location_settings', settingsMap);
    } else {
      // Update existing settings
      await db.update(
        'location_settings',
        settingsMap,
        where: 'id = ?',
        whereArgs: [maps.first['id']],
      );
    }
  }

  // CAMERA METHODS

  Future<List<camera_model.Camera>> getCameras() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cameras');

    return List.generate(maps.length, (i) {
      return camera_model.Camera.fromMap(maps[i]);
    });
  }

  Future<camera_model.Camera?> getCamera(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cameras',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return camera_model.Camera.fromMap(maps.first);
    }

    return null;
  }

  Future<int> addCamera(camera_model.Camera camera) async {
    final db = await database;

    Map<String, dynamic> cameraMap = camera.toMap();
    cameraMap.remove('id'); // Remove id for insert
    cameraMap['created_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    cameraMap['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.insert('cameras', cameraMap);
  }

  Future<int> updateCamera(camera_model.Camera camera) async {
    final db = await database;

    Map<String, dynamic> cameraMap = camera.toMap();
    cameraMap['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.update(
      'cameras',
      cameraMap,
      where: 'id = ?',
      whereArgs: [camera.id],
    );
  }

  Future<void> deleteCamera(int cameraId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete dependent records first
      await txn.delete(
        'camera_assignments',
        where: 'camera_id = ?',
        whereArgs: [cameraId],
      );
      
      await txn.delete(
        'images',
        where: 'camera_id = ?',
        whereArgs: [cameraId],
      );

      // Delete the camera
      await txn.delete(
        'cameras',
        where: 'id = ?',
        whereArgs: [cameraId],
      );
    });
  }

  Future<void> assignCameraToZone(
    int cameraId,
    int zoneId,
    String position,
  ) async {
    final db = await database;

    await db.insert('camera_assignments', {
      'camera_id': cameraId,
      'zone_id': zoneId,
      'view_type': position,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  Future<void> removeCameraFromZone(int cameraId, int zoneId) async {
    final db = await database;

    await db.delete(
      'camera_assignments',
      where: 'camera_id = ? AND zone_id = ?',
      whereArgs: [cameraId, zoneId],
    );
  }

  Future<List<CameraAssignment>> getZoneCameras(int zoneId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        ca.id,
        ca.camera_id,
        ca.zone_id,
        ca.view_type as position,
        c.name,
        c.device_path,
        c.enabled
      FROM camera_assignments ca
      JOIN cameras c ON ca.camera_id = c.id
      WHERE ca.zone_id = ?
    ''',
      [zoneId],
    );

    return List.generate(maps.length, (i) {
      return CameraAssignment.fromMap(maps[i]);
    });
  }

  Future<CameraAssignment?> getCameraAssignment(int cameraId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'camera_assignments',
      where: 'camera_id = ?',
      whereArgs: [cameraId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return CameraAssignment.fromMap(maps.first);
    }
    return null;
  }

  // IMAGE METHODS

  Future<int> saveImage(
    int cameraId,
    int growId,
    String filePath, {
    String? thumbnailPath,
    int? timestamp,
    int? growDay,
    int? growHour,
    String? notes,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Get grow start time if growDay/growHour not provided
    if (growDay == null || growHour == null) {
      final List<Map<String, dynamic>> growMaps = await db.query(
        'grows',
        columns: ['start_time'],
        where: 'id = ?',
        whereArgs: [growId],
        limit: 1,
      );

      if (growMaps.isNotEmpty) {
        final startTime = growMaps.first['start_time'] as int;
        final currentTime = timestamp ?? now;
        final elapsedSeconds = currentTime - startTime;

        growDay = elapsedSeconds ~/ (24 * 3600);
        growHour = (elapsedSeconds % (24 * 3600)) ~/ 3600;
      }
    }

    return await db.insert('images', {
      'camera_id': cameraId,
      'grow_id': growId,
      'file_path': filePath,
      'thumbnail_path': thumbnailPath,
      'timestamp': timestamp ?? now,
      'grow_day': growDay ?? 0,
      'grow_hour': growHour ?? 0,
      'notes': notes,
      'created_at': now,
    });
  }

  Future<List<ImageInfo>> getGrowImages(
    int growId, {
    int? limit,
    int? offset,
    String? sortBy,
    bool descending = true,
  }) async {
    final db = await database;

    String orderBy = sortBy ?? 'timestamp';
    if (descending) {
      orderBy += ' DESC';
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'images',
      where: 'grow_id = ?',
      whereArgs: [growId],
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) {
      return ImageInfo.fromMap(maps[i]);
    });
  }

  Future<ImageInfo?> getImage(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'images',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ImageInfo.fromMap(maps.first);
    }

    return null;
  }

  Future<int> updateImageNotes(int id, String notes) async {
    final db = await database;

    return await db.update(
      'images',
      {'notes': notes},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteImage(int id) async {
    final db = await database;

    return await db.delete('images', where: 'id = ?', whereArgs: [id]);
  }

  // GENERAL SETTINGS METHODS

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }

    return null;
  }

  Future<bool> getBoolSetting(String key, {bool defaultValue = false}) async {
    final value = await getSetting(key);
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }

  Future<int> getIntSetting(String key, {int defaultValue = 0}) async {
    final value = await getSetting(key);
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  Future<double> getDoubleSetting(
    String key, {
    double defaultValue = 0.0,
  }) async {
    final value = await getSetting(key);
    if (value == null) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }

  Future<void> saveSetting(String key, String value, String dataType) async {
    final db = await database;

    // Check if setting exists
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (maps.isEmpty) {
      // Insert new setting
      await db.insert('settings', {
        'key': key,
        'value': value,
        'data_type': dataType,
        'created_at': now,
        'updated_at': now,
      });
    } else {
      // Update existing setting
      await db.update(
        'settings',
        {'value': value, 'data_type': dataType, 'updated_at': now},
        where: 'key = ?',
        whereArgs: [key],
      );
    }
  }

  Future<void> saveStringSetting(String key, String value) async {
    await saveSetting(key, value, 'string');
  }

  Future<void> saveBoolSetting(String key, bool value) async {
    await saveSetting(key, value.toString(), 'bool');
  }

  Future<void> saveIntSetting(String key, int value) async {
    await saveSetting(key, value.toString(), 'int');
  }

  Future<void> saveDoubleSetting(String key, double value) async {
    await saveSetting(key, value.toString(), 'float');
  }

  Future<void> saveJsonSetting(String key, Map<String, dynamic> value) async {
    await saveSetting(key, json.encode(value), 'json');
  }

  // DATABASE MAINTENANCE

  Future<void> vacuumDatabase() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<void> deleteOldLogs(int daysToKeep) async {
    final db = await database;
    final cutoffTime =
        DateTime.now()
            .subtract(Duration(days: daysToKeep))
            .millisecondsSinceEpoch ~/
        1000;

    await db.delete(
      'sensor_readings',
      where: 'timestamp < ?',
      whereArgs: [cutoffTime],
    );

    await db.delete(
      'control_status_log',
      where: 'timestamp < ?',
      whereArgs: [cutoffTime],
    );

    await db.delete(
      'timer_log',
      where: 'start_time < ?',
      whereArgs: [cutoffTime],
    );
  }

  Future<void> performMaintenance() async {
    // Get maintenance settings
    final logRetentionDays = await getIntSetting(
      'log_retention_days',
      defaultValue: 90,
    );

    // Delete old logs
    await deleteOldLogs(logRetentionDays);

    // Optimize database
    await vacuumDatabase();
  }

  // WAVESHARE RELAY SETUP METHODS

  /// Set up Waveshare relay channels in the database
  Future<void> setupWaveshareRelayChannels() async {
    final db = await database;
    await _createDefaultIoChannels(db);
  }

  Future<void> _createDefaultIoChannels(Database db) async {
    // Check if Waveshare relay channels already exist
    final List<Map<String, dynamic>> existingChannels = await db.query(
      'io_channels',
      where: 'module_number = ?',
      whereArgs: [100],
    );

    if (existingChannels.isNotEmpty) {
      return; // Already exist
    }

    // Add Waveshare relay channels
    final batch = db.batch();
    final relayNames = [
      'Waveshare Relay 1',
      'Waveshare Relay 2',
      'Waveshare Relay 3',
      'Waveshare Relay 4',
      'Waveshare Relay 5',
      'Waveshare Relay 6',
      'Waveshare Relay 7',
      'Waveshare Relay 8',
    ];

    for (int i = 0; i < relayNames.length; i++) {
      batch.insert('io_channels', {
        'channel_number': i, // 0-7 for database storage
        'module_number': 100, // 100 indicates Waveshare relay
        'is_input': 0, // These are output channels
        'name': relayNames[i],
        'is_assigned': 0, // Initially unassigned
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch.commit();
  }


  /// Create default IO channels for a module
Future<void> createIoChannelsForModule(int moduleNumber, int channelCount, {String prefix = 'Channel'}) async {
  final db = await database;
  final batch = db.batch();
  
  // Specific Logic for Sensor Hubs (channelCount is ignored if we assume standard hub layout, 
  // but we can keep it for flexibility or check if it matches 11)
  
  // 2 I2C, 1 SPI, 4 DIs, 2 AO(0-10V) 2 AI (4-20mA) = 11 Total
  
  int currentChannel = 0;

  // 1. I2C (2 Channels)
  for (int i = 0; i < 2; i++) {
    batch.insert('io_channels', {
      'channel_number': currentChannel++,
      'module_number': moduleNumber,
      'is_input': 1, 
      'type': 'i2c',
      'name': '$prefix I2C ${i + 1}',
      'is_assigned': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  // 2. SPI (1 Channel)
  batch.insert('io_channels', {
    'channel_number': currentChannel++,
    'module_number': moduleNumber,
    'is_input': 1,
    'type': 'spi',
    'name': '$prefix SPI 1',
    'is_assigned': 0,
    'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
  });

  // 3. Digital Inputs (4 Channels)
  for (int i = 0; i < 4; i++) {
    batch.insert('io_channels', {
      'channel_number': currentChannel++,
      'module_number': moduleNumber,
      'is_input': 1,
      'type': 'di',
      'name': '$prefix DI ${i + 1}',
      'is_assigned': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  // 4. Analog Outputs (2 Channels) - 0-10V
  for (int i = 0; i < 2; i++) {
    batch.insert('io_channels', {
      'channel_number': currentChannel++,
      'module_number': moduleNumber,
      'is_input': 0, // Output
      'type': 'ao_0_10v',
      'name': '$prefix AO ${i + 1}',
      'is_assigned': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  // 5. Analog Inputs (2 Channels) - 4-20mA
  for (int i = 0; i < 2; i++) {
    batch.insert('io_channels', {
      'channel_number': currentChannel++,
      'module_number': moduleNumber,
      'is_input': 1,
      'type': 'ai_4_20ma',
      'name': '$prefix AI ${i + 1}',
      'is_assigned': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }
  
  await batch.commit();
}

  /// Get Waveshare relay channels
  Future<List<IoChannel>> getWaveshareRelayChannels() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'io_channels',
      where: 'module_number = ?',
      whereArgs: [100],
      orderBy: 'channel_number ASC',
    );

    return List.generate(maps.length, (i) {
      return IoChannel.fromMap(maps[i]);
    });
  }

  /// Get available (unassigned) Waveshare relay channels
  Future<List<IoChannel>> getAvailableWaveshareRelayChannels() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'io_channels',
      where: 'module_number = ? AND is_assigned = ?',
      whereArgs: [100, 0],
      orderBy: 'channel_number ASC',
    );

    return List.generate(maps.length, (i) {
      return IoChannel.fromMap(maps[i]);
    });
  }

  /// Update Waveshare relay channel name
  Future<int> updateWaveshareRelayChannelName(
    int channelNumber,
    String name,
  ) async {
    final db = await database;

    return await db.update(
      'io_channels',
      {
        'name': name,
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'module_number = ? AND channel_number = ?',
      whereArgs: [100, channelNumber],
    );
  }


  // AERATION METHODS

  Future<List<Map<String, dynamic>>> getAerationSchedules(int zoneId) async {
    final db = await database;
    return await db.query(
      'aeration_schedules',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
    );
  }

  Future<void> saveAerationSchedule(Map<String, dynamic> schedule) async {
    final db = await database;
    await db.insert(
      'aeration_schedules',
      schedule,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAerationSchedule(String id) async {
    final db = await database;
    await db.delete(
      'aeration_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getAerationSettings(int zoneId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'aeration_settings',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  // Seedling Mat Settings
  Future<Map<String, dynamic>?> getSeedlingMatSettings(int zoneId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'seedling_mat_settings',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> saveSeedlingMatSettings(Map<String, dynamic> settings) async {
    final db = await database;
    await db.insert(
      'seedling_mat_settings',
      settings,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Astral Simulation Settings
  Future<AstralSimulationSettings?> getAstralSimulationSettings(int zoneId) async {
    final db = await database;
    final maps = await db.query(
      'astral_simulation',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return AstralSimulationSettings.fromMap(maps.first);
    }
    return null;
  }

  Future<int> saveAstralSimulationSettings(AstralSimulationSettings settings) async {
    final db = await database;
    final existing = await getAstralSimulationSettings(settings.zoneId);
    
    if (existing != null) {
      return await db.update(
        'astral_simulation',
        settings.toMap()..['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000,
        where: 'zone_id = ?',
        whereArgs: [settings.zoneId],
      );
    } else {
      return await db.insert('astral_simulation', settings.toMap());
    }
  }

  Future<int> deleteAstralSimulationSettings(int zoneId) async {
    final db = await database;
    return await db.delete(
      'astral_simulation',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
    );
  }

  Future<void> saveAerationSettings(int zoneId, String mode, bool alwaysOnEnabled) async {
    final db = await database;
    await db.insert(
      'aeration_settings',
      {
        'zone_id': zoneId,
        'mode': mode,
        'always_on_enabled': alwaysOnEnabled ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }



  // SENSOR HUB METHODS

  Future<List<Sensor>> getSensorsByHub(int hubId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sensors',
      where: 'hub_id = ?',
      whereArgs: [hubId],
    );
    return List.generate(maps.length, (i) => Sensor.fromMap(maps[i]));
  }

  Future<List<SensorHub>> getSensorHubs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sensor_hubs');
    return List.generate(maps.length, (i) => SensorHub.fromMap(maps[i]));
  }

  Future<SensorHub?> getSensorHub(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sensor_hubs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return SensorHub.fromMap(maps.first);
    return null;
  }

  /// Get IO channel by ID
  Future<IoChannel?> getIoChannelById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'io_channels',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return IoChannel.fromMap(maps.first);
    }
    return null;
  }

  /// Get IO channels for a specific module
  Future<List<IoChannel>> getIoChannelsByModule(int moduleNumber) async {
    final db = await database;
    // Join with control_io_assignments and zone_controls to get the assigned device name
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        c.*, 
        zc.name as assigned_to_name 
      FROM io_channels c
      LEFT JOIN control_io_assignments cia ON c.id = cia.io_channel_id
      LEFT JOIN zone_controls zc ON cia.zone_control_id = zc.id
      WHERE c.module_number = ?
      ORDER BY c.channel_number ASC
    ''', [moduleNumber]);

    return List.generate(maps.length, (i) {
      return IoChannel.fromMap(maps[i]);
    });
  }

  /// Get all IO channels assigned to a specific zone
  Future<List<Map<String, dynamic>>> getZoneIoAssignments(int zoneId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        c.*, 
        zc.name as assigned_to_name,
        zc.category as assigned_category,
        zc.control_type
      FROM io_channels c
      JOIN control_io_assignments cia ON c.id = cia.io_channel_id
      JOIN zone_controls zc ON cia.zone_control_id = zc.id
      WHERE zc.zone_id = ?
    ''', [zoneId]);
  }

  Future<int> insertSensorHub(SensorHub hub) async {
    final db = await database;
    final map = hub.toMap();
    map.remove('id'); // Allow auto-increment
    return await db.insert('sensor_hubs', map);
  }

  Future<int> updateSensorHub(SensorHub hub) async {
    final db = await database;
    return await db.update(
      'sensor_hubs',
      hub.toMap(),
      where: 'id = ?',
      whereArgs: [hub.id],
    );
  }

  Future<int> deleteSensorHub(int id) async {
    final db = await database;
    return await db.delete('sensor_hubs', where: 'id = ?', whereArgs: [id]);
  }







  Future<List<Map<String, dynamic>>> getRecentDoses(int zoneId, {int hours = 48}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(hours: hours)).millisecondsSinceEpoch ~/ 1000;
    return await db.query(
      'dose_events',
      where: 'zone_id = ? AND timestamp >= ?',
      whereArgs: [zoneId, cutoff],
      orderBy: 'timestamp DESC',
    );
  }

  Future<int> getDoseCountLastHour(int zoneId) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM dose_events WHERE zone_id = ? AND timestamp >= ?',
      [zoneId, cutoff],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // RELAY & OUTPUT METHODS

  Future<List<Map<String, dynamic>>> getRelayModules() async {
    final db = await database;
    // Infer modules from IO channels
    return await db.rawQuery('SELECT DISTINCT module_number FROM io_channels');
  }

  Future<List<Map<String, dynamic>>> getAllOutputAssignments(int zoneId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        c.id, c.module_number, c.channel_number, c.name,
        zc.name as assigned_to,
        zc.category,
        CASE WHEN c.is_assigned = 1 THEN 1 ELSE 0 END as current_state
      FROM io_channels c
      JOIN control_io_assignments cia ON c.id = cia.io_channel_id
      JOIN zone_controls zc ON cia.zone_control_id = zc.id
      WHERE zc.zone_id = ?
    ''', [zoneId]);
  }

  // SCHEDULE METHODS

  Future<List<Map<String, dynamic>>> getIntervalSchedules(int zoneId) async {
    final db = await database;
    try {
      return await db.query('interval_schedules', where: 'zone_id = ?', whereArgs: [zoneId]);
    } catch (e) {
      return [];
    }
  }



  // HISTORY & SETTINGS

  Future<List<Map<String, dynamic>>> getAlertHistory(int zoneId, {int days = 7}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch ~/ 1000;
    return await db.query(
      'guardian_alerts',
      where: 'zone_id = ? AND created_at >= ?',
      whereArgs: [zoneId, cutoff],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>> getAllSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('settings');
    final Map<String, dynamic> settings = {};
    for (var map in maps) {
      settings[map['key'] as String] = map['value'];
    }
    return settings;
  }

  // SENSOR CALIBRATION METHODS

  Future<List<SensorCalibration>> getSensorCalibrations(int sensorId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sensor_calibrations',
      where: 'sensor_id = ?',
      whereArgs: [sensorId],
    );
    return List.generate(maps.length, (i) => SensorCalibration.fromMap(maps[i]));
  }

  Future<int> insertSensorCalibration(SensorCalibration calibration) async {
    final db = await database;
    return await db.insert('sensor_calibrations', calibration.toMap());
  }

  Future<int> updateSensorCalibration(SensorCalibration calibration) async {
    final db = await database;
    return await db.update(
      'sensor_calibrations',
      calibration.toMap(),
      where: 'id = ?',
      whereArgs: [calibration.id],
    );
  }

  // ==================== Crop Management CRUD ====================

  // Recipe Templates
  Future<int> createRecipeTemplate(Map<String, dynamic> values) async {
    final db = await database;
    values.remove('id');
    values['created_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return await db.insert('recipe_templates', values);
  }

  Future<List<Map<String, dynamic>>> getAllRecipeTemplates() async {
    final db = await database;
    return await db.query('recipe_templates');
  }

  Future<Map<String, dynamic>?> getRecipeTemplateById(int id) async {
    final db = await database;
    final maps = await db.query('recipe_templates', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<int> updateRecipeTemplate(int id, Map<String, dynamic> values) async {
    final db = await database;
    values['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return await db.update('recipe_templates', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteRecipeTemplate(int id) async {
    final db = await database;
    return await db.delete('recipe_templates', where: 'id = ?', whereArgs: [id]);
  }

  // Recipe Phases
  Future<int> createRecipePhase(Map<String, dynamic> values) async {
    final db = await database;
    values.remove('id');
    values['created_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return await db.insert('recipe_phases', values);
  }

  Future<List<Map<String, dynamic>>> getPhasesForTemplate(int templateId) async {
    final db = await database;
    return await db.query('recipe_phases', where: 'template_id = ?', whereArgs: [templateId]);
  }

  Future<Map<String, dynamic>?> getPhaseById(int id) async {
    final db = await database;
    final maps = await db.query('recipe_phases', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<int> updateRecipePhase(int id, Map<String, dynamic> values) async {
    final db = await database;
    values['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return await db.update('recipe_phases', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteRecipePhase(int id) async {
    final db = await database;
    return await db.delete('recipe_phases', where: 'id = ?', whereArgs: [id]);
  }



  // Zone Crops
  Future<int> assignCropToZone(Map<String, dynamic> values) async {
    final db = await database;
    values.remove('id');
    values['created_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return await db.insert('zone_crops', values);
  }

  Future<Map<String, dynamic>?> getZoneCrop(int zoneId) async {
    final db = await database;
    final maps = await db.query('zone_crops', where: 'zone_id = ?', whereArgs: [zoneId], limit: 1);
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<int> updateZoneCrop(int id, Map<String, dynamic> values) async {
    final db = await database;
    // values['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Column missing in schema
    return await db.update('zone_crops', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteZoneCrop(int id) async {
    final db = await database;
    return await db.delete('zone_crops', where: 'id = ?', whereArgs: [id]);
  }


  Future<int> deleteSensorCalibration(int id) async {
    final db = await database;
    return await db.delete('sensor_calibrations', where: 'id = ?', whereArgs: [id]);
  }

  // HUB DIAGNOSTICS METHODS

  Future<List<HubDiagnostic>> getHubDiagnostics(int hubId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'hub_diagnostics',
      where: 'hub_id = ?',
      whereArgs: [hubId],
      orderBy: 'timestamp DESC',
      limit: 50,
    );
    return List.generate(maps.length, (i) => HubDiagnostic.fromMap(maps[i]));
  }

  Future<int> insertHubDiagnostic(HubDiagnostic diagnostic) async {
    final db = await database;
    final map = diagnostic.toMap();
    map.remove('id');
    return await db.insert('hub_diagnostics', map);
  }



  // --- Guardian Helper Methods ---

  Future<Map<String, dynamic>?> getActiveCropForZone(int zoneId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plants',
      where: 'zone_id = ? AND harvest_date IS NULL',
      whereArgs: [zoneId],
      orderBy: 'start_date DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<List<Sensor>> getSensorsForZone(int zoneId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sensors',
      where: 'zone_id = ? AND enabled = 1',
      whereArgs: [zoneId],
    );
    return List.generate(maps.length, (i) => Sensor.fromMap(maps[i]));
  }

  Future<int> createSensor(Sensor sensor) async {
    final db = await database;
    final map = sensor.toMap();
    map.remove('id');
    return await db.insert('sensors', map);
  }

  Future<SensorReading?> getLatestSensorReading(int sensorId, String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sensor_readings',
      where: 'sensor_id = ? AND reading_type = ?',
      whereArgs: [sensorId, type],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return SensorReading.fromMap(maps.first);
    }
    return null;
  }




  // GUARDIAN METHODS

  Future<int> insertGuardianReport(GuardianReport report) async {
    final db = await database;
    return await db.insert('guardian_reports', report.toMap());
  }

  // API Key Management
  Future<void> insertGuardianApiKey(Map<String, dynamic> keyData) async {
    final db = await database;
    await db.insert('guardian_api_keys', keyData, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getGuardianApiKeys() async {
    final db = await database;
    return await db.query('guardian_api_keys', orderBy: 'created_at DESC');
  }

  Future<void> deleteGuardianApiKey(String id) async {
    final db = await database;
    await db.delete('guardian_api_keys', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<void> updateGuardianApiKeyLastUsed(String id) async {
    final db = await database;
    await db.update(
      'guardian_api_keys', 
      {'last_used_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  // USER METHODS



  Future<int> createUser(User user) async {
    final db = await database;
    final map = user.toMap();
    map.remove('id'); // Let DB assign ID
    return await db.insert('users', map);
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', orderBy: 'username ASC');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<User?> getUser(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
