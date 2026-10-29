import 'package:flutter/material.dart';

class WeatherReport {
  const WeatherReport({
    required this.city,
    required this.country,
    required this.localTime,
    required this.tempC,
    required this.condition,
    required this.conditionCode,
    required this.isDay,
    required this.feelsLikeC,
    required this.humidity,
    required this.windKph,
    required this.uv,
    required this.precipMm,
    required this.pressureMb,
    required this.visibilityKm,
    required this.cloud,
    required this.windDir,
    required this.sunrise,
    required this.sunset,
    required this.hours,
    required this.days,
  });

  final String city;
  final String country;
  final DateTime localTime;
  final double tempC;
  final String condition;
  final int conditionCode;
  final bool isDay;
  final double feelsLikeC;
  final int humidity;
  final double windKph;
  final double uv;
  final double precipMm;
  final double pressureMb;
  final double visibilityKm;
  final int cloud;
  final String windDir;

  /// Local sunrise/sunset for today, as reported by the provider (e.g.
  /// "06:12 AM"); empty when unavailable.
  final String sunrise;
  final String sunset;
  final List<HourForecast> hours;
  final List<DayForecast> days;

  /// A query that reloads this exact place later (see [CitySuggestion.query]).
  String get query => '$city, $country';

  DayForecast? get today => days.isEmpty ? null : days.first;

  factory WeatherReport.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;
    final forecastDays =
        (json['forecast']?['forecastday'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
    final localTime = DateTime.parse(
      (location['localtime'] as String).replaceFirst(' ', 'T'),
    );

    // Next 24 hours starting from the current hour, across day boundaries.
    final allHours = [
      for (final day in forecastDays)
        for (final hour in (day['hour'] as List<dynamic>))
          HourForecast.fromJson(hour as Map<String, dynamic>),
    ];
    final startOfHour = DateTime(
      localTime.year,
      localTime.month,
      localTime.day,
      localTime.hour,
    );
    final upcoming = allHours
        .where((hour) => !hour.time.isBefore(startOfHour))
        .take(24)
        .toList();

    return WeatherReport(
      city: location['name'] as String,
      country: location['country'] as String,
      localTime: localTime,
      tempC: (current['temp_c'] as num).toDouble(),
      condition: current['condition']['text'] as String,
      conditionCode: current['condition']['code'] as int,
      isDay: (current['is_day'] as int) == 1,
      feelsLikeC: (current['feelslike_c'] as num).toDouble(),
      humidity: (current['humidity'] as num).toInt(),
      windKph: (current['wind_kph'] as num).toDouble(),
      uv: (current['uv'] as num).toDouble(),
      precipMm: (current['precip_mm'] as num?)?.toDouble() ?? 0,
      pressureMb: (current['pressure_mb'] as num?)?.toDouble() ?? 0,
      visibilityKm: (current['vis_km'] as num?)?.toDouble() ?? 0,
      cloud: (current['cloud'] as num?)?.toInt() ?? 0,
      windDir: current['wind_dir'] as String? ?? '',
      sunrise: forecastDays.isEmpty
          ? ''
          : forecastDays.first['astro']?['sunrise'] as String? ?? '',
      sunset: forecastDays.isEmpty
          ? ''
          : forecastDays.first['astro']?['sunset'] as String? ?? '',
      hours: upcoming,
      days: [for (final day in forecastDays) DayForecast.fromJson(day)],
    );
  }
}

class HourForecast {
  const HourForecast({
    required this.time,
    required this.tempC,
    required this.conditionCode,
    required this.isDay,
    required this.chanceOfRain,
  });

  final DateTime time;
  final double tempC;
  final int conditionCode;
  final bool isDay;
  final int chanceOfRain;

  factory HourForecast.fromJson(Map<String, dynamic> json) => HourForecast(
    time: DateTime.parse((json['time'] as String).replaceFirst(' ', 'T')),
    tempC: (json['temp_c'] as num).toDouble(),
    conditionCode: json['condition']['code'] as int,
    isDay: (json['is_day'] as int) == 1,
    chanceOfRain: (json['chance_of_rain'] as num?)?.toInt() ?? 0,
  );
}

class DayForecast {
  const DayForecast({
    required this.date,
    required this.minC,
    required this.maxC,
    required this.condition,
    required this.conditionCode,
    required this.chanceOfRain,
  });

  final DateTime date;
  final double minC;
  final double maxC;
  final String condition;
  final int conditionCode;
  final int chanceOfRain;

  factory DayForecast.fromJson(Map<String, dynamic> json) {
    final day = json['day'] as Map<String, dynamic>;
    return DayForecast(
      date: DateTime.parse(json['date'] as String),
      minC: (day['mintemp_c'] as num).toDouble(),
      maxC: (day['maxtemp_c'] as num).toDouble(),
      condition: day['condition']['text'] as String,
      conditionCode: day['condition']['code'] as int,
      chanceOfRain: (day['daily_chance_of_rain'] as num?)?.toInt() ?? 0,
    );
  }
}

class CitySuggestion {
  const CitySuggestion({
    required this.name,
    required this.region,
    required this.country,
  });

  final String name;
  final String region;
  final String country;

  /// A query that loads this exact place ("Matale, Sri Lanka"), so that
  /// same-named towns elsewhere are never picked instead.
  String get query => '$name, $country';

  factory CitySuggestion.fromJson(Map<String, dynamic> json) => CitySuggestion(
    name: json['name'] as String,
    region: json['region'] as String? ?? '',
    country: json['country'] as String,
  );
}

/// Maps a WeatherAPI condition code to a Material icon.
IconData weatherIcon(int code, {bool isDay = true}) {
  if (code == 1000) {
    return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
  }
  if (code == 1003) {
    return isDay ? Icons.wb_cloudy_outlined : Icons.cloud_queue_rounded;
  }
  if (code == 1006 || code == 1009) return Icons.cloud_rounded;
  if (const {1030, 1135, 1147}.contains(code)) return Icons.foggy;
  if (const {1087, 1273, 1276, 1279, 1282}.contains(code)) {
    return Icons.thunderstorm_rounded;
  }
  if (const {
    1066, 1114, 1117, 1210, 1213, 1216, 1219, 1222, 1225, //
    1255, 1258, 1261, 1264,
  }.contains(code)) {
    return Icons.ac_unit_rounded;
  }
  if (const {1063, 1150, 1153, 1168, 1171, 1180, 1183}.contains(code)) {
    return Icons.grain_rounded;
  }
  return Icons.water_drop_rounded;
}
