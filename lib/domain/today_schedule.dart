/// A scheduled lesson independent of database rows and Flutter widgets.
class TodayLesson {
  const TodayLesson({
    required this.slotId,
    required this.classId,
    required this.className,
    required this.subject,
    required this.period,
    required this.day,
    this.startTime,
    this.lessonId,
    this.completed = false,
  });

  final int? slotId;
  final int classId;
  final String className;
  final String subject;
  final int period;
  final DateTime day;
  final String? startTime;
  final int? lessonId;
  final bool completed;

  DateTime? get startsAt {
    final parts = startTime?.split(':');
    if (parts == null || parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  // The current timetable stores a start time only. A lesson lasts 45 minutes.
  DateTime? get endsAt => startsAt?.add(const Duration(minutes: 45));

  bool isCurrent(DateTime now) {
    final start = startsAt;
    final end = endsAt;
    return !completed &&
        start != null &&
        end != null &&
        !now.isBefore(start) &&
        now.isBefore(end);
  }
}

class TodaySchedule {
  TodaySchedule({required List<TodayLesson> lessons, this.reason})
    : lessons = List.unmodifiable(lessons);

  final List<TodayLesson> lessons;
  final String? reason;
}

DateTime calendarDay(DateTime date, [int offset = 0]) =>
    DateTime(date.year, date.month, date.day + offset);

String germanDayLabel(DateTime date) {
  const weekdays = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];
  const months = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day}. ${months[date.month - 1]}';
}

String lessonTime(DateTime? time) => time == null
    ? '–'
    : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
