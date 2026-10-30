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
      expect(tester.takeException(), isNull);
    });
  }
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
    await tester.tap(find.text('Stundenplan').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Englisch').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bearbeiten'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Fach'), 'Deutsch');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect((await store.slots()).single['subject'], 'Deutsch');
    await tester.tap(find.text('Einstellungen').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unterrichtszeiten'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1. Stunde'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '08:15');
    await tester.tap(find.text('Übernehmen'));
    await tester.pumpAndSettle();
    expect(await store.setting('period_1'), '08:15');
    expect(tester.takeException(), isNull);
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
    await tester.enterText(find.byType(TextFormField).first, '2026-11-02');
    await tester.enterText(find.byType(TextFormField).last, 'Studientag');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect((await store.freeDays()).single['label'], 'Studientag');
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
      find.widgetWithText(TextField, 'Schüler/in suchen'),
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
    await tester.tap(find.text('Design'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dunkel').last);
    await tester.pumpAndSettle();
    expect(await store.setting('theme'), 'dark');
    expect(mode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('Design').first)).brightness,
      Brightness.dark,
    );
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hell').last);
    await tester.pumpAndSettle();
    expect(mode, ThemeMode.light);
    expect(
      Theme.of(tester.element(find.text('Design').first)).brightness,
      Brightness.light,
    );
    expect(await store.setting('theme'), 'light');
  });

  test('dark palette keeps readable surface contrast', () {
    DaymarkColors.dark = true;
    addTearDown(() => DaymarkColors.dark = false);
    final theme = daymarkTheme(dark: true);
    expect(theme.brightness, Brightness.dark);
    expect(DaymarkColors.surface, isNot(DaymarkColors.ink));
  });
}
