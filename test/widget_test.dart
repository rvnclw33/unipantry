// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import your actual app file
import 'package:unipantry/app.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Wrap your App in a ProviderScope, just like in main.dart
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    // Because your app now shows a loading spinner or login screen,
    // we'll just test that no errors are thrown.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
}
