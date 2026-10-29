import '../domain/school_calendar.dart';
import '../domain/today_schedule.dart';
import 'daymark_store.dart';

/// Adapts the existing SQLite store to typed data for the Today screen.
class TodayRepository {
  const TodayRepository(this.store);

  final DaymarkStore store;

  Future<TodaySchedule> load(DateTime date) async {
    final tomorrow = calendarDay(date, 1);
    final (todayRows, tomorrowRows, freeDays) = await (
      store.dayEntries(date),
      store.dayEntries(tomorrow),
      store.freeDays(),
    ).wait;
    final days = freeDays.map((row) => row['day'] as String).toSet();
    String? reason(DateTime day) {
      for (final row in freeDays) {
        if (row['day'] == dayKey(day)) return row['label'] as String;
      }
      return SchoolCalendar.reason(day, days);
    }

    return TodaySchedule(
      lessons: todayRows.map(_lesson).toList(),
      tomorrow: tomorrowRows.map(_lesson).toList(),
      reason: reason(date),
      tomorrowReason: reason(tomorrow),
    );
  }

  TodayLesson _lesson(Map<String, Object?> row) => TodayLesson(
    slotId: row['id'] as int?,
    classId: row['class_id'] as int,
    className: row['class_name'] as String,
    subject: row['subject'] as String,
    period: row['period'] as int,
    day: DateTime.parse(row['day'] as String),
    startTime: row['start_time'] as String?,
    lessonId: row['lesson_id'] as int?,
    completed: row['completed'] == 1,
  );
}
