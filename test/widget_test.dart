import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skycast/main.dart';
import 'package:skycast/screens/forecast_screen.dart';

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
}
