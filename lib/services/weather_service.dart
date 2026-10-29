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

  Future<List<CitySuggestion>> searchCities(String query) async {
    final json = await _get('search.json', {'q': query});
    return [
      for (final item in json as List<dynamic>)
        CitySuggestion.fromJson(item as Map<String, dynamic>),
    ];
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
