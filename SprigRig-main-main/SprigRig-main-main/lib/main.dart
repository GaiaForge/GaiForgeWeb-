// lib/main.dart

// lib/main.dart
import 'dart:io'; 
import 'package:flutter/foundation.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // **FIX: Only run desktop code when NOT on web**
  if (!kIsWeb) {  // ← Add this check
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  runApp(const SprigRigApp());
}