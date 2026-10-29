import 'package:daymark/ui/daymark_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps its controller alive until the dialog is removed', (
    tester,
  ) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await showTextInputDialog(context, 'Vorname');
            },
            child: const Text('Dialog öffnen'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Dialog öffnen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Erika  ');
    await tester.tap(find.text('Übernehmen'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(result, 'Erika');
  });
}
