import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class SkyCastApp extends StatefulWidget {
  const SkyCastApp({super.key});

  @override
  State<SkyCastApp> createState() => _SkyCastAppState();
}

class _SkyCastAppState extends State<SkyCastApp> {
  final _themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101B36);
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, themeMode, _) {
        return AppThemeScope(
          themeMode: _themeMode,
          child: MaterialApp(
            title: 'SkyCast',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: _buildTheme(Brightness.light, navy),
            darkTheme: _buildTheme(Brightness.dark, navy),
            home: const WeatherHomePage(),
          ),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness, Color navy) {
    final dark = brightness == Brightness.dark;
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF63B8FF),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: dark
          ? const Color(0xFF0B1429)
          : const Color(0xFFF4F7FC),
      fontFamily: 'Avenir',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: dark ? Colors.white : navy,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF111E38) : Colors.white,
        indicatorColor: dark
            ? const Color(0xFF234A70)
            : const Color(0xFFE4F2FF),
      ),
    );
  }
}

class AppThemeScope extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const AppThemeScope({
    required ValueNotifier<ThemeMode> themeMode,
    required super.child,
    super.key,
  }) : super(notifier: themeMode);

  static ValueNotifier<ThemeMode>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppThemeScope>()?.notifier;
}
