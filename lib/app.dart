import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_settings.dart';
import 'services/location_service.dart';
import 'services/weather_service.dart';

class SkyCastApp extends StatefulWidget {
  const SkyCastApp({
    this.service,
    this.location,
    this.showOnboarding = false,
    super.key,
  });

  final WeatherService? service;
  final LocationService? location;
  final bool showOnboarding;

  @override
  State<SkyCastApp> createState() => _SkyCastAppState();
}

class _SkyCastAppState extends State<SkyCastApp> {
  final _themeMode = ValueNotifier<ThemeMode>(AppSettings.instance.themeMode);

  @override
  void initState() {
    super.initState();
    _themeMode.addListener(_persistTheme);
  }

  void _persistTheme() => AppSettings.instance.setThemeMode(_themeMode.value);

  @override
  void dispose() {
    _themeMode.removeListener(_persistTheme);
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, themeMode, _) {
        return AppThemeScope(
          themeMode: _themeMode,
          child: MaterialApp(
            title: 'SkyCast',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            builder: (context, child) {
              // Light icons on the dark theme, dark icons on the light one.
              final dark = Theme.of(context).brightness == Brightness.dark;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: _overlayStyle(dark),
                child: child!,
              );
            },
            home: widget.showOnboarding
                ? OnboardingScreen(
                    service: widget.service,
                    location: widget.location,
                  )
                : WeatherHomePage(
                    service: widget.service,
                    location: widget.location,
                  ),
          ),
        );
      },
    );
  }

  SystemUiOverlayStyle _overlayStyle(bool dark) => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: dark ? const Color(0xFF151F33) : Colors.white,
    systemNavigationBarIconBrightness: dark
        ? Brightness.light
        : Brightness.dark,
  );

  ThemeData _buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    const accent = Color(0xFF63B8FF);
    const background = Color(0xFF0B1220);
    const card = Color(0xFF151F33);
    const primaryText = Color(0xFFF5F8FF);
    const secondaryText = Color(0xFFA8B4C8);
    const divider = Color(0xFF27334A);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
        surface: dark ? card : Colors.white,
        onSurface: dark ? primaryText : const Color(0xFF101B36),
        outline: dark ? divider : const Color(0xFFE1EAF4),
      ),
      scaffoldBackgroundColor: dark ? background : const Color(0xFFF4F7FC),
      cardColor: dark ? card : Colors.white,
      dividerColor: dark ? divider : const Color(0xFFE1EAF4),
      hintColor: dark ? secondaryText : const Color(0xFF8290A8),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: dark ? primaryText : const Color(0xFF101B36),
        displayColor: dark ? primaryText : const Color(0xFF101B36),
      ),
      fontFamily: 'Avenir',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: dark ? primaryText : const Color(0xFF101B36),
        elevation: 0,
        systemOverlayStyle: _overlayStyle(dark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? card : Colors.white,
        hintStyle: TextStyle(
          color: dark ? secondaryText : const Color(0xFF8290A8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: dark ? divider : const Color(0xFFE2EAF4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? card : Colors.white,
        indicatorColor: dark
            ? const Color(0xFF234A70)
            : const Color(0xFFE4F2FF),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: dark ? secondaryText : const Color(0xFF101B36),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
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
      context.getInheritedWidgetOfExactType<AppThemeScope>()?.notifier;
}
