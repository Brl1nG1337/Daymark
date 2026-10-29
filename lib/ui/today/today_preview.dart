import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../domain/today_schedule.dart';
import '../daymark_sidebar.dart';
import '../theme/daymark_theme.dart';
import 'today_view.dart';

void _ignore() {}
void _ignoreLesson(TodayLesson lesson) {}

@Preview(name: 'Heute · Desktop', size: Size(1586, 992))
Widget todayDesktopPreview() {
  final date = DateTime(2026, 5, 12);
  const subjects = [
    'Mathematik',
    'Deutsch',
    'Englisch',
    'Geschichte',
    'Mathematik',
    'Politik',
  ];
  const classes = ['8a', '7c', '8b', '9a', '7a', '10b'];
  const times = ['08:00', '08:55', '09:55', '10:55', '11:50', '12:45'];
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: daymarkTheme(),
    home: Scaffold(
      body: Row(
        children: [
          DaymarkSidebar(selectedIndex: 0, onSelected: (_) {}),
          Expanded(
            child: TodayView(
              date: date,
              now: DateTime(2026, 5, 12, 10),
              schedule: TodaySchedule(
                lessons: [
                  for (var i = 0; i < subjects.length; i++)
                    TodayLesson(
                      slotId: i,
                      classId: i,
                      className: classes[i],
                      subject: subjects[i],
                      period: i + 1,
                      day: date,
                      startTime: times[i],
                      completed: i < 2,
                    ),
                ],
                tomorrow: [
                  for (var i = 0; i < 2; i++)
                    TodayLesson(
                      slotId: i,
                      classId: i,
                      className: i == 0 ? '8b' : '7b',
                      subject: i == 0 ? 'Mathematik' : 'Englisch',
                      period: i + 1,
                      day: calendarDay(date, 1),
                      startTime: times[i],
                    ),
                ],
              ),
              onPrevious: _ignore,
              onNext: _ignore,
              onToday: _ignore,
              onPickDate: _ignore,
              onRetry: _ignore,
              onOpenLesson: _ignoreLesson,
            ),
          ),
        ],
      ),
    ),
  );
}
