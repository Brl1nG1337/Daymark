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
  Widget build(BuildContext context) {
    final isToday = calendarDay(date) == calendarDay(now);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
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
                onPressed: isToday ? null : onToday,
                child: const Text('Heute', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Expanded(child: _body()),
        ],
      ),
    );
  }

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
        else if (data.lessons.isEmpty)
          _EmptySchedule(reason: data.reason)
        else ...[
          if (data.reason != null) _DayNotice(data.reason!),
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
            Expanded(flex: 68, child: today),
            const SizedBox(width: 16),
            Expanded(flex: 32, child: notesPanel),
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1),
            ),
            ...children,
            const SizedBox(height: 10),
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
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Text(
      message,
      style: TextStyle(color: DaymarkColors.muted, fontSize: 16),
    ),
  );
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final hasReason = reason != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 72, 32, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: DaymarkColors.activeSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasReason
                      ? Icons.beach_access_outlined
                      : Icons.event_busy_outlined,
                  size: 30,
                  color: DaymarkColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                reason ?? 'Keine Stunde geplant',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DaymarkColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasReason ? 'Für diesen Tag ist kein Unterricht geplant.' : 'Für diesen Tag sind keine Unterrichtsstunden eingetragen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DaymarkColors.muted,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
