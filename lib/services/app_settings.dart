import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences shared across screens and persisted on the device.
class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final instance = AppSettings._();

  bool _fahrenheit = false;
  bool _mph = false;
  bool _inches = false;
  bool _autoLocation = true;
  ThemeMode _themeMode = ThemeMode.dark;

  bool get fahrenheit => _fahrenheit;
  bool get mph => _mph;
  bool get inches => _inches;
  bool get autoLocation => _autoLocation;
  ThemeMode get themeMode => _themeMode;

  String get temperatureUnit => _fahrenheit ? '°F' : '°C';
  String get windUnit => _mph ? 'mph' : 'km/h';
  String get precipitationUnit => _inches ? 'in' : 'mm';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _fahrenheit = prefs.getBool('fahrenheit') ?? false;
    _mph = prefs.getBool('mph') ?? false;
    _inches = prefs.getBool('inches') ?? false;
    _autoLocation = prefs.getBool('auto_location') ?? true;
    _themeMode = ThemeMode.values.asNameMap()[prefs.getString('theme_mode')] ??
        ThemeMode.dark;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _setString('theme_mode', mode.name, () => _themeMode = mode);

  Future<void> setFahrenheit(bool value) => _set('fahrenheit', value, () {
    _fahrenheit = value;
  });

  Future<void> setMph(bool value) => _set('mph', value, () => _mph = value);

  Future<void> setInches(bool value) =>
      _set('inches', value, () => _inches = value);

  Future<void> setAutoLocation(bool value) =>
      _set('auto_location', value, () => _autoLocation = value);

  Future<void> _setString(String key, String value, VoidCallback apply) async {
    apply();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _set(String key, bool value, VoidCallback apply) async {
    apply();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}

/// Rebuilds a [State] whenever [AppSettings] changes (e.g. unit toggles).
mixin SettingsListener<T extends StatefulWidget> on State<T> {
  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
