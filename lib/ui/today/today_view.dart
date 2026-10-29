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
                        style: const TextStyle(
                          color: DaymarkColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 28),
                      const Icon(Icons.calendar_today_outlined, size: 22),
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
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }
    final data = schedule;
    if (data == null) return const Center(child: CircularProgressIndicator());
    final today = _SchedulePanel(
      title: 'Unterricht',
      children: [
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
    );
    final tomorrow = _SchedulePanel(
      title: 'Morgen',
      subtitle: germanDayLabel(calendarDay(date, 1)),
      children: [
        if (data.tomorrowReason != null) _DayNotice(data.tomorrowReason!),
        if (data.tomorrow.isEmpty) const _DayNotice('Keine Stunde geplant.'),
        for (final lesson in data.tomorrow)
          TomorrowLessonTile(
            lesson: lesson,
            onOpen: () => onOpenLesson(lesson),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return ListView(
            children: [today, const SizedBox(height: 12), tomorrow],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 66, child: today),
            const SizedBox(width: 12),
            Expanded(flex: 34, child: tomorrow),
          ],
        );
      },
    );
  }
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel({
    required this.title,
    required this.children,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
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
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 18,
                        color: DaymarkColors.muted,
                      ),
                    ),
                ],
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
      style: const TextStyle(color: DaymarkColors.muted, fontSize: 18),
    ),
  );
}
