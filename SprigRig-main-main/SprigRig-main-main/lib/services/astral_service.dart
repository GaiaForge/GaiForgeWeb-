import 'dart:async';
import 'dart:io';
import '../models/sensor.dart';
import '../models/location_settings.dart';
import '../services/database_helper.dart';

/// AstralService calculates sunrise and sunset times based on location.
class AstralService {
  static AstralService? _instance;
  static AstralService get instance => _instance ??= AstralService._internal();

  AstralService._internal();

  // Services
  final DatabaseHelper _db = DatabaseHelper();

  // Python script path
  final String _astralScript =
      '/opt/sprigrig/python/utils/astral_calculator.py';

  // Cache for astral times
  final Map<String, DateTime> _sunriseCache = {};
  final Map<String, DateTime> _sunsetCache = {};

  // Current location settings
  LocationSettings? _locationSettings;

  /// Initialize the astral service
  Future<void> initialize() async {
    // Load location settings
    await _loadLocationSettings();

    // Verify the astral script exists
    final scriptFile = File(_astralScript);
    if (!await scriptFile.exists()) {
      throw Exception('Astral calculator script not found: $_astralScript');
    }
  }

  /// Load location settings from the database
  Future<void> _loadLocationSettings() async {
    _locationSettings = await _db.getLocationSettings();

    // If no location settings are found, use default (equator)
    if (_locationSettings == null) {
      throw Exception(
        'No location settings found. Please configure location in settings.',
      );
    }
  }

  /// Force reload of location settings
  Future<void> reloadLocationSettings() async {
    _locationSettings = null;
    await _loadLocationSettings();

    // Clear caches
    _sunriseCache.clear();
    _sunsetCache.clear();
  }

  /// Get sunrise for a specific date
  Future<DateTime> getSunriseForDate(DateTime date) async {
    // Ensure location settings are loaded
    if (_locationSettings == null) {
      await _loadLocationSettings();
    }

    // Check cache first
    final cacheKey = '${date.year}-${date.month}-${date.day}';
    if (_sunriseCache.containsKey(cacheKey)) {
      return _sunriseCache[cacheKey]!;
    }

    try {
      // Format the date as YYYY-MM-DD
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Run the astral calculator script
      final result = await Process.run('python3', [
        _astralScript,
        '--date',
        dateStr,
        '--event',
        'sunrise',
        '--lat',
        _locationSettings!.latitude.toString(),
        '--lng',
        _locationSettings!.longitude.toString(),
        '--tz',
        _locationSettings!.timezone,
      ]);

      // Check result
      if (result.exitCode != 0) {
        throw Exception('Failed to calculate sunrise: ${result.stderr}');
      }

      // Parse the result (expected format: YYYY-MM-DD HH:MM:SS)
      final sunriseStr = result.stdout.trim();
      final sunriseParts = sunriseStr.split(' ');
      if (sunriseParts.length != 2) {
        throw Exception('Invalid sunrise format: $sunriseStr');
      }

      final dateParts = sunriseParts[0].split('-');
      final timeParts = sunriseParts[1].split(':');

      if (dateParts.length != 3 || timeParts.length != 3) {
        throw Exception('Invalid sunrise format: $sunriseStr');
      }

      final sunrise = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );

      // Cache the result
      _sunriseCache[cacheKey] = sunrise;

      return sunrise;
    } catch (e) {
      throw Exception('Error calculating sunrise: $e');
    }
  }

  /// Get sunset for a specific date
  Future<DateTime> getSunsetForDate(DateTime date) async {
    // Ensure location settings are loaded
    if (_locationSettings == null) {
      await _loadLocationSettings();
    }

    // Check cache first
    final cacheKey = '${date.year}-${date.month}-${date.day}';
    if (_sunsetCache.containsKey(cacheKey)) {
      return _sunsetCache[cacheKey]!;
    }

    try {
      // Format the date as YYYY-MM-DD
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Run the astral calculator script
      final result = await Process.run('python3', [
        _astralScript,
        '--date',
        dateStr,
        '--event',
        'sunset',
        '--lat',
        _locationSettings!.latitude.toString(),
        '--lng',
        _locationSettings!.longitude.toString(),
        '--tz',
        _locationSettings!.timezone,
      ]);

      // Check result
      if (result.exitCode != 0) {
        throw Exception('Failed to calculate sunset: ${result.stderr}');
      }

      // Parse the result (expected format: YYYY-MM-DD HH:MM:SS)
      final sunsetStr = result.stdout.trim();
      final sunsetParts = sunsetStr.split(' ');
      if (sunsetParts.length != 2) {
        throw Exception('Invalid sunset format: $sunsetStr');
      }

      final dateParts = sunsetParts[0].split('-');
      final timeParts = sunsetParts[1].split(':');

      if (dateParts.length != 3 || timeParts.length != 3) {
        throw Exception('Invalid sunset format: $sunsetStr');
      }

      final sunset = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );

      // Cache the result
      _sunsetCache[cacheKey] = sunset;

      return sunset;
    } catch (e) {
      throw Exception('Error calculating sunset: $e');
    }
  }

  /// Get the current location settings
  LocationSettings? get locationSettings => _locationSettings;

  /// Get day length in hours for a specific date
  Future<double> getDayLengthForDate(DateTime date) async {
    try {
      final sunrise = await getSunriseForDate(date);
      final sunset = await getSunsetForDate(date);

      final dayLength = sunset.difference(sunrise).inMinutes / 60.0;
      return dayLength;
    } catch (e) {
      throw Exception('Error calculating day length: $e');
    }
  }

  /// Get the current photoperiod (light/dark hours)
  Future<Map<String, double>> getCurrentPhotoperiod() async {
    try {
      final today = DateTime.now();
      final dayLength = await getDayLengthForDate(today);

      return {'dayHours': dayLength, 'nightHours': 24.0 - dayLength};
    } catch (e) {
      throw Exception('Error calculating photoperiod: $e');
    }
  }

  /// Check if it's currently daytime
  Future<bool> isDaytime() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final sunrise = await getSunriseForDate(today);
      final sunset = await getSunsetForDate(today);

      return now.isAfter(sunrise) && now.isBefore(sunset);
    } catch (e) {
      throw Exception('Error checking daytime: $e');
    }
  }

  /// Get the next astral event (sunrise or sunset)
  Future<Map<String, dynamic>> getNextAstralEvent() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final sunrise = await getSunriseForDate(today);
      final sunset = await getSunsetForDate(today);

      // If both events are in the past, get tomorrow's sunrise
      if (now.isAfter(sunrise) && now.isAfter(sunset)) {
        final tomorrow = today.add(const Duration(days: 1));
        final tomorrowSunrise = await getSunriseForDate(tomorrow);

        return {
          'event': 'sunrise',
          'time': tomorrowSunrise,
          'remainingMinutes': tomorrowSunrise.difference(now).inMinutes,
        };
      }

      // If sunrise is in the future but sunset is not
      if (now.isBefore(sunrise)) {
        return {
          'event': 'sunrise',
          'time': sunrise,
          'remainingMinutes': sunrise.difference(now).inMinutes,
        };
      }

      // If sunset is in the future
      if (now.isBefore(sunset)) {
        return {
          'event': 'sunset',
          'time': sunset,
          'remainingMinutes': sunset.difference(now).inMinutes,
        };
      }

      // Fallback (should not reach here)
      final tomorrow = today.add(const Duration(days: 1));
      final tomorrowSunrise = await getSunriseForDate(tomorrow);

      return {
        'event': 'sunrise',
        'time': tomorrowSunrise,
        'remainingMinutes': tomorrowSunrise.difference(now).inMinutes,
      };
    } catch (e) {
      throw Exception('Error determining next astral event: $e');
    }
  }
}

/// Python implementation of the astral calculator script
/// Place this in /opt/sprigrig/python/utils/astral_calculator.py
///
/// ```python
/// #!/usr/bin/env python3
/// import argparse
/// import datetime
/// from astral import LocationInfo
/// from astral.sun import sun
/// from zoneinfo import ZoneInfo
///
/// def main():
///     parser = argparse.ArgumentParser(description='Calculate sunrise and sunset times.')
///     parser.add_argument('--date', required=True, help='Date in YYYY-MM-DD format')
///     parser.add_argument('--event', required=True, choices=['sunrise', 'sunset'], 
///                         help='Astral event to calculate')
///     parser.add_argument('--lat', required=True, type=float, help='Latitude')
///     parser.add_argument('--lng', required=True, type=float, help='Longitude')
///     parser.add_argument('--tz', required=True, help='Timezone name (e.g., America/New_York)')
///     
///     args = parser.parse_args()
///     
///     # Parse the date
///     year, month, day = map(int, args.date.split('-'))
///     date = datetime.date(year, month, day)
///     
///     # Create a location
///     location = LocationInfo(
///         name='Custom',
///         region='Region',
///         timezone=args.tz,
///         latitude=args.lat,
///         longitude=args.lng
///     )
///     
///     # Calculate sun times
///     timezone = ZoneInfo(args.tz)
///     s = sun(location.observer, date=date, tzinfo=timezone)
///     
///     # Get the requested event
///     if args.event == 'sunrise':
///         time = s['sunrise']
///     else:
///         time = s['sunset']
///     
///     # Format the result as YYYY-MM-DD HH:MM:SS
///     print(time.strftime('%Y-%m-%d %H:%M:%S'))
///
/// if __name__ == '__main__':
///     main()
/// ```
