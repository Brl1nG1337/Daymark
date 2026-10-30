import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/daymark_store.dart';
import '../../data/today_repository.dart';
import '../../domain/today_schedule.dart';
import '../day_notes/day_notes_panel.dart';
import 'desktop_date_picker_dialog.dart';
import 'today_view.dart';

/// Owns loading and calendar navigation; rendering stays database independent.
class TodayPage extends StatefulWidget {
  const TodayPage({
    super.key,
    required this.store,
    required this.initialDate,
    required this.onDateChanged,
    required this.onOpenLesson,
  });

  final DaymarkStore store;
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TodayLesson> onOpenLesson;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  late DateTime _date;
  late Future<TodaySchedule> _schedule;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _date = calendarDay(widget.initialDate);
    _load();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _load() => _schedule = TodayRepository(widget.store).load(_date);

  void _select(DateTime date) {
    setState(() {
      _date = calendarDay(date);
      _load();
    });
    widget.onDateChanged(_date);
  }

  Future<void> _pickDate() async {
    final date = await showDaymarkDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
    );
    if (date != null && mounted) _select(date);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<TodaySchedule>(
    future: _schedule,
    builder: (context, snapshot) => TodayView(
      date: _date,
      now: DateTime.now(),
      // Do not display the previous day's data while a new date loads.
      schedule: snapshot.connectionState == ConnectionState.done
          ? snapshot.data
          : null,
      error:
          snapshot.connectionState == ConnectionState.done && snapshot.hasError
          ? 'Der Unterricht konnte nicht geladen werden.'
          : null,
      onPrevious: () => _select(calendarDay(_date, -1)),
      onNext: () => _select(calendarDay(_date, 1)),
      onToday: () => _select(DateTime.now()),
      onPickDate: _pickDate,
      onRetry: () => setState(_load),
      onOpenLesson: widget.onOpenLesson,
      notesPanel: DayNotesPanel(
        key: ValueKey(dayKey(_date)),
        store: widget.store,
        date: _date,
      ),
    ),
  );
}
