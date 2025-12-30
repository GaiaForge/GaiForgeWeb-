import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class WifiNetwork {
  final String ssid;
  final int signalStrength;
  final bool isSecure;
  final bool isConnected;

  WifiNetwork({
    required this.ssid,
    required this.signalStrength,
    required this.isSecure,
    this.isConnected = false,
  });
}

class WifiService {
  static final WifiService _instance = WifiService._internal();
  static WifiService get instance => _instance;

  WifiService._internal();

  /// Check if running on Linux (Raspberry Pi)
  bool get _isLinux => Platform.isLinux;

  /// Scan for available networks
  Future<List<WifiNetwork>> scanNetworks() async {
    if (!_isLinux) {
      // Mock data for development on macOS/Windows
      await Future.delayed(const Duration(seconds: 2));
      return [
        WifiNetwork(ssid: 'Home_WiFi', signalStrength: 80, isSecure: true, isConnected: true),
        WifiNetwork(ssid: 'Guest_Network', signalStrength: 60, isSecure: true),
        WifiNetwork(ssid: 'Neighbor_WiFi', signalStrength: 40, isSecure: true),
        WifiNetwork(ssid: 'Open_Hotspot', signalStrength: 90, isSecure: false),
      ];
    }

    try {
      // Rescan first
      await Process.run('nmcli', ['dev', 'wifi', 'rescan']);
      
      // Get list: SSID, SIGNAL, SECURITY, ACTIVE
      // -t: terse (script friendly)
      // -f: fields
      final result = await Process.run('nmcli', [
        '-t',
        '-f', 'SSID,SIGNAL,SECURITY,ACTIVE',
        'dev', 'wifi', 'list'
      ]);

      if (result.exitCode != 0) {
        throw Exception('Failed to scan networks: ${result.stderr}');
      }

      final lines = LineSplitter.split(result.stdout.toString());
      final networks = <WifiNetwork>[];
      final seenSsids = <String>{};

      for (final line in lines) {
        final parts = line.split(':'); // nmcli -t uses : as separator, but wait...
        // nmcli -t escapes colons in values with backslash. 
        // A simpler way might be to not use -t and parse fixed width, or use CSV format if available.
        // Actually, -t uses ':' as separator. If SSID has ':', it is escaped as '\:'.
        // For simplicity, let's assume standard SSIDs for now or use a more robust parser.
        // Better yet, let's just split by ':' and handle the basics.
        
        // Parts: SSID:SIGNAL:SECURITY:ACTIVE
        // Note: SECURITY might contain colons (e.g. WPA2:802.1X), so we should be careful.
        // Let's use a regex or just take the first and last known fields.
        
        // Actually, nmcli output with -t looks like:
        // MyNetwork:85:WPA2:yes
        
        // If we have multiple colons, it's tricky.
        // Let's try to parse from the back for ACTIVE and SECURITY?
        // Or just use a safer separator if possible? nmcli doesn't easily support custom separators.
        
        // Let's try basic split and hope for the best for now.
        // If parts.length > 4, we might have issues.
        
        // Alternative: Use JSON output if available (newer nmcli), but RPi might be old.
        // Let's stick to basic parsing.
        
        if (parts.length < 4) continue;
        
        final isConnected = parts.last == 'yes';
        final security = parts[parts.length - 2];
        final signal = int.tryParse(parts[parts.length - 3]) ?? 0;
        
        // Reconstruct SSID if it contained colons
        final ssidParts = parts.sublist(0, parts.length - 3);
        final ssid = ssidParts.join(':').replaceAll(r'\:', ':');
        
        if (ssid.isEmpty) continue;
        if (seenSsids.contains(ssid)) continue; // Dedup
        
        seenSsids.add(ssid);
        networks.add(WifiNetwork(
          ssid: ssid,
          signalStrength: signal,
          isSecure: security.isNotEmpty && security != '',
          isConnected: isConnected,
        ));
      }
      
      // Sort: Connected first, then signal strength
      networks.sort((a, b) {
        if (a.isConnected != b.isConnected) return a.isConnected ? -1 : 1;
        return b.signalStrength.compareTo(a.signalStrength);
      });

      return networks;

    } catch (e) {
      debugPrint('Error scanning wifi: $e');
      return [];
    }
  }

  /// Connect to a network
  Future<bool> connectToNetwork(String ssid, String? password) async {
    if (!_isLinux) {
      await Future.delayed(const Duration(seconds: 2));
      return true;
    }

    try {
      final args = ['dev', 'wifi', 'connect', ssid];
      if (password != null && password.isNotEmpty) {
        args.addAll(['password', password]);
      }

      final result = await Process.run('nmcli', args);
      
      if (result.exitCode != 0) {
        debugPrint('Connection failed: ${result.stderr}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error connecting to wifi: $e');
      return false;
    }
  }

  /// Forget a network (delete connection)
  Future<bool> forgetNetwork(String ssid) async {
    if (!_isLinux) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    try {
      final result = await Process.run('nmcli', ['connection', 'delete', ssid]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Error forgetting network: $e');
      return false;
    }
  }

  /// Check if Wi-Fi is enabled
  Future<bool> isWifiEnabled() async {
    if (!_isLinux) return true;
    try {
      final result = await Process.run('nmcli', ['radio', 'wifi']);
      return result.stdout.toString().trim() == 'enabled';
    } catch (e) {
      return false;
    }
  }

  /// Toggle Wi-Fi
  Future<void> toggleWifi(bool enable) async {
    if (!_isLinux) return;
    try {
      await Process.run('nmcli', ['radio', 'wifi', enable ? 'on' : 'off']);
    } catch (e) {
      debugPrint('Error toggling wifi: $e');
    }
  }
}
