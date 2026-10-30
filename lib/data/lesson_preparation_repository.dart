import '../domain/lesson_preparation.dart';
import 'daymark_store.dart';

class LessonPreparationRepository {
  const LessonPreparationRepository(this.store);

  final DaymarkStore store;

  Future<LessonPreparation> load({
    required int slotId,
    required DateTime day,
  }) async {
    final row = await store.lessonPreparation(slotId, dayKey(day));
    return LessonPreparation(
      slotId: slotId,
      day: DateTime(day.year, day.month, day.day),
      body: row?['body'] as String? ?? '',
    );
  }

  Future<void> save(LessonPreparation preparation) =>
      store.saveLessonPreparation(
        preparation.slotId,
        dayKey(preparation.day),
        preparation.body,
      );
}
