import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skycast/main.dart';
import 'package:skycast/screens/saved_cities_screen.dart';
import 'package:skycast/screens/city_search_screen.dart';

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
}
