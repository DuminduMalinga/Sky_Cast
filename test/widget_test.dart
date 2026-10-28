import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skycast/main.dart';

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
}
