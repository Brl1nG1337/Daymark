import 'package:daymark/data/daymark_store.dart';
import 'package:daymark/ui/daymark_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens a planned lesson in its own screen and starts it', (
    tester,
  ) async {
    final store = await DaymarkStore.inMemory();
    addTearDown(store.close);
    await store.addClass('3a');
    await store.addStudent(1, 'Erika', 'Muster');
    final monday = DateTime(2026, 5, 11);
    await store.db.customStatement('UPDATE enrollments SET start_date=?', [
      dayKey(monday.subtract(const Duration(days: 7))),
    ]);
    await store.addSlot(
      1,
      'Mathe',
      1,
      2,
      '09:00',
      dayKey(monday.subtract(const Duration(days: 7))),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DaymarkApp(store: store, initialDate: monday),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Heute'), findsWidgets);
    await tester.tap(find.text('2. Stunde'));
    await tester.pumpAndSettle();
    expect(find.text('Stundendetail'), findsOneWidget);
    expect(find.text('Stunde starten'), findsOneWidget);
    expect(find.text('Klasse auswählen.'), findsNothing);
    await tester.tap(find.text('Stunde starten'));
    await tester.pumpAndSettle();
    expect(find.text('Stunde abschließen'), findsOneWidget);
    await tester.tap(find.text('Stundeninhalt bearbeiten'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Thema'),
      'Brüche',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Brüche'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Muster, Erika'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byIcon(Icons.check_circle).first);
    await tester.pumpAndSettle();
    expect((await store.attendance(1)).single['status'], 'absent');
    await tester.tap(find.text('Stunde abschließen'));
    await tester.pumpAndSettle();
    expect(find.text('Stunde erneut öffnen'), findsOneWidget);
    await tester.tap(find.text('Zum Stundenplan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Abgeschlossen'), findsOneWidget);
  });
}
