import 'package:flutter/material.dart';

import '../../domain/today_schedule.dart';
import '../theme/daymark_theme.dart';
import 'today_lesson_row.dart';

class TodayView extends StatelessWidget {
  const TodayView({
    super.key,
    required this.date,
    required this.now,
    required this.schedule,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onPickDate,
    required this.onOpenLesson,
    required this.onRetry,
    required this.notesPanel,
    this.error,
  });

  final DateTime date;
  final DateTime now;
  final TodaySchedule? schedule;
  final String? error;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onPickDate;
  final VoidCallback onRetry;
  final ValueChanged<TodayLesson> onOpenLesson;
  final Widget notesPanel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 32, 14, 34),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 22),
          child: Wrap(
            spacing: 10,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 30),
                child: Text(
                  'Heute',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
                ),
              ),
              _dateArrow('Voriger Tag', Icons.chevron_left, onPrevious),
              OutlinedButton(
                onPressed: onPickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        germanDayLabel(date),
                        style: TextStyle(
                          color: DaymarkColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 28),
                      Icon(Icons.calendar_today_outlined, size: 22),
                    ],
                  ),
                ),
              ),
              _dateArrow('Nächster Tag', Icons.chevron_right, onNext),
              const SizedBox(width: 2),
              OutlinedButton(
                onPressed: onToday,
                child: const Text('Heute', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Expanded(child: _body()),
      ],
    ),
  );

  Widget _dateArrow(String label, IconData icon, VoidCallback onPressed) =>
      Tooltip(
        message: label,
        child: SizedBox(
          width: 46,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
            child: Semantics(label: label, child: Icon(icon, size: 26)),
          ),
        ),
      );

  Widget _body() {
    final data = schedule;
    final today = _SchedulePanel(
      title: 'Unterricht',
      children: [
        if (error != null) ...[
          _DayNotice(error!),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: OutlinedButton(
              onPressed: onRetry,
              child: const Text('Erneut versuchen'),
            ),
          ),
        ] else if (data == null)
          const Padding(
            padding: EdgeInsets.all(26),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          if (data.reason != null) _DayNotice(data.reason!),
          if (data.lessons.isEmpty) const _DayNotice('Keine Stunde geplant.'),
          for (var index = 0; index < data.lessons.length; index++)
            TodayLessonRow(
              lesson: data.lessons[index],
              now: now,
              first: index == 0,
              last: index == data.lessons.length - 1,
              onOpen: () => onOpenLesson(data.lessons[index]),
            ),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return ListView(
            children: [
              today,
              const SizedBox(height: 12),
              SizedBox(height: 360, child: notesPanel),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 66, child: today),
            const SizedBox(width: 12),
            Expanded(flex: 34, child: notesPanel),
          ],
        );
      },
    );
  }
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: DaymarkColors.surface,
      border: Border.all(color: DaymarkColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 26, 26, 20),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 26),
              child: Divider(height: 1),
            ),
            ...children,
            const SizedBox(height: 24),
          ],
        );
        return constraints.hasBoundedHeight
            ? SingleChildScrollView(child: content)
            : content;
      },
    ),
  );
}

class _DayNotice extends StatelessWidget {
  const _DayNotice(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(26),
    child: Text(
      message,
      style: TextStyle(color: DaymarkColors.muted, fontSize: 18),
    ),
  );
}
