import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skycast/main.dart';
import 'package:skycast/screens/saved_cities_screen.dart';
import 'package:skycast/screens/forecast_screen.dart';
import 'package:skycast/screens/city_search_screen.dart';
import 'package:skycast/screens/settings_screen.dart';
import 'package:skycast/screens/weather_states_screen.dart';

void main() {
  testWidgets('renders the SkyCast weather dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SkyCastApp());

    expect(find.text('SkyCast'), findsOneWidget);
    expect(find.text('Colombo, Sri Lanka'), findsOneWidget);
    expect(find.text('29°'), findsOneWidget);
    expect(find.text('Today’s highlights'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('5-day forecast'), findsOneWidget);
  });

  testWidgets('renders and switches the detailed forecast view', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ForecastScreen()));

    expect(find.text('Weather Forecast'), findsOneWidget);
    expect(find.text('Hourly forecast'), findsOneWidget);
    expect(find.text('Temperature today'), findsOneWidget);

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
    await tester.pumpWidget(const MaterialApp(home: CitySearchScreen()));

    expect(find.text('Search City'), findsOneWidget);
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Colombo'), findsOneWidget);
    expect(find.text('Use My Location'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Kandy');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.text('Kandy'), findsNWidgets(2));
    expect(find.text('Colombo'), findsNothing);
  });

  testWidgets('renders saved cities and opens city details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SavedCitiesScreen()));

    expect(find.text('Saved Cities'), findsOneWidget);
    expect(find.text('Colombo'), findsOneWidget);
    expect(find.text('Kandy'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Add City'), findsOneWidget);

    await tester.tap(find.text('Galle'));
    await tester.pumpAndSettle();
    expect(find.text('Light rain'), findsOneWidget);
  });

  testWidgets('renders settings and changes preferences', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Weather preferences'), findsOneWidget);
    expect(find.text('Daily weather summary'), findsOneWidget);
    await tester.tap(find.text('Dark Theme'));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('About SkyCast'), findsOneWidget);
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
