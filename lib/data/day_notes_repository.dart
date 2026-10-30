import '../domain/day_note.dart';
import 'daymark_store.dart';

class DayNotesRepository {
  const DayNotesRepository(this.store);

  final DaymarkStore store;

  Future<List<DayNote>> forDay(DateTime date) async => [
    for (final row in await store.dayNotes(dayKey(date)))
      DayNote(
        id: row['id'] as int,
        day: row['day'] as String,
        body: row['body'] as String,
      ),
  ];

  Future<void> add(DateTime date, String body) =>
      store.addDayNote(dayKey(date), body);

  Future<void> update(DayNote note, String body) =>
      store.updateDayNote(note.id, body);

  Future<void> delete(DayNote note) => store.deleteDayNote(note.id);
}
