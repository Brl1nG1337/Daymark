import 'package:flutter/material.dart';

import '../../domain/today_schedule.dart';
import '../theme/daymark_theme.dart';

class TodayLessonRow extends StatelessWidget {
  const TodayLessonRow({
    super.key,
    required this.lesson,
    required this.now,
    required this.first,
    required this.last,
    required this.onOpen,
  });

  final TodayLesson lesson;
  final DateTime now;
  final bool first;
  final bool last;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final current = lesson.isCurrent(now);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        final status = lesson.completed
            ? 'Abgeschlossen'
            : lesson.lessonId != null
            ? 'Begonnen'
            : 'Geplant';
        return Material(
          color: current ? DaymarkColors.activeSurface : Colors.transparent,
          child: InkWell(
            onTap: onOpen,
            child: Semantics(
              button: true,
              label:
                  '${lesson.period}. Stunde, ${lesson.className}, ${lesson.subject}, $status',
              child: Container(
                constraints: const BoxConstraints(minHeight: 115),
                margin: const EdgeInsets.symmetric(horizontal: 26),
                decoration: BoxDecoration(
                  border: last
                      ? null
                      : const Border(
                          bottom: BorderSide(color: DaymarkColors.border),
                        ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: compact ? 66 : 88,
                      child: Text(
                        '${lessonTime(lesson.startsAt)}\n${lessonTime(lesson.endsAt)}',
                        style: TextStyle(
                          fontSize: compact ? 16 : 20,
                          height: 1.4,
                          color: current
                              ? DaymarkColors.active
                              : DaymarkColors.muted,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      height: 114,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: first ? 57 : 0,
                            bottom: last ? 57 : 0,
                            child: Container(
                              width: 1,
                              color: current
                                  ? const Color(0xffa6d6ff)
                                  : DaymarkColors.border,
                            ),
                          ),
                          Container(
                            width: current ? 23 : 20,
                            height: current ? 23 : 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: DaymarkColors.surface,
                              border: Border.all(
                                color: current
                                    ? DaymarkColors.active
                                    : DaymarkColors.muted,
                                width: current ? 5 : 2.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: compact ? 14 : 27),
                    if (!compact) ...[
                      SizedBox(
                        width: 34,
                        child: lesson.completed
                            ? const Icon(
                                Icons.check_circle,
                                color: DaymarkColors.success,
                                size: 32,
                              )
                            : null,
                      ),
                      const SizedBox(width: 38),
                    ],
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${lesson.period}. Stunde',
                              style: TextStyle(
                                fontSize: compact ? 18 : 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: lesson.className),
                                  TextSpan(
                                    text: '  ·  ${lesson.subject}',
                                    style: const TextStyle(
                                      color: DaymarkColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                              style: TextStyle(fontSize: compact ? 17 : 21),
                            ),
                            if (compact) ...[
                              const SizedBox(height: 8),
                              Text(
                                current ? 'Öffnen' : status,
                                style: TextStyle(
                                  color: lesson.completed
                                      ? DaymarkColors.success
                                      : DaymarkColors.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 12),
                      if (current)
                        FilledButton.icon(
                          onPressed: onOpen,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(160, 56),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 30),
                          label: const Text(
                            'Öffnen',
                            style: TextStyle(fontSize: 20),
                          ),
                        )
                      else
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 18,
                            color: lesson.completed
                                ? DaymarkColors.success
                                : DaymarkColors.muted,
                          ),
                        ),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TomorrowLessonTile extends StatelessWidget {
  const TomorrowLessonTile({
    super.key,
    required this.lesson,
    required this.onOpen,
  });
  final TodayLesson lesson;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 25),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: DaymarkColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${lesson.period}. Stunde',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '${lessonTime(lesson.startsAt)} – ${lessonTime(lesson.endsAt)}',
                style: const TextStyle(
                  fontSize: 21,
                  color: DaymarkColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: lesson.className),
                    TextSpan(
                      text: '  ·  ${lesson.subject}',
                      style: const TextStyle(color: DaymarkColors.muted),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 21),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
