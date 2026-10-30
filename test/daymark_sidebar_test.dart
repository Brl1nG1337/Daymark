import 'package:daymark/ui/daymark_sidebar.dart';
import 'package:daymark/ui/theme/daymark_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('first navigation destination is Unterricht', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DaymarkSidebar(selectedIndex: 0, onSelected: (_) {}),
        ),
      ),
    );

    expect(find.text('Unterricht'), findsOneWidget);
    expect(find.text('Heute'), findsNothing);
  });

  testWidgets('sidebar greets Madame Röling according to the time of day', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> showAt(int hour) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DaymarkSidebar(
            selectedIndex: 0,
            onSelected: (_) {},
            currentTime: DateTime(2026, 10, 30, hour),
          ),
        ),
      ),
    );

    await showAt(8);
    expect(find.text('Guten Morgen,'), findsOneWidget);
    expect(find.text('Madame Röling'), findsOneWidget);

    await showAt(13);
    expect(find.text('Guten Tag,'), findsOneWidget);
    expect(find.text('Madame Röling'), findsOneWidget);

    await showAt(20);
    expect(find.text('Guten Abend,'), findsOneWidget);
    expect(find.text('Madame Röling'), findsOneWidget);
    expect(find.byTooltip('Guten Abend, Madame Röling'), findsOneWidget);
    expect(find.bySemanticsLabel('Daymark'), findsNothing);

    expect(
      find.byKey(const ValueKey('sidebar-greeting-gradient')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('sidebar-greeting-divider')),
      findsOneWidget,
    );
  });

  testWidgets('compact sidebar exposes the greeting as a tooltip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DaymarkSidebar(
            selectedIndex: 0,
            onSelected: (_) {},
            currentTime: DateTime(2026, 10, 30, 20),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.waving_hand_outlined), findsOneWidget);
    expect(find.byTooltip('Guten Abend, Madame Röling'), findsOneWidget);
  });

  testWidgets('navigation labels turn black on hover', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DaymarkSidebar(selectedIndex: 0, onSelected: (_) {}),
        ),
      ),
    );

    final label = find.text('Klassen');
    expect(tester.widget<Text>(label).style?.color, DaymarkColors.onSidebar);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(label));
    await tester.pump();

    expect(tester.widget<Text>(label).style?.color, DaymarkColors.ink);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.groups_rounded)).color,
      DaymarkColors.ink,
    );
  });

  testWidgets('navigation labels stay light on hover in dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    DaymarkColors.dark = true;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => DaymarkColors.dark = false);

    await tester.pumpWidget(
      MaterialApp(
        theme: daymarkTheme(dark: true),
        home: Scaffold(
          body: DaymarkSidebar(selectedIndex: 0, onSelected: (_) {}),
        ),
      ),
    );

    final label = find.text('Klassen');
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(label));
    await tester.pump();

    expect(tester.widget<Text>(label).style?.color, DaymarkColors.onSidebar);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.groups_rounded)).color,
      DaymarkColors.sidebarIcon,
    );
  });
}
