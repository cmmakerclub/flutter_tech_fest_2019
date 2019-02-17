// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_grill_hack_mqtt/main.dart';

void main() {
  testWidgets('On Off smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that our counter starts at empty.
    expect(find.text(''), findsOneWidget);
    expect(find.text('ON'), findsNothing);
    expect(find.text('OFF'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.blur_on));
    await tester.pump();

    // Verify that state has chnage.
    expect(find.text(''), findsNothing);
    expect(find.text('ON'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.blur_off));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text(''), findsNothing);
    expect(find.text('OFF'), findsOneWidget);
  });
}
