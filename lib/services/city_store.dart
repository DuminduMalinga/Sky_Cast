import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's chosen city, saved cities and recent searches.
class CityStore {
  static const defaultCity = 'Colombo';
  static const _currentKey = 'current_city';
  static const _savedKey = 'saved_cities';
  static const _recentKey = 'recent_searches';
  static const _maxRecent = 6;

  Future<String> loadCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentKey) ?? defaultCity;
  }

  Future<void> saveCurrent(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentKey, city);
  }

  /// Saved cities, or null if the user has never saved any.
  Future<List<String>?> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedKey);
  }

  Future<void> saveSaved(List<String> cities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedKey, cities);
  }

  Future<List<String>> loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentKey) ?? const [];
  }

  Future<void> addRecent(String city) async {
    final recent = [
      city,
      ...(await loadRecent()).where(
        (item) => item.toLowerCase() != city.toLowerCase(),
      ),
    ].take(_maxRecent).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, recent);
  }

  Future<void> removeRecent(String city) async {
    final recent = (await loadRecent()).where((item) => item != city).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, recent);
  }
}
