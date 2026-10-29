import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skycast/main.dart';
import 'package:skycast/screens/saved_cities_screen.dart';
import 'package:skycast/screens/details_screen.dart';
import 'package:skycast/screens/forecast_screen.dart';
import 'package:skycast/services/app_settings.dart';
import 'package:skycast/services/city_store.dart';
import 'package:skycast/screens/city_search_screen.dart';
import 'package:skycast/screens/settings_screen.dart';
import 'package:skycast/screens/weather_states_screen.dart';
import 'package:skycast/services/location_service.dart';
import 'package:skycast/services/weather_service.dart';

Map<String, dynamic> _hour(String time, double temp) => {
  'time': time,
  'temp_c': temp,
  'is_day': 1,
  'condition': {'text': 'Sunny', 'code': 1000},
};

Map<String, dynamic> _day(String date) => {
  'date': date,
  'day': {
    'maxtemp_c': 32.0,
    'mintemp_c': 25.0,
    'condition': {'text': 'Sunny', 'code': 1000},
  },
  'astro': {'sunrise': '06:12 AM', 'sunset': '06:20 PM'},
  'hour': [
    for (var h = 0; h < 24; h++)
      _hour('$date ${h.toString().padLeft(2, '0')}:00', 29.0),
  ],
};

WeatherService _fakeService({int status = 200, Object? body}) {
  final weather = {
    'location': {
      'name': 'Colombo',
      'country': 'Sri Lanka',
      'localtime': '2024-04-23 10:42',
    },
    'current': {
      'temp_c': 29.4,
      'is_day': 1,
      'condition': {'text': 'Partly cloudy', 'code': 1003},
      'feelslike_c': 32.0,
      'humidity': 78,
      'wind_kph': 14.0,
      'uv': 6.0,
      'pressure_mb': 1012.0,
      'vis_km': 10.0,
      'cloud': 40,
      'wind_dir': 'NW',
    },
    'forecast': {
      'forecastday': [
        _day('2024-04-23'),
        _day('2024-04-24'),
        _day('2024-04-25'),
      ],
    },
  };
  final cities = [
    {'name': 'Kandy', 'region': 'Central', 'country': 'Sri Lanka'},
  ];
  return WeatherService(
    client: MockClient((request) async {
      if (status != 200) {
        return http.Response(jsonEncode(body), status);
      }
      final payload = request.url.path.endsWith('search.json')
          ? cities
          : weather;
      return http.Response(jsonEncode(payload), 200);
    }),
  );
}

/// Location is unavailable in tests, so the app falls back to the saved city.
class _FakeLocation extends LocationService {
  @override
  Future<String> currentQuery({bool allowPrompt = true}) =>
      throw const LocationException(LocationFailure.unavailable);
}

/// Records how the app asked for the location on start-up.
class _RecordingLocation extends LocationService {
  final prompts = <bool>[];

  @override
  Future<String> currentQuery({bool allowPrompt = true}) async {
    prompts.add(allowPrompt);
    return 'auto:ip';
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders the SkyCast weather dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(SkyCastApp(service: _fakeService(), location: _FakeLocation()));
    await tester.pumpAndSettle();

    expect(find.text('SkyCast'), findsOneWidget);
    expect(find.text('Colombo, Sri Lanka'), findsOneWidget);
    expect(find.text('29°'), findsOneWidget);
    expect(find.text('Today’s highlights'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('5-day forecast'), findsOneWidget);
  });

  testWidgets('shows the city-not-found state for an unknown city', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      SkyCastApp(
        location: _FakeLocation(),
        service: _fakeService(
          status: 400,
          body: {
            'error': {'code': 1006, 'message': 'No matching location found.'},
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('City not found'), findsOneWidget);
  });

  testWidgets('renders weather details from the highlights link', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      SkyCastApp(service: _fakeService(), location: _FakeLocation()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('See details'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailsScreen), findsOneWidget);
    expect(find.text('06:12 AM'), findsOneWidget);
    expect(find.text('06:20 PM'), findsOneWidget);
    expect(find.text('1012 hPa'), findsOneWidget);
    expect(find.text('10 km'), findsOneWidget);
  });

  testWidgets('keeps the navigation bar on every screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      SkyCastApp(service: _fakeService(), location: _FakeLocation()),
    );
    await tester.pumpAndSettle();

    Finder navLabel(String label) =>
        find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

    for (final label in ['Forecast', 'Saved', 'Settings']) {
      await tester.tap(navLabel(label));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget, reason: label);
    }
    expect(find.text('Appearance'), findsOneWidget);

    // The tab's back arrow returns to Home with the bar still in place.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Today’s highlights'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Pushed pages keep the bar, and it jumps straight to another tab.
    await tester.tap(find.text('See details'));
    await tester.pumpAndSettle();
    expect(find.byType(DetailsScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(navLabel('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(DetailsScreen), findsNothing);
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('refreshes the location on open without prompting', (
    WidgetTester tester,
  ) async {
    final location = _RecordingLocation();
    await tester.pumpWidget(
      SkyCastApp(service: _fakeService(), location: location),
    );
    await tester.pumpAndSettle();

    expect(location.prompts, [false]);
    expect(find.text('Colombo, Sri Lanka'), findsOneWidget);
  });

  testWidgets('shows the welcome flow only on the first run', (
    WidgetTester tester,
  ) async {
    await AppSettings.instance.load();
    expect(AppSettings.instance.onboarded, isFalse);

    await tester.pumpWidget(
      SkyCastApp(
        service: _fakeService(),
        location: _FakeLocation(),
        showOnboarding: true,
      ),
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.text('Explore Weather'));
    await tester.pumpAndSettle();

    expect(AppSettings.instance.onboarded, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarded'), isTrue);
  });

  testWidgets('saved cities survive an app restart', (
    WidgetTester tester,
  ) async {
    await CityStore().saveSaved(['Matale, Sri Lanka', 'Kandy, Sri Lanka']);

    await tester.pumpWidget(
      MaterialApp(
        home: SavedCitiesScreen(
          currentCity: 'Colombo, Sri Lanka',
          service: _fakeService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Matale, Sri Lanka'), findsOneWidget);
    expect(find.text('Kandy, Sri Lanka'), findsOneWidget);
  });

  testWidgets('persists the chosen theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      SkyCastApp(service: _fakeService(), location: _FakeLocation()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light Theme'));
    await tester.pumpAndSettle();

    expect(AppSettings.instance.themeMode, ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
    await AppSettings.instance.setThemeMode(ThemeMode.dark);
  });

  testWidgets('renders and switches the detailed forecast view', (
    WidgetTester tester,
  ) async {
    final report = await _fakeService().fetchWeather('Colombo');
    await tester.pumpWidget(MaterialApp(home: ForecastScreen(report: report)));

    expect(find.text('Weather Forecast'), findsOneWidget);
    expect(find.text('Colombo, Sri Lanka'), findsOneWidget);
    expect(find.text('Hourly forecast'), findsOneWidget);
    expect(find.text('Temperature next 24 hours'), findsOneWidget);

    await tester.tap(find.text('5 Days'));
    await tester.pumpAndSettle();

    expect(find.text('5-day forecast'), findsOneWidget);
    expect(find.text('Tomorrow'), findsNothing);
    expect(find.text('Wed'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('Humidity'), findsOneWidget);
  });

  testWidgets('renders and filters the city search screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'recent_searches': ['Colombo'],
    });
    await tester.pumpWidget(
      MaterialApp(home: CitySearchScreen(service: _fakeService())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search City'), findsOneWidget);
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Colombo'), findsOneWidget);
    expect(find.text('Use My Location'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Kan');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.text('Kandy'), findsOneWidget);
    expect(find.text('Central, Sri Lanka'), findsOneWidget);
    expect(find.text('Colombo'), findsNothing);
  });

  testWidgets('renders saved cities and opens city details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SavedCitiesScreen(
          currentCity: 'Colombo',
          service: _fakeService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved Cities'), findsOneWidget);
    expect(find.text('Colombo'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('29°'), findsOneWidget);
    expect(find.text('Add City'), findsOneWidget);

    await tester.tap(find.text('Colombo'));
    await tester.pumpAndSettle();
    expect(find.text('Weather Forecast'), findsOneWidget);
  });

  testWidgets('renders settings and changes preferences', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Weather preferences'), findsOneWidget);
    expect(find.text('Automatic location'), findsOneWidget);
    await tester.tap(find.text('Dark Theme'));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('About SkyCast'), findsOneWidget);
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
    expect(find.text('Close'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Close'), findsNothing);
  });

  testWidgets('renders explicit weather request states', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WeatherStateView(state: WeatherRequestState.networkError),
      ),
    );

    expect(find.text('Unable to load weather'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('SkyCast'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: WeatherStateView(
          state: WeatherRequestState.offline,
          hasCachedWeather: true,
          lastUpdated: 'Today, 9:42 AM',
        ),
      ),
    );
    expect(find.text('Showing saved weather'), findsOneWidget);
    expect(find.text('Last updated Today, 9:42 AM'), findsOneWidget);
  });
}
