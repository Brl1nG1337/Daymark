import 'package:daymark/data/daymark_store.dart';
import 'package:daymark/data/today_repository.dart';
import 'package:daymark/domain/today_schedule.dart';
import 'package:daymark/ui/daymark_app.dart';
import 'package:daymark/ui/theme/daymark_theme.dart';
import 'package:daymark/ui/today/today_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('current lesson uses a half-open interval and explicit completion', () {
    final lesson = TodayLesson(
      slotId: 1,
      classId: 1,
      className: '8b',
      subject: 'Englisch',
      period: 3,
      day: DateTime(2026, 5, 12),
      startTime: '09:55',
    );
    expect(lesson.isCurrent(DateTime(2026, 5, 12, 9, 54)), isFalse);
    expect(lesson.isCurrent(DateTime(2026, 5, 12, 9, 55)), isTrue);
    expect(lessonTime(lesson.endsAt), '10:40');
    expect(lesson.isCurrent(DateTime(2026, 5, 12, 10, 40)), isFalse);
    expect(lesson.isCurrent(DateTime(2026, 5, 13, 10)), isFalse);
    final invalid = TodayLesson(
      slotId: 2,
      classId: 1,
      className: '8b',
      subject: 'Englisch',
      period: 4,
      day: lesson.day,
      startTime: '25:70',
    );
    expect(invalid.startsAt, isNull);
    expect(invalid.isCurrent(DateTime(2026, 5, 12, 10)), isFalse);
    final completed = TodayLesson(
      slotId: 1,
      classId: 1,
      className: '8b',
      subject: 'Englisch',
      period: 3,
      day: lesson.day,
      startTime: '09:55',
      completed: true,
    );
    expect(completed.isCurrent(DateTime(2026, 5, 12, 10)), isFalse);
  });

  test(
    'daily repository includes weekends, completion and free-day labels',
    () async {
      final store = await DaymarkStore.inMemory();
      addTearDown(store.close);
      await store.addClass('8a');
      await store.addSlot(1, 'Mathematik', 6, 1, '08:00', '2026-01-01');
      await store.addSlot(1, 'Deutsch', 7, 2, null, '2026-01-01');
      await store.addFreeDay('2026-05-16', 'Pädagogischer Tag');
      final saturday = DateTime(2026, 5, 16);
      final entry = (await store.dayEntries(saturday)).single;
      final id = await store.openLesson(entry, dayKey(saturday));
      await store.complete(id);
      // Preserve the historical lesson even after its slot becomes invalid.
      await store.endSlot(entry['id'] as int, '2026-05-15');
      final data = await TodayRepository(store).load(saturday);
      expect(data.lessons.single.lessonId, id);
      expect(data.lessons.single.completed, isTrue);
      expect(data.reason, 'Pädagogischer Tag');
      expect(data.tomorrow.single.subject, 'Deutsch');
      expect(data.tomorrow.single.startsAt, isNull);
    },
  );

  testWidgets('day navigation crosses a year boundary and calendar opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await DaymarkStore.inMemory();
    addTearDown(store.close);
    await store.addClass('8a');
    await store.addSlot(1, 'Mathematik', 4, 1, '08:00', '2026-01-01');
    await store.addSlot(1, 'Deutsch', 5, 2, '08:55', '2026-01-01');
    await tester.pumpWidget(
      MaterialApp(
        theme: daymarkTheme(),
        home: DaymarkApp(store: store, initialDate: DateTime(2026, 12, 31)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Donnerstag, 31. Dezember'), findsOneWidget);
    expect(find.text('Freitag, 1. Januar'), findsOneWidget);
    await tester.tap(find.byTooltip('Nächster Tag'));
    await tester.pumpAndSettle();
    expect(find.text('Freitag, 1. Januar'), findsOneWidget);
    expect(find.text('Samstag, 2. Januar'), findsOneWidget);
    expect(find.text('2. Stunde'), findsOneWidget);
    await tester.tap(find.text('Freitag, 1. Januar'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Voriger Tag'));
    await tester.pumpAndSettle();
    expect(find.text('Donnerstag, 31. Dezember'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Heute'));
    await tester.pumpAndSettle();
    expect(find.text(germanDayLabel(DateTime.now())), findsOneWidget);
    // Dispose the screen's timer before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('narrow layout scrolls, opens lessons, and renders errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(620, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final date = DateTime(2026, 5, 12);
    TodayLesson? opened;
    var retries = 0;
    final lesson = TodayLesson(
      slotId: 1,
      classId: 1,
      className: '8b',
      subject: 'Englisch',
      period: 3,
      day: date,
      startTime: '09:55',
    );
    Widget view({String? error}) => MaterialApp(
      theme: daymarkTheme(),
      home: Scaffold(
        body: TodayView(
          date: date,
          now: DateTime(2026, 5, 12, 10),
          schedule: TodaySchedule(lessons: [lesson], tomorrow: []),
          error: error,
          onPrevious: () {},
          onNext: () {},
          onToday: () {},
          onPickDate: () {},
          onOpenLesson: (value) => opened = value,
          onRetry: () => retries++,
        ),
      ),
    );
    await tester.pumpWidget(view());
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('3. Stunde'));
    expect(opened, same(lesson));
    await tester.scrollUntilVisible(find.text('Keine Stunde geplant.'), 150);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(view(error: 'Laden fehlgeschlagen'));
    await tester.tap(find.text('Erneut versuchen'));
    expect(retries, 1);
  });
}
