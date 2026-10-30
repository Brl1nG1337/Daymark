import 'package:daymark/data/daymark_store.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('upgrades a legacy lesson without losing its data', () async {
    final database = DaymarkDatabase(NativeDatabase.memory());
    await database.customStatement(
      'CREATE TABLE classes (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE)',
    );
    await database.customStatement(
      'CREATE TABLE slots (id INTEGER PRIMARY KEY, class_id INTEGER NOT NULL, subject TEXT NOT NULL, weekday INTEGER NOT NULL, period INTEGER NOT NULL, start_time TEXT, valid_from TEXT NOT NULL, valid_to TEXT)',
    );
    await database.customStatement(
      'CREATE TABLE lessons (id INTEGER PRIMARY KEY, slot_id INTEGER, class_id INTEGER NOT NULL, subject TEXT NOT NULL, period INTEGER NOT NULL, day TEXT NOT NULL, completed INTEGER NOT NULL DEFAULT 0, UNIQUE(slot_id, day))',
    );
    await database.customStatement("INSERT INTO classes VALUES (1, '3a')");
    await database.customStatement(
      "INSERT INTO slots VALUES (1,1,'Mathe',1,2,'09:00','2026-01-01',NULL)",
    );
    await database.customStatement(
      "INSERT INTO lessons VALUES (1,1,1,'Mathe',2,'2026-11-02',1)",
    );
    final store = await DaymarkStore.inMemory(database: database);
    addTearDown(store.close);
    expect((await store.lesson(1))['completed'], 1);
    await store.updateLessonDetails(1, 'Brüche', '', '');
    expect((await store.lesson(1))['topic'], 'Brüche');
    expect(
      (await store.rows('SELECT version FROM app_meta')).single['version'],
      4,
    );
  });

  group('dated lessons', () {
    late DaymarkStore store;
    setUp(() async {
      store = await DaymarkStore.inMemory();
      await store.addClass('3a');
      await store.addStudent(1, 'Erika', 'Muster');
      await store.addSlot(1, 'Mathe', 1, 2, '09:00', '2026-01-01');
    });
    tearDown(() async => store.close());

    test(
      'week preview does not create a lesson; starting is idempotent',
      () async {
        final monday = DateTime(2026, 11, 2);
        final preview = await store.weekEntries(monday);
        expect(preview, hasLength(1));
        expect(preview.single['lesson_id'], isNull);
        final first = await store.openLesson(preview.single, '2026-11-02');
        final second = await store.openLesson(preview.single, '2026-11-02');
        expect(second, first);
        expect((await store.weekEntries(monday)).single['lesson_id'], first);
        expect((await store.attendance(first)), hasLength(1));
        expect((await store.lesson(first))['started_at'], isNotNull);
      },
    );

    test(
      'details and completion survive reopening and a changed slot',
      () async {
        final monday = DateTime(2026, 11, 2);
        final slot = (await store.weekEntries(monday)).single;
        final id = await store.openLesson(slot, '2026-11-02');
        await store.updateLessonDetails(
          id,
          ' Brüche ',
          ' Übungen ',
          ' Seite 4 ',
        );
        await store.complete(id);
        await store.endSlot(1, '2026-11-01');
        final saved = (await store.weekEntries(monday)).single;
        expect(saved['lesson_id'], id);
        expect(saved['completed'], 1);
        expect((await store.lesson(id))['topic'], 'Brüche');
        await store.reopen(id);
        expect((await store.lesson(id))['completed'], 0);
      },
    );
  });
}
