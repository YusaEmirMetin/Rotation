// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rotation_app/main.dart';
import 'package:rotation_app/tournament_detail_screen.dart';

void main() {
  testWidgets('RotationApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RotationApp());
    await tester.pumpAndSettle();

    // Verify that RotationApp is rendered.
    expect(find.byType(RotationApp), findsOneWidget);
  });

  testWidgets('referee dialog returns names and disposes its controllers safely', (WidgetTester tester) async {
    List<String>? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<List<String>>(
                  context: context,
                  builder: (_) => const CreateRefereeDialog(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Ada');
    await tester.enterText(find.byType(TextFormField).at(1), 'Yilmaz');
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();

    expect(result, ['Ada', 'Yilmaz']);
    expect(tester.takeException(), isNull);
  });
}
