import 'package:flutter/material.dart';

import '../data/daymark_store.dart';
import 'daymark_sidebar.dart';
import 'today/today_page.dart';
import 'lesson_detail/lesson_detail_page.dart';
import 'classes/classes_page.dart';
import 'planning/planning_page.dart';
import 'settings/settings_page.dart';
import '../domain/today_schedule.dart';

String scheduleWeekdayLabel(Object? weekday) => switch (weekday) {
  1 => 'Mo',
  2 => 'Di',
  3 => 'Mi',
  4 => 'Do',
  5 => 'Fr',
  6 => 'Sa',
  7 => 'So',
  _ => 'Tag fehlt',
};

Future<String?> showTextInputDialog(
  BuildContext context,
  String title, {
  String hint = '',
  String initial = '',
}) async {
  final value = await showDialog<String>(
    context: context,
    builder: (context) =>
        _TextInputDialog(title: title, hint: hint, initial: initial),
  );
  return value?.trim().isNotEmpty == true ? value!.trim() : null;
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.hint,
    required this.initial,
  });

  final String title;
  final String hint;
  final String initial;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      decoration: InputDecoration(hintText: widget.hint),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Übernehmen')),
    ],
  );
}

class DaymarkApp extends StatefulWidget {
  const DaymarkApp({
    super.key,
    required this.store,
    this.initialDate,
    this.onSessionEnded,
    this.onThemeChanged,
  });
  final DateTime? initialDate;
  final DaymarkStore store;
  final VoidCallback? onSessionEnded;
  final ValueChanged<ThemeMode>? onThemeChanged;
  @override
  State<DaymarkApp> createState() => _DaymarkAppState();
}

class _DaymarkAppState extends State<DaymarkApp> {
  int page = 0;
  late DateTime selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialDate ?? DateTime.now();
  }

  TodayLesson? selectedLesson;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        DaymarkSidebar(
          selectedIndex: page,
          onSelected: (index) => setState(() {
            page = index;
            selectedLesson = null;
          }),
        ),
        Expanded(
          child: switch (page) {
            0 => selectedLesson == null ? dashboard() : lessonDetail(),
            1 => classes(),
            2 => schedule(),
            _ => freeDays(),
          },
        ),
      ],
    ),
  );
  Widget dashboard() => TodayPage(
    store: widget.store,
    initialDate: selected,
    onDateChanged: (date) => selected = date,
    onOpenLesson: (lesson) => setState(() {
      selectedLesson = lesson;
    }),
  );
  Widget classes() => ClassesPage(
    store: widget.store,
    onOpenLesson: (lesson) => setState(() {
      page = 0;
      selectedLesson = lesson;
    }),
  );
  Widget lessonDetail() => LessonDetailPage(
    store: widget.store,
    lesson: selectedLesson!,
    onBack: () => setState(() {
      selectedLesson = null;
    }),
  );

  Widget schedule() => PlanningPage(store: widget.store);
  Widget freeDays() => SettingsPage(
    store: widget.store,
    onSessionEnded: widget.onSessionEnded ?? () {},
    onThemeChanged: widget.onThemeChanged ?? (_) {},
  );
}
