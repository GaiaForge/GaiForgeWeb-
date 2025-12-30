import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/astral_simulation_settings.dart';

class AstralSimulationService {
  static AstralSimulationService? _instance;
  static AstralSimulationService get instance => _instance ??= AstralSimulationService._();
  AstralSimulationService._();

  SunTimes calculateSunTimes(double latitude, double longitude, DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final declination = -23.45 * math.cos((360 / 365) * (dayOfYear + 10) * (math.pi / 180));
    
    final latRad = latitude * (math.pi / 180);
    final decRad = declination * (math.pi / 180);
    final cosHourAngle = -math.tan(latRad) * math.tan(decRad);
    
    double hourAngle;
    if (cosHourAngle < -1) {
      hourAngle = 180;
    } else if (cosHourAngle > 1) {
      hourAngle = 0;
    } else {
      hourAngle = math.acos(cosHourAngle) * (180 / math.pi);
    }
    
    final solarNoon = 12.0 - (longitude / 15.0);
    final sunriseHour = solarNoon - (hourAngle / 15.0);
    final sunsetHour = solarNoon + (hourAngle / 15.0);
    
    return SunTimes(
      sunrise: _hourToTimeOfDay(sunriseHour),
      sunset: _hourToTimeOfDay(sunsetHour),
      dayLengthMinutes: ((sunsetHour - sunriseHour) * 60).round(),
    );
  }

  DateTime getCurrentSimulatedDate(AstralSimulationSettings settings) {
    if (!settings.enabled) return DateTime.now();
    
    final realElapsed = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(settings.simulationStartDate * 1000)
    );
    
    final simulatedElapsed = Duration(
      milliseconds: (realElapsed.inMilliseconds * settings.timeCompression).round()
    );
    
    var simulatedDate = _getSimulationStartDate(settings).add(simulatedElapsed);
    simulatedDate = _applySimulationBounds(simulatedDate, settings);
    
    return simulatedDate;
  }

  AstralLightingSchedule getTodaySchedule(AstralSimulationSettings settings) {
    final simDate = getCurrentSimulatedDate(settings);
    final sunTimes = calculateSunTimes(settings.latitude, settings.longitude, simDate);
    
    final lightsOn = _subtractMinutes(sunTimes.sunrise, settings.sunriseOffsetMinutes);
    final lightsOff = _addMinutes(sunTimes.sunset, settings.sunsetOffsetMinutes);
    
    return AstralLightingSchedule(
      lightsOn: lightsOn,
      lightsOff: lightsOff,
      simulatedDate: simDate,
      sunTimes: sunTimes,
    );
  }
  
  TimeOfDay _hourToTimeOfDay(double hour) {
    // Handle wrapping around 24 hours
    while (hour < 0) hour += 24;
    while (hour >= 24) hour -= 24;
    
    final h = hour.floor();
    final m = ((hour - h) * 60).round();
    return TimeOfDay(hour: h, minute: m);
  }
  
  DateTime _getSimulationStartDate(AstralSimulationSettings settings) {
    final now = DateTime.now();
    switch (settings.simulationMode) {
      case 'full_year':
        return DateTime(now.year, 1, 1);
      case 'seasons':
        return _getFirstSelectedSeasonStart(settings, now.year);
      case 'custom_range':
        return DateTime(now.year, settings.rangeStartMonth ?? 1, settings.rangeStartDay ?? 1);
      case 'fixed_day':
        return DateTime(now.year, settings.fixedMonth ?? 1, settings.fixedDay ?? 1);
      default:
        return DateTime(now.year, 1, 1);
    }
  }
  
  DateTime _getFirstSelectedSeasonStart(AstralSimulationSettings settings, int year) {
    if (settings.includeSpring) return DateTime(year, 3, 1);
    if (settings.includeSummer) return DateTime(year, 6, 1);
    if (settings.includeFall) return DateTime(year, 9, 1);
    if (settings.includeWinter) return DateTime(year, 12, 1);
    return DateTime(year, 1, 1);
  }
  
  DateTime _applySimulationBounds(DateTime date, AstralSimulationSettings settings) {
    final year = date.year;
    
    switch (settings.simulationMode) {
      case 'full_year':
        // Simple wrap around year
        final startOfYear = DateTime(year, 1, 1);
        final dayOfYear = date.difference(startOfYear).inDays % 365;
        return startOfYear.add(Duration(days: dayOfYear));
        
      case 'fixed_day':
        return DateTime(year, settings.fixedMonth ?? 1, settings.fixedDay ?? 1);
        
      case 'seasons':
        // This is complex - need to jump between selected seasons
        // For MVP, just wrap around year and let the user ensure contiguous seasons or accept jumps
        // A better implementation would calculate total days in selected seasons and modulo that
        final startOfYear = DateTime(year, 1, 1);
        final dayOfYear = date.difference(startOfYear).inDays % 365;
        return startOfYear.add(Duration(days: dayOfYear));
        
      case 'custom_range':
        final start = DateTime(year, settings.rangeStartMonth ?? 1, settings.rangeStartDay ?? 1);
        final end = DateTime(year, settings.rangeEndMonth ?? 12, settings.rangeEndDay ?? 31);
        
        if (end.isBefore(start)) {
          // Range spans year boundary (e.g. Dec to Jan)
          // Not supported in this simple version yet
          return date; 
        }
        
        final rangeDuration = end.difference(start).inDays + 1;
        if (rangeDuration <= 0) return start;
        
        final daysSinceStart = date.difference(start).inDays;
        final wrappedDays = daysSinceStart % rangeDuration;
        
        return start.add(Duration(days: wrappedDays));
        
      default:
        return date;
    }
  }
  
  TimeOfDay _subtractMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute - minutes;
    final adjusted = totalMinutes < 0 ? totalMinutes + 1440 : totalMinutes;
    return TimeOfDay(hour: (adjusted ~/ 60) % 24, minute: adjusted % 60);
  }
  
  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(hour: (totalMinutes ~/ 60) % 24, minute: totalMinutes % 60);
  }
}

class SunTimes {
  final TimeOfDay sunrise;
  final TimeOfDay sunset;
  final int dayLengthMinutes;
  
  SunTimes({required this.sunrise, required this.sunset, required this.dayLengthMinutes});
  
  String get dayLengthFormatted {
    final h = dayLengthMinutes ~/ 60;
    final m = dayLengthMinutes % 60;
    return '${h}h ${m}m';
  }
}

class AstralLightingSchedule {
  final TimeOfDay lightsOn;
  final TimeOfDay lightsOff;
  final DateTime simulatedDate;
  final SunTimes sunTimes;
  
  AstralLightingSchedule({
    required this.lightsOn,
    required this.lightsOff,
    required this.simulatedDate,
    required this.sunTimes,
  });
}
