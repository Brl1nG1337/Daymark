import 'package:daymark/data/daymark_store.dart';
import 'package:daymark/ui/daymark_app.dart';
import 'package:daymark/ui/theme/daymark_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(1400, 900), const Size(700, 700)]) {
    testWidgets('classes, planning and settings render at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await DaymarkStore.inMemory();
      addTearDown(store.close);
      await store.addClass('8b');
      await store.addStudent(1, 'Lea', 'Hartmann');
      await store.addSlot(1, 'Englisch', 1, 3, '09:55', '2020-01-01');
      await tester.pumpWidget(MaterialApp(home: DaymarkApp(store: store)));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byTooltip('Klassen').evaluate().isNotEmpty
            ? find.byTooltip('Klassen')
            : find.text('Klassen').first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Klasse 8b'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Hartmann, Lea'));
      await tester.pumpAndSettle();
      expect(find.text('Bemerkungen'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.byTooltip('Stundenplan').evaluate().isNotEmpty
            ? find.byTooltip('Stundenplan')
            : find.text('Stundenplan').first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Stundenplan'), findsWidgets);
      expect(find.text('Stunde hinzufügen'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.byTooltip('Einstellungen').evaluate().isNotEmpty
            ? find.byTooltip('Einstellungen')
            : find.text('Einstellungen').first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Unterrichtszeiten'), findsOneWidget);
      expect(find.text('Schuljahr & Kalender'), findsOneWidget);
      expect(find.text('Daten & Sicherheit'), findsOneWidget);
      expect(find.text('Design'), findsOneWidget);
      expect(find.text('Darstellung'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('timetable keeps subject cards neutral', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await DaymarkStore.inMemory();
    addTearDown(store.close);
    await store.addClass('8b');
    await store.addSlot(1, 'Englisch', 1, 1, '08:00', '2020-01-01');
    await store.addSlot(1, 'Englisch', 2, 1, '08:00', '2020-01-01');
    await store.addSlot(1, 'Deutsch', 3, 1, '08:00', '2020-01-01');

    await tester.pumpWidget(MaterialApp(home: DaymarkApp(store: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stundenplan').first);
    await tester.pumpAndSettle();

    final englishMonday = tester.widget<Material>(
      find.byKey(const ValueKey('planning-slot-1-1')),
    );
    final englishTuesday = tester.widget<Material>(
      find.byKey(const ValueKey('planning-slot-2-1')),
    );
    final germanWednesday = tester.widget<Material>(
      find.byKey(const ValueKey('planning-slot-3-1')),
    );
    expect(englishMonday.color, englishTuesday.color);
    expect(englishMonday.color, germanWednesday.color);
    expect(tester.takeException(), isNull);
  });

  testWidgets('class roster keeps headings and cells on one column grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1125, 637);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await DaymarkStore.inMemory();
    addTearDown(store.close);
    await store.setSetting('school_year', '2026');
    await store.addClass('3A');
    await store.addStudent(1, 'Amelie', 'Becker');
    await store.db.customStatement(
      "UPDATE enrollments SET start_date='2026-08-01'",
    );
    final lessonDay = DateTime(2026, 10, 15);
    await store.addSlot(
      1,
      'Englisch',
      lessonDay.weekday,
      2,
      '08:50',
      '2026-08-01',
    );
    final lessonId = await store.openLesson(
      (await store.slots()).single,
      '2026-10-15',
    );
    await store.setAttendance(lessonId, 1, 'absent');
    await store.complete(lessonId);

    await tester.pumpWidget(MaterialApp(home: DaymarkApp(store: store)));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byTooltip('Klassen').evaluate().isNotEmpty
          ? find.byTooltip('Klassen')
          : find.text('Klassen').first,
    );
    await tester.pumpAndSettle();

    final headingAbsences = tester.getCenter(
      find.byKey(const ValueKey('roster-heading-absences')),
    );
    final headingLates = tester.getCenter(
      find.byKey(const ValueKey('roster-heading-lates')),
    );
    final headingLastEntry = tester.getCenter(
      find.byKey(const ValueKey('roster-heading-last-entry')),
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('roster-1-absences'))).dx,
      closeTo(headingAbsences.dx, 1),
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('roster-1-lates'))).dx,
      closeTo(headingLates.dx, 1),
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('roster-1-last-entry'))).dx,
      closeTo(headingLastEntry.dx, 1),
    );
    expect(find.text('15.10.2026'), findsOneWidget);
    expect(find.text('2026-10-15'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits class, timetable entry and lesson time', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await DaymarkStore.inMemory();
    addTearDown(store.close);
    await store.addClass('8b');
    await store.addSlot(1, 'Englisch', 1, 3, '09:55', '2020-01-01');
    await tester.pumpWidget(MaterialApp(home: DaymarkApp(store: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Klassen').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Klasse bearbeiten'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '8c');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect((await store.classes()).single['name'], '8c');
    expect(find.text('Schüler (0)'), findsOneWidget);
    await tester.tap(find.text('Schüler hinzufügen'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('student-first-name')),
      'Max',
    );
    await tester.enterText(
      find.byKey(const ValueKey('student-last-name')),
      'Muster',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Muster, Max'), findsOneWidget);
    await tester.tap(find.text('Stundenplan').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Englisch').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bearbeiten'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Gültig ab (TT.MM.JJJJ)'),
          )
          .initialValue,
      '01.01.2020',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Fach'), 'Deutsch');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect((await store.slots()).single['subject'], 'Deutsch');
    expect((await store.slots()).single['valid_from'], '2020-01-01');
    await tester.tap(find.text('Einstellungen').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unterrichtszeiten'));
    await tester.pumpAndSettle();
    expect(find.text('Unterrichtszeiten bearbeiten'), findsOneWidget);
    expect(find.text('Zeiten bearbeiten'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('period-1-start')),
      '08:10',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(await store.setting('period_1'), '08:10');
    expect(find.text('Unterrichtszeiten bearbeiten'), findsNothing);
    expect(find.text('Unterrichtszeiten gespeichert.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits first and last name in one student dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await DaymarkStore.inMemory();
    addTearDown(store.close);
    await store.addClass('8b');
    await store.addStudent(1, 'Max', 'Muster');

    await tester.pumpWidget(MaterialApp(home: DaymarkApp(store: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Klassen').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muster, Max'));
    await tester.pumpAndSettle();
    final nameRect = tester.getRect(
      find.byKey(const ValueKey('student-detail-name')),
    );
    final editRect = tester.getRect(
      find.byKey(const ValueKey('edit-student-button')),
    );
    expect(editRect.left, greaterThan(nameRect.right));
    expect(editRect.center.dy, closeTo(nameRect.center.dy, 1));
    await tester.tap(find.text('Schüler bearbeiten'));
    await tester.pumpAndSettle();

    expect(find.text('Schüler bearbeiten'), findsWidgets);
    expect(find.byKey(const ValueKey('student-first-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('student-last-name')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('student-first-name')),
      'Mara',
    );
    await tester.enterText(
      find.byKey(const ValueKey('student-last-name')),
      'Beispiel',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Beispiel, Mara'), findsOneWidget);
    final student = (await store.students(1, dayKey(DateTime.now()))).single;
    expect(student['first_name'], 'Mara');
    expect(student['last_name'], 'Beispiel');
    expect(find.text('Vorname'), findsNothing);
    expect(find.text('Nachname'), findsNothing);
  });
  testWidgets('school free days live in settings', (tester) async {
    final store = await DaymarkStore.inMemory();
    addTearDown(store.close);
    await tester.pumpWidget(MaterialApp(home: DaymarkApp(store: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Stundenplan'));
    await tester.pumpAndSettle();
    expect(find.text('Schulfreie Tage'), findsNothing);
    await tester.tap(find.byTooltip('Einstellungen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Schulfreie Tage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tag hinzufügen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '02.11.2026');
    await tester.enterText(find.byType(TextFormField).last, 'Studientag');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect((await store.freeDays()).single['label'], 'Studientag');
    expect((await store.freeDays()).single['day'], '2026-11-02');
    expect(find.text('02.11.2026'), findsOneWidget);
  });
  testWidgets('global student search opens a note in its lesson', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await DaymarkStore.inMemory();
    addTearDown(store.close);
    await store.addClass('8b');
    await store.addClass('9a');
    await store.addStudent(2, 'Lea', 'Hartmann');
    final today = DateTime.now();
    await store.addSlot(2, 'Englisch', today.weekday, 3, '09:55', '2020-01-01');
    final slot = (await store.slots()).single;
    final lessonId = await store.openLesson(slot, dayKey(today));
    await store.addNote(lessonId, 1, 'Gut mitgearbeitet');
    await store.complete(lessonId);
    await tester.pumpWidget(MaterialApp(home: DaymarkApp(store: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Klassen').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Schüler suchen'),
      'Hartmann',
    );
    await tester.pumpAndSettle();
    expect(find.text('Klasse 9a'), findsOneWidget);
    await tester.tap(find.text('Hartmann, Lea'));
    await tester.pumpAndSettle();
    expect(find.text('Gut mitgearbeitet'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stunde öffnen'));
    await tester.pumpAndSettle();
    expect(find.text('Stunde erneut öffnen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('theme choice persists', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await DaymarkStore.inMemory();
    addTearDown(store.close);
    var mode = ThemeMode.light;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          DaymarkColors.dark = mode == ThemeMode.dark;
          return MaterialApp(
            theme: daymarkTheme(),
            darkTheme: daymarkTheme(dark: true),
            themeMode: mode,
            home: DaymarkApp(
              store: store,
              onThemeChanged: (value) => setState(() => mode = value),
            ),
          );
        },
      ),
    );
    addTearDown(() => DaymarkColors.dark = false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Einstellungen').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Design'));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('theme-toggle'));
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.widget<Switch>(toggle).value, isFalse);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(await store.setting('theme'), 'dark');
    expect(mode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('Design').first)).brightness,
      Brightness.dark,
    );
    expect(tester.widget<Switch>(toggle).value, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(mode, ThemeMode.light);
    expect(
      Theme.of(tester.element(find.text('Design').first)).brightness,
      Brightness.light,
    );
    expect(await store.setting('theme'), 'light');
    expect(tester.widget<Switch>(toggle).value, isFalse);
  });

  test('dark palette keeps readable surface contrast', () {
    DaymarkColors.dark = true;
    addTearDown(() => DaymarkColors.dark = false);
    final theme = daymarkTheme(dark: true);
    expect(theme.brightness, Brightness.dark);
    expect(DaymarkColors.surface, isNot(DaymarkColors.ink));
  });
}
