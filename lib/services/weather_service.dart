import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/weather.dart';

enum WeatherFailure { network, cityNotFound, server }

class WeatherException implements Exception {
  const WeatherException(this.failure, [this.message]);

  final WeatherFailure failure;
  final String? message;

  @override
  String toString() => 'WeatherException($failure, $message)';
}

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 12);

  /// Current conditions plus hourly and daily forecast for [query]
  /// (a city name or "lat,lon").
  Future<WeatherReport> fetchWeather(String query) async {
    final json = await _get('forecast.json', {
      'q': query,
      'days': '5',
      'aqi': 'no',
      'alerts': 'no',
    });
    return WeatherReport.fromJson(json as Map<String, dynamic>);
  }

  /// City suggestions for [query]. WeatherAPI's own search misses many towns
  /// (e.g. Matale, Sri Lanka), so Open-Meteo's geocoder is merged in.
  Future<List<CitySuggestion>> searchCities(String query) async {
    final results = await Future.wait([
      _get('search.json', {'q': query}).then<List<CitySuggestion>>(
        (json) => [
          for (final item in json as List<dynamic>)
            CitySuggestion.fromJson(item as Map<String, dynamic>),
        ],
      ),
      _geocode(query),
    ]);
    final seen = <String>{};
    final merged = [
      for (final city in [...results[0], ...results[1]])
        if (seen.add('${city.name}|${city.country}'.toLowerCase())) city,
    ];
    // Exact name matches first; the sort is stable so source order is kept.
    final lower = query.trim().toLowerCase();
    merged.sort((a, b) {
      final aExact = a.name.toLowerCase() == lower ? 0 : 1;
      final bExact = b.name.toLowerCase() == lower ? 0 : 1;
      return aExact.compareTo(bExact);
    });
    return merged.take(8).toList();
  }

  /// Best-effort lookup; any failure just means no extra suggestions.
  Future<List<CitySuggestion>> _geocode(String query) async {
    try {
      final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': query,
        'count': '6',
        'language': 'en',
      });
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return const [];
      final results =
          (jsonDecode(response.body) as Map<String, dynamic>)['results']
              as List<dynamic>?;
      return [
        for (final item in results ?? const [])
          CitySuggestion(
            name: (item as Map<String, dynamic>)['name'] as String,
            region: item['admin1'] as String? ?? '',
            country: item['country'] as String? ?? '',
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<dynamic> _get(String path, Map<String, String> params) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/$path',
    ).replace(queryParameters: {'key': ApiConfig.apiKey, ...params});

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on SocketException {
      throw const WeatherException(WeatherFailure.network);
    } on TimeoutException {
      throw const WeatherException(WeatherFailure.network);
    } on http.ClientException {
      throw const WeatherException(WeatherFailure.network);
    }

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body);
      } on FormatException {
        throw const WeatherException(
          WeatherFailure.server,
          'Invalid response from weather service',
        );
      }
    }

    String? message;
    int? code;
    try {
      final error = (jsonDecode(response.body) as Map<String, dynamic>)['error']
          as Map<String, dynamic>;
      message = error['message'] as String?;
      code = error['code'] as int?;
    } catch (_) {}

    // 1006 = no matching location found.
    if (code == 1006) {
      throw WeatherException(WeatherFailure.cityNotFound, message);
    }
    throw WeatherException(WeatherFailure.server, message);
  }
}
