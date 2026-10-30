import 'package:daymark/data/daymark_store.dart';
import 'package:daymark/data/today_repository.dart';
import 'package:daymark/domain/today_schedule.dart';
import 'package:daymark/ui/day_notes/day_notes_panel.dart';
import 'package:daymark/ui/daymark_app.dart';
import 'package:daymark/ui/theme/daymark_theme.dart';
import 'package:daymark/ui/today/desktop_date_picker_dialog.dart';
import 'package:daymark/ui/today/today_lesson_row.dart';
import 'package:daymark/ui/today/today_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('holiday empty state is clear at desktop content width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1054, 717);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await DaymarkStore.inMemory();
    addTearDown(store.close);
    final date = DateTime(2026, 10, 30);

    await tester.pumpWidget(
      MaterialApp(
        theme: daymarkTheme(),
        home: Scaffold(
          body: TodayView(
            date: date,
            now: DateTime(2026, 10, 30, 10),
            schedule: TodaySchedule(lessons: [], reason: 'Herbstferien'),
            notesPanel: DayNotesPanel(store: store, date: date),
            onPrevious: () {},
            onNext: () {},
            onToday: () {},
            onPickDate: () {},
            onOpenLesson: (_) {},
            onRetry: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Herbstferien'), findsOneWidget);
    expect(
      find.text('Für diesen Tag ist kein Unterricht geplant.'),
      findsOneWidget,
    );
    expect(find.text('Tagesnotizen'), findsOneWidget);
    expect(find.text('Eintrag'), findsNothing);
    expect(find.text('Eintrag hinzufügen'), findsOneWidget);
    final dateLabel = tester.widget<Text>(
      find.byKey(const ValueKey('selected-date-label')),
    );
    expect(dateLabel.data, 'Freitag, 30. Oktober');
    expect(dateLabel.style?.fontSize, 26);
    expect(dateLabel.style?.fontWeight, FontWeight.w700);
    final todayButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Heute'),
    );
    expect(todayButton.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('day notes persist for past and future dates', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await DaymarkStore.inMemory();
    addTearDown(store.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: daymarkTheme(),
        home: DaymarkApp(store: store, initialDate: DateTime(2026, 12, 31)),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> addNote(String text) async {
      await tester.tap(find.text('Eintrag hinzufügen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Notiz'), text);
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
    }

    await addNote('Jahresabschluss vorbereiten');
    expect(find.text('Eintrag'), findsOneWidget);
    expect(
      (await store.dayNotes('2026-12-31')).single['body'],
      'Jahresabschluss vorbereiten',
    );
    await tester.tap(find.byTooltip('Nächster Tag'));
    await tester.pumpAndSettle();
    expect(find.text('Jahresabschluss vorbereiten'), findsNothing);
    expect(find.text('Eintrag'), findsNothing);
    await addNote('Neujahrsplanung');
    expect(
      (await store.dayNotes('2027-01-01')).single['body'],
      'Neujahrsplanung',
    );
    await tester.tap(find.byTooltip('Eintragsaktionen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bearbeiten').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notiz'),
      'Neujahrsplanung aktualisiert',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(
      (await store.dayNotes('2027-01-01')).single['body'],
      'Neujahrsplanung aktualisiert',
    );
    await tester.tap(find.byTooltip('Eintragsaktionen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen').last);
    await tester.pumpAndSettle();
    expect(find.text('Eintrag löschen?'), findsOneWidget);
    await tester.tap(find.text('Löschen').last);
    await tester.pumpAndSettle();
    expect(await store.dayNotes('2027-01-01'), isEmpty);
    await tester.tap(find.byTooltip('Voriger Tag'));
    await tester.pumpAndSettle();
    expect(find.text('Jahresabschluss vorbereiten'), findsOneWidget);
    await tester.tap(find.byTooltip('Voriger Tag'));
    await tester.pumpAndSettle();
    await addNote('Alte Unterlagen sortieren');
    expect(
      (await store.dayNotes('2026-12-30')).single['body'],
      'Alte Unterlagen sortieren',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

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

  testWidgets('desktop lesson rows use the compact list height', (
    tester,
  ) async {
    final date = DateTime(2026, 5, 12);
    final lesson = TodayLesson(
      slotId: 1,
      classId: 1,
      className: '8b',
      subject: 'Englisch',
      period: 3,
      day: date,
      startTime: '09:55',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: daymarkTheme(),
        home: Scaffold(
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TodayLessonRow(
                lesson: lesson,
                now: DateTime(2026, 5, 12, 8),
                first: true,
                last: true,
                onOpen: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(TodayLessonRow)).height,
      TodayLessonRow.minimumHeight,
    );
    expect(tester.takeException(), isNull);
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
    expect(find.text('Tagesnotizen'), findsOneWidget);
    await tester.tap(find.byTooltip('Nächster Tag'));
    await tester.pumpAndSettle();
    expect(find.text('Freitag, 1. Januar'), findsOneWidget);
    expect(find.text('2. Stunde'), findsOneWidget);
    await tester.tap(find.text('Freitag, 1. Januar'));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopDatePickerDialog), findsOneWidget);
    expect(find.text('Freitag, 1. Januar 2027'), findsOneWidget);
    expect(find.text('01.01.2027'), findsOneWidget);
    final dialogSize = tester.getSize(find.byType(DesktopDatePickerDialog));
    expect(dialogSize.width, greaterThanOrEqualTo(800));
    expect(dialogSize.height, greaterThanOrEqualTo(580));
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

  testWidgets('date picker remains usable in a narrow window', (tester) async {
    tester.view.physicalSize = const Size(620, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: daymarkTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  await showDaymarkDatePicker(
                    context: context,
                    initialDate: DateTime(2026, 10, 30),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2200, 12, 31),
                  );
                },
                child: const Text('Kalender öffnen'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Kalender öffnen'));
    await tester.pumpAndSettle();

    expect(find.text('Freitag, 30. Oktober 2026'), findsOneWidget);
    expect(find.text('30.10.2026'), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
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
          schedule: TodaySchedule(lessons: [lesson]),
          notesPanel: const SizedBox(
            height: 300,
            child: Text('Noch keine Notizen.'),
          ),
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
    await tester.scrollUntilVisible(find.text('Noch keine Notizen.'), 150);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(view(error: 'Laden fehlgeschlagen'));
    await tester.tap(find.text('Erneut versuchen'));
    expect(retries, 1);
  });
}
