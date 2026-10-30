import 'package:daymark/data/daymark_store.dart';
import 'package:daymark/ui/daymark_app.dart';
import 'package:daymark/ui/lesson_detail/lesson_detail_page.dart';
import 'package:daymark/domain/today_schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens a planned lesson in its own screen and starts it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    expect(find.text('Geplante Stunde'), findsOneWidget);
    expect(find.text('Stunde starten'), findsOneWidget);
    expect(find.text('Klasse auswählen.'), findsNothing);
    await tester.tap(find.text('Stunde starten'));
    await tester.pumpAndSettle();
    expect(find.text('Stunde abschließen'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('attendance-1-absent')));
    await tester.pumpAndSettle();
    expect((await store.attendance(1)).single['status'], 'absent');
    await tester.tap(find.text('Muster, Erika'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Gut mitgearbeitet');
    await tester.tap(find.text('Bemerkung speichern'));
    await tester.pumpAndSettle();
    expect((await store.notes(1)).single['body'], 'Gut mitgearbeitet');
    await tester.tap(find.text('Bemerkung löschen'));
    await tester.pumpAndSettle();
    expect(await store.notes(1), isEmpty);
    await tester.tap(find.text('Stundeninhalt'));
    await tester.pumpAndSettle();
    final topicField = find.byKey(const ValueKey('lesson-thema'));
    final noteField = find.byKey(const ValueKey('lesson-stundennotiz'));
    expect(
      tester.widget<TextField>(noteField).textAlignVertical,
      TextAlignVertical.top,
    );
    expect(
      tester.widget<TextField>(noteField).decoration?.hintText,
      'Was wurde in der Stunde behandelt?',
    );
    await tester.enterText(topicField, 'Brüche');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect((await store.lesson(1))['topic'], 'Brüche');
    await tester.tap(find.text('Stunde abschließen'));
    await tester.pumpAndSettle();
    expect((await store.lesson(1))['completed'], 1);
    await tester.tap(find.byIcon(Icons.chevron_left).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Abgeschlossen'), findsOneWidget);
  });
  testWidgets('detail remains usable in a narrow window', (tester) async {
    tester.view.physicalSize = const Size(620, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await DaymarkStore.inMemory();
    addTearDown(store.close);
    await store.addClass('8b');
    await store.addStudent(1, 'Erika', 'Muster');
    final day = DateTime.now();
    await store.addSlot(1, 'Mathe', day.weekday, 2, '09:00', '2020-01-01');
    final slot = (await store.slots()).single;
    final id = await store.openLesson(slot, dayKey(day));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonDetailPage(
            store: store,
            lesson: TodayLesson(
              slotId: slot['id'] as int,
              classId: 1,
              className: '8b',
              subject: 'Mathe',
              period: 2,
              day: day,
              lessonId: id,
            ),
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Anwesenheit'), findsWidgets);
    await tester.tap(find.text('Muster, Erika'));
    await tester.pumpAndSettle();
    expect(
      find.byTooltip('Bemerkung schließen', skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    final outer = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey('lesson-detail-narrow-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    outer.position.jumpTo(outer.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('Bemerkung speichern'), findsOneWidget);
  });

  testWidgets('a started lesson can be reset from the detail header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await DaymarkStore.inMemory();
    addTearDown(store.close);
    await store.addClass('3a');
    await store.addStudent(1, 'Erika', 'Muster');
    final monday = DateTime(2026, 5, 11);
    await store.db.customStatement('UPDATE enrollments SET start_date=?', [
      dayKey(monday.subtract(const Duration(days: 7))),
    ]);
    await store.addSlot(1, 'Mathe', 1, 2, '09:00', '2026-01-01');
    final slot = (await store.slots()).single;
    final id = await store.openLesson(slot, dayKey(monday));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonDetailPage(
            store: store,
            lesson: TodayLesson(
              slotId: slot['id'] as int,
              classId: 1,
              className: '3a',
              subject: 'Mathe',
              period: 2,
              day: monday,
              startTime: '09:00',
              lessonId: id,
            ),
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Stundenstart rückgängig machen'));
    await tester.pumpAndSettle();
    expect(find.text('Stundenstart rückgängig machen?'), findsOneWidget);
    await tester.tap(find.text('Start rückgängig'));
    await tester.pumpAndSettle();

    expect(find.text('Geplante Stunde'), findsOneWidget);
    expect(find.text('Stunde starten'), findsOneWidget);
    expect((await store.weekEntries(monday)).single['lesson_id'], isNull);
  });
}
