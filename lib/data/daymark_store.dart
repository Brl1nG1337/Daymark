import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class DaymarkStore {
  DaymarkStore._(this.db);
  final DaymarkDatabase db;

  static Future<DaymarkStore> inMemory({DaymarkDatabase? database}) async {
    final store = DaymarkStore._(
      database ?? DaymarkDatabase(NativeDatabase.memory()),
    );
    await store.db.customStatement(
      'CREATE TABLE IF NOT EXISTS app_meta (id INTEGER PRIMARY KEY, version INTEGER NOT NULL)',
    );
    await store.db.customStatement(
      'INSERT OR IGNORE INTO app_meta VALUES (1, 1)',
    );
    await store._schema();
    return store;
  }

  static Future<DaymarkStore> open(String password) async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'daymark.sqlite'));
    final escaped = password.replaceAll("'", "''");
    final executor = NativeDatabase.createInBackground(
      file,
      setup: (raw) {
        raw.execute("PRAGMA key = '$escaped'");
        raw.execute('PRAGMA foreign_keys = ON');
      },
    );
    final store = DaymarkStore._(DaymarkDatabase(executor));
    try {
      await store.db.customStatement(
        'CREATE TABLE IF NOT EXISTS app_meta (id INTEGER PRIMARY KEY, version INTEGER NOT NULL)',
      );
      await store.db.customStatement(
        'INSERT OR IGNORE INTO app_meta VALUES (1, 1)',
      );
      await store._schema();
      return store;
    } catch (_) {
      await store.db.close();
      throw const FormatException(
        'Passwort falsch oder Datenbank nicht lesbar.',
      );
    }
  }

  Future<void> _schema() async {
    for (final sql in [
      'CREATE TABLE IF NOT EXISTS classes (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE)',
      'CREATE TABLE IF NOT EXISTS students (id INTEGER PRIMARY KEY, first_name TEXT NOT NULL, last_name TEXT NOT NULL)',
      'CREATE TABLE IF NOT EXISTS enrollments (id INTEGER PRIMARY KEY, class_id INTEGER NOT NULL REFERENCES classes(id), student_id INTEGER NOT NULL REFERENCES students(id), start_date TEXT NOT NULL, end_date TEXT)',
      'CREATE TABLE IF NOT EXISTS slots (id INTEGER PRIMARY KEY, class_id INTEGER NOT NULL REFERENCES classes(id), subject TEXT NOT NULL, weekday INTEGER NOT NULL, period INTEGER NOT NULL, start_time TEXT, valid_from TEXT NOT NULL, valid_to TEXT)',
      'CREATE TABLE IF NOT EXISTS free_days (day TEXT PRIMARY KEY, label TEXT NOT NULL)',
      'CREATE TABLE IF NOT EXISTS lessons (id INTEGER PRIMARY KEY, slot_id INTEGER REFERENCES slots(id), class_id INTEGER NOT NULL REFERENCES classes(id), subject TEXT NOT NULL, period INTEGER NOT NULL, day TEXT NOT NULL, completed INTEGER NOT NULL DEFAULT 0, UNIQUE(slot_id, day))',
      'CREATE TABLE IF NOT EXISTS attendance (lesson_id INTEGER NOT NULL REFERENCES lessons(id), student_id INTEGER NOT NULL REFERENCES students(id), status TEXT NOT NULL DEFAULT \'present\', PRIMARY KEY(lesson_id, student_id))',
      'CREATE TABLE IF NOT EXISTS notes (id INTEGER PRIMARY KEY, lesson_id INTEGER NOT NULL REFERENCES lessons(id), student_id INTEGER NOT NULL REFERENCES students(id), body TEXT NOT NULL, created_at TEXT NOT NULL)',
      'CREATE INDEX IF NOT EXISTS idx_lessons_day ON lessons(day)',
      'CREATE INDEX IF NOT EXISTS idx_notes_student ON notes(student_id)',
    ]) {
      await db.customStatement(sql);
    }
    final columns = (await rows('PRAGMA table_info(lessons)'))
        .map((row) => row['name'])
        .toSet();
    for (final column in ['started_at', 'topic', 'summary', 'homework']) {
      if (!columns.contains(column)) {
        await db.customStatement('ALTER TABLE lessons ADD COLUMN $column TEXT');
      }
    }
    await db.customStatement('UPDATE app_meta SET version=2 WHERE id=1');
  }

  Future<List<Map<String, Object?>>> rows(
    String sql, [
    List<Object?> args = const [],
  ]) async =>
      (await db
              .customSelect(sql, variables: args.map(Variable.new).toList())
              .get())
          .map((r) => r.data)
          .toList();

  Future<void> addClass(String name) async =>
      db.customStatement('INSERT INTO classes(name) VALUES (?)', [name.trim()]);
  Future<void> addStudent(int classId, String first, String last) async {
    await db.transaction(() async {
      await db.customStatement(
        'INSERT INTO students(first_name,last_name) VALUES (?,?)',
        [first.trim(), last.trim()],
      );
      final id = (await rows('SELECT last_insert_rowid() id')).single['id'];
      await db.customStatement(
        'INSERT INTO enrollments(class_id,student_id,start_date) VALUES (?,?,?)',
        [classId, id, dayKey(DateTime.now())],
      );
    });
  }

  Future<void> addSlot(
    int classId,
    String subject,
    int weekday,
    int period,
    String? time,
    String from,
  ) async => db.customStatement(
    'INSERT INTO slots(class_id,subject,weekday,period,start_time,valid_from) VALUES (?,?,?,?,?,?)',
    [classId, subject.trim(), weekday, period, time, from],
  );
  Future<void> endSlot(int slotId, String end) async => db.customStatement(
    'UPDATE slots SET valid_to=? WHERE id=?',
    [end, slotId],
  );
  Future<void> addFreeDay(String day, String label) async => db.customStatement(
    'INSERT OR REPLACE INTO free_days(day,label) VALUES (?,?)',
    [day, label],
  );
  Future<void> removeFreeDay(String day) async =>
      db.customStatement('DELETE FROM free_days WHERE day=?', [day]);
  Future<List<Map<String, Object?>>> classes() =>
      rows('SELECT * FROM classes ORDER BY name COLLATE NOCASE');
  Future<List<Map<String, Object?>>> students(int classId, String day) => rows(
    'SELECT s.* FROM students s JOIN enrollments e ON e.student_id=s.id WHERE e.class_id=? AND e.start_date<=? AND (e.end_date IS NULL OR e.end_date>=?) ORDER BY s.last_name COLLATE NOCASE,s.first_name COLLATE NOCASE',
    [classId, day, day],
  );
  Future<List<Map<String, Object?>>> slotsFor(DateTime day) => rows(
    'SELECT sl.*, c.name class_name FROM slots sl JOIN classes c ON c.id=sl.class_id WHERE weekday=? AND valid_from<=? AND (valid_to IS NULL OR valid_to>=?) ORDER BY period, start_time',
    [day.weekday, dayKey(day), dayKey(day)],
  );
  Future<List<Map<String, Object?>>> slots() => rows(
    'SELECT sl.*, c.name class_name FROM slots sl JOIN classes c ON c.id=sl.class_id ORDER BY weekday,period',
  );
  Future<List<Map<String, Object?>>> weekEntries(DateTime monday) async {
    final days = await Future.wait([
      for (var offset = 0; offset < 5; offset++)
        dayEntries(DateTime(monday.year, monday.month, monday.day + offset)),
    ]);
    return days.expand((entries) => entries).toList();
  }

  Future<List<Map<String, Object?>>> dayEntries(DateTime day) async {
    final key = dayKey(day);
    final slotsOnDay = await slotsFor(day);
    final existing = await rows(
      'SELECT l.*, c.name class_name, sl.start_time FROM lessons l '
      'JOIN classes c ON c.id=l.class_id LEFT JOIN slots sl ON sl.id=l.slot_id '
      'WHERE l.day=? ORDER BY l.period',
      [key],
    );
    final bySlot = {for (final lesson in existing) lesson['slot_id']: lesson};
    final slotIds = slotsOnDay.map((slot) => slot['id']).toSet();
    final result = <Map<String, Object?>>[
      for (final slot in slotsOnDay)
        {
          ...slot,
          if (bySlot[slot['id']] case final lesson?) ...{
            'subject': lesson['subject'],
            'period': lesson['period'],
            'class_id': lesson['class_id'],
            'class_name': lesson['class_name'],
          },
          'day': key,
          'lesson_id': bySlot[slot['id']]?['id'],
          'completed': bySlot[slot['id']]?['completed'],
        },
      for (final lesson in existing)
        if (!slotIds.contains(lesson['slot_id']))
          {...lesson, 'id': lesson['slot_id'], 'lesson_id': lesson['id']},
    ];
    result.sort((a, b) {
      final byPeriod = (a['period'] as int).compareTo(b['period'] as int);
      return byPeriod != 0
          ? byPeriod
          : '${a['start_time'] ?? ''}'.compareTo('${b['start_time'] ?? ''}');
    });
    return result;
  }

  Future<List<Map<String, Object?>>> freeDays() =>
      rows('SELECT * FROM free_days ORDER BY day');
  Future<int> openLesson(Map<String, Object?> slot, String day) async {
    return db.transaction(() async {
      await db.customStatement(
        'INSERT OR IGNORE INTO lessons(slot_id,class_id,subject,period,day) VALUES (?,?,?,?,?)',
        [slot['id'], slot['class_id'], slot['subject'], slot['period'], day],
      );
      final lesson = (await rows(
        'SELECT id FROM lessons WHERE slot_id=? AND day=?',
        [slot['id'], day],
      )).single;
      final id = lesson['id'] as int;
      await db.customStatement(
        'UPDATE lessons SET started_at=COALESCE(started_at, ?) WHERE id=?',
        [DateTime.now().toIso8601String(), id],
      );
      for (final student in await students(slot['class_id'] as int, day)) {
        await db.customStatement(
          "INSERT OR IGNORE INTO attendance(lesson_id,student_id,status) VALUES (?,?,'present')",
          [id, student['id']],
        );
      }
      return id;
    });
  }

  Future<Map<String, Object?>> lesson(int id) async => (await rows(
    'SELECT l.*,c.name class_name,sl.start_time FROM lessons l '
    'JOIN classes c ON c.id=l.class_id LEFT JOIN slots sl ON sl.id=l.slot_id '
    'WHERE l.id=?',
    [id],
  )).single;
  Future<void> updateLessonDetails(
    int id,
    String topic,
    String summary,
    String homework,
  ) => db.customStatement(
    'UPDATE lessons SET topic=?,summary=?,homework=? WHERE id=?',
    [topic.trim(), summary.trim(), homework.trim(), id],
  );
  Future<List<Map<String, Object?>>> attendance(int lessonId) => rows(
    'SELECT a.*,s.first_name,s.last_name FROM attendance a JOIN students s ON s.id=a.student_id WHERE a.lesson_id=? ORDER BY s.last_name COLLATE NOCASE,s.first_name COLLATE NOCASE',
    [lessonId],
  );
  Future<void> setAttendance(
    int lessonId,
    int studentId,
    String status,
  ) async => db.customStatement(
    'UPDATE attendance SET status=? WHERE lesson_id=? AND student_id=?',
    [status, lessonId, studentId],
  );
  Future<void> complete(int lessonId) async => db.customStatement(
    'UPDATE lessons SET completed=1 WHERE id=?',
    [lessonId],
  );
  Future<void> reopen(int lessonId) async => db.customStatement(
    'UPDATE lessons SET completed=0 WHERE id=?',
    [lessonId],
  );
  Future<void> addNote(
    int lessonId,
    int studentId,
    String body,
  ) async => db.customStatement(
    'INSERT INTO notes(lesson_id,student_id,body,created_at) VALUES (?,?,?,?)',
    [lessonId, studentId, body.trim(), DateTime.now().toIso8601String()],
  );
  Future<void> updateNote(int id, String body) async => db.customStatement(
    'UPDATE notes SET body=? WHERE id=?',
    [body.trim(), id],
  );
  Future<void> deleteNote(int id) async =>
      db.customStatement('DELETE FROM notes WHERE id=?', [id]);
  Future<List<Map<String, Object?>>> notes(int lessonId) => rows(
    'SELECT n.*,s.first_name,s.last_name FROM notes n JOIN students s ON s.id=n.student_id WHERE lesson_id=? ORDER BY created_at DESC',
    [lessonId],
  );
  Future<List<Map<String, Object?>>> history(int studentId) => rows(
    'SELECT l.day,l.subject,l.period,a.status,(SELECT GROUP_CONCAT(body, \' · \') FROM notes n WHERE n.lesson_id=l.id AND n.student_id=a.student_id) body FROM lessons l JOIN attendance a ON a.lesson_id=l.id AND a.student_id=? WHERE l.completed=1 ORDER BY l.day DESC,l.period DESC',
    [studentId],
  );
  Future<void> close() => db.close();
}

class DaymarkDatabase extends GeneratedDatabase {
  DaymarkDatabase(super.executor);
  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from != 1 || to != 2) {
        throw StateError('Nicht unterstützte Datenbankmigration: $from → $to');
      }
      // Drift checks user_version before the store can initialize its SQL schema.
      await transaction(() => DaymarkStore._(this)._schema());
    },
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
}
