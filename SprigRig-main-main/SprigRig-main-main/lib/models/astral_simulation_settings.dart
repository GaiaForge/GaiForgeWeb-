class AstralSimulationSettings {
  final int? id;
  final int zoneId;
  final bool enabled;
  final double latitude;
  final double longitude;
  final String? locationName;
  final String? timezone;
  final String simulationMode;
  final bool includeSpring;
  final bool includeSummer;
  final bool includeFall;
  final bool includeWinter;
  final int? rangeStartMonth;
  final int? rangeStartDay;
  final int? rangeEndMonth;
  final int? rangeEndDay;
  final int? fixedMonth;
  final int? fixedDay;
  final double timeCompression;
  final int simulationStartDate;
  final int sunriseOffsetMinutes;
  final int sunsetOffsetMinutes;
  final bool useIntensityCurve;
  final int dawnDurationMinutes;
  final int duskDurationMinutes;

  AstralSimulationSettings({
    this.id,
    required this.zoneId,
    this.enabled = false,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.timezone,
    this.simulationMode = 'full_year',
    this.includeSpring = true,
    this.includeSummer = true,
    this.includeFall = true,
    this.includeWinter = true,
    this.rangeStartMonth,
    this.rangeStartDay,
    this.rangeEndMonth,
    this.rangeEndDay,
    this.fixedMonth,
    this.fixedDay,
    this.timeCompression = 1.0,
    required this.simulationStartDate,
    this.sunriseOffsetMinutes = 0,
    this.sunsetOffsetMinutes = 0,
    this.useIntensityCurve = false,
    this.dawnDurationMinutes = 30,
    this.duskDurationMinutes = 30,
  });

  factory AstralSimulationSettings.fromMap(Map<String, dynamic> map) {
    return AstralSimulationSettings(
      id: map['id'],
      zoneId: map['zone_id'],
      enabled: map['enabled'] == 1,
      latitude: map['latitude'],
      longitude: map['longitude'],
      locationName: map['location_name'],
      timezone: map['timezone'],
      simulationMode: map['simulation_mode'] ?? 'full_year',
      includeSpring: map['include_spring'] == 1,
      includeSummer: map['include_summer'] == 1,
      includeFall: map['include_fall'] == 1,
      includeWinter: map['include_winter'] == 1,
      rangeStartMonth: map['range_start_month'],
      rangeStartDay: map['range_start_day'],
      rangeEndMonth: map['range_end_month'],
      rangeEndDay: map['range_end_day'],
      fixedMonth: map['fixed_month'],
      fixedDay: map['fixed_day'],
      timeCompression: (map['time_compression'] as num?)?.toDouble() ?? 1.0,
      simulationStartDate: map['simulation_start_date'] ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      sunriseOffsetMinutes: map['sunrise_offset_minutes'] ?? 0,
      sunsetOffsetMinutes: map['sunset_offset_minutes'] ?? 0,
      useIntensityCurve: map['use_intensity_curve'] == 1,
      dawnDurationMinutes: map['dawn_duration_minutes'] ?? 30,
      duskDurationMinutes: map['dusk_duration_minutes'] ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'zone_id': zoneId,
      'enabled': enabled ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'timezone': timezone,
      'simulation_mode': simulationMode,
      'include_spring': includeSpring ? 1 : 0,
      'include_summer': includeSummer ? 1 : 0,
      'include_fall': includeFall ? 1 : 0,
      'include_winter': includeWinter ? 1 : 0,
      'range_start_month': rangeStartMonth,
      'range_start_day': rangeStartDay,
      'range_end_month': rangeEndMonth,
      'range_end_day': rangeEndDay,
      'fixed_month': fixedMonth,
      'fixed_day': fixedDay,
      'time_compression': timeCompression,
      'simulation_start_date': simulationStartDate,
      'sunrise_offset_minutes': sunriseOffsetMinutes,
      'sunset_offset_minutes': sunsetOffsetMinutes,
      'use_intensity_curve': useIntensityCurve ? 1 : 0,
      'dawn_duration_minutes': dawnDurationMinutes,
      'dusk_duration_minutes': duskDurationMinutes,
    };
  }
}
