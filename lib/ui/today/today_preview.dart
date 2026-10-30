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
              ),
              onPrevious: _ignore,
              onNext: _ignore,
              onToday: _ignore,
              onPickDate: _ignore,
              onRetry: _ignore,
              onOpenLesson: _ignoreLesson,
              notesPanel: Container(
                decoration: BoxDecoration(
                  color: DaymarkColors.surface,
                  border: Border.all(color: DaymarkColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tagesnotizen',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Divider(height: 32),
                      Text('Elternabend vorbereiten'),
                      SizedBox(height: 20),
                      Text('Material für die nächste Stunde zusammenstellen'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
