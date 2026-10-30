import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class DaymarkStore {
  DaymarkStore._(this.db, [this._file]);
  final DaymarkDatabase db;
  final File? _file;
  bool _closed = false;
  bool get isClosed => _closed;

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
    return openFile(file, password);
  }

  static Future<DaymarkStore> openFile(File file, String password) async {
    await file.parent.create(recursive: true);
    final escaped = password.replaceAll("'", "''");
    final executor = NativeDatabase.createInBackground(
      file,
      setup: (raw) {
        raw.execute("PRAGMA key = '$escaped'");
        raw.execute('PRAGMA foreign_keys = ON');
      },
    );
    final store = DaymarkStore._(DaymarkDatabase(executor), file);
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
      'CREATE TABLE IF NOT EXISTS day_notes (id INTEGER PRIMARY KEY, day TEXT NOT NULL, body TEXT NOT NULL, created_at TEXT NOT NULL)',
      'CREATE INDEX IF NOT EXISTS idx_day_notes_day ON day_notes(day, created_at)',
      'CREATE TABLE IF NOT EXISTS lesson_preparations (slot_id INTEGER NOT NULL REFERENCES slots(id), day TEXT NOT NULL, body TEXT NOT NULL, updated_at TEXT NOT NULL, PRIMARY KEY(slot_id, day))',
      'CREATE INDEX IF NOT EXISTS idx_lessons_day ON lessons(day)',
      'CREATE INDEX IF NOT EXISTS idx_notes_student ON notes(student_id)',
      'CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
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
    await db.transaction(() async {
      await db.customStatement(
        'UPDATE notes SET body=('
        'SELECT GROUP_CONCAT(body, char(10) || char(10)) FROM ('
        'SELECT duplicate.body FROM notes duplicate '
        'WHERE duplicate.lesson_id=notes.lesson_id '
        'AND duplicate.student_id=notes.student_id '
        'ORDER BY duplicate.created_at,duplicate.id)) '
        'WHERE id IN (SELECT MAX(id) FROM notes GROUP BY lesson_id,student_id)',
      );
      await db.customStatement(
        'DELETE FROM notes WHERE id NOT IN ('
        'SELECT MAX(id) FROM notes GROUP BY lesson_id,student_id)',
      );
      await db.customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_notes_lesson_student '
        'ON notes(lesson_id,student_id)',
      );
      await db.customStatement('UPDATE app_meta SET version=6 WHERE id=1');
    });
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
  Future<List<Map<String, Object?>>> dayNotes(String day) => rows(
    'SELECT id, day, body, created_at FROM day_notes WHERE day=? ORDER BY created_at DESC, id DESC',
    [day],
  );
  Future<void> addDayNote(String day, String body) => db.customStatement(
    'INSERT INTO day_notes(day, body, created_at) VALUES (?, ?, ?)',
    [day, body.trim(), DateTime.now().toUtc().toIso8601String()],
  );
  Future<void> updateDayNote(int id, String body) => db.customStatement(
    'UPDATE day_notes SET body=? WHERE id=?',
    [body.trim(), id],
  );
  Future<void> deleteDayNote(int id) =>
      db.customStatement('DELETE FROM day_notes WHERE id=?', [id]);
  Future<Map<String, Object?>?> lessonPreparation(
    int slotId,
    String day,
  ) async {
    final result = await rows(
      'SELECT slot_id, day, body, updated_at FROM lesson_preparations WHERE slot_id=? AND day=?',
      [slotId, day],
    );
    return result.firstOrNull;
  }

  Future<void> saveLessonPreparation(
    int slotId,
    String day,
    String body,
  ) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      await db.customStatement(
        'DELETE FROM lesson_preparations WHERE slot_id=? AND day=?',
        [slotId, day],
      );
      return;
    }
    await db.customStatement(
      'INSERT INTO lesson_preparations(slot_id,day,body,updated_at) VALUES (?,?,?,?) '
      'ON CONFLICT(slot_id,day) DO UPDATE SET body=excluded.body,updated_at=excluded.updated_at',
      [slotId, day, trimmed, DateTime.now().toUtc().toIso8601String()],
    );
  }

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
  Future<void> undoLessonStart(int lessonId) async {
    await db.transaction(() async {
      final lesson = (await rows('SELECT completed FROM lessons WHERE id=?', [
        lessonId,
      ])).single;
      if (lesson['completed'] == 1) {
        throw StateError(
          'Eine abgeschlossene Stunde kann nicht zurückgesetzt werden.',
        );
      }
      await db.customStatement('DELETE FROM notes WHERE lesson_id=?', [
        lessonId,
      ]);
      await db.customStatement('DELETE FROM attendance WHERE lesson_id=?', [
        lessonId,
      ]);
      await db.customStatement('DELETE FROM lessons WHERE id=?', [lessonId]);
    });
  }

  Future<void> addNote(int lessonId, int studentId, String body) async =>
      saveStudentLessonNote(lessonId, studentId, body);

  Future<int?> saveStudentLessonNote(
    int lessonId,
    int studentId,
    String body,
  ) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      await db.customStatement(
        'DELETE FROM notes WHERE lesson_id=? AND student_id=?',
        [lessonId, studentId],
      );
      return null;
    }
    await db.customStatement(
      'INSERT INTO notes(lesson_id,student_id,body,created_at) VALUES (?,?,?,?) '
      'ON CONFLICT(lesson_id,student_id) DO UPDATE SET body=excluded.body',
      [lessonId, studentId, trimmed, DateTime.now().toIso8601String()],
    );
    final row = (await rows(
      'SELECT id FROM notes WHERE lesson_id=? AND student_id=?',
      [lessonId, studentId],
    )).single;
    return row['id'] as int;
  }

  Future<Map<String, Object?>?> studentLessonNote(
    int lessonId,
    int studentId,
  ) async => (await rows(
    'SELECT n.*,s.first_name,s.last_name FROM notes n '
    'JOIN students s ON s.id=n.student_id '
    'WHERE lesson_id=? AND student_id=?',
    [lessonId, studentId],
  )).firstOrNull;
  Future<List<Map<String, Object?>>> notes(int lessonId) => rows(
    'SELECT n.*,s.first_name,s.last_name FROM notes n JOIN students s ON s.id=n.student_id WHERE lesson_id=? ORDER BY created_at DESC',
    [lessonId],
  );
  Future<void> renameClass(int id, String name) => db.customStatement(
    'UPDATE classes SET name=? WHERE id=?',
    [name.trim(), id],
  );
  Future<void> renameStudent(int id, String first, String last) =>
      db.customStatement(
        'UPDATE students SET first_name=?,last_name=? WHERE id=?',
        [first.trim(), last.trim(), id],
      );
  Future<void> updateSlot(
    int id,
    int classId,
    String subject,
    int weekday,
    int period,
    String? time,
    String from,
    String? to,
  ) async {
    await db.transaction(() async {
      final latest = await rows(
        'SELECT MAX(day) last_day FROM lessons WHERE slot_id=?',
        [id],
      );
      final lastDay = latest.single['last_day'] as String?;
      if (lastDay == null) {
        await db.customStatement(
          'UPDATE slots SET class_id=?,subject=?,weekday=?,period=?,start_time=?,valid_from=?,valid_to=? WHERE id=?',
          [classId, subject.trim(), weekday, period, time, from, to, id],
        );
        return;
      }
      final afterLast = dayKey(
        DateTime.parse(lastDay).add(const Duration(days: 1)),
      );
      final effectiveFrom = from.compareTo(afterLast) < 0 ? afterLast : from;
      if (to != null && to.compareTo(effectiveFrom) < 0) {
        throw const FormatException(
          'Das Ende liegt vor dem neuen Gültigkeitsbeginn.',
        );
      }
      final previousEnd = dayKey(
        DateTime.parse(effectiveFrom).subtract(const Duration(days: 1)),
      );
      final oldTo =
          (await rows('SELECT valid_to FROM slots WHERE id=?', [
                id,
              ])).single['valid_to']
              as String?;
      final boundedEnd = oldTo != null && oldTo.compareTo(previousEnd) < 0
          ? oldTo
          : previousEnd;
      await db.customStatement('UPDATE slots SET valid_to=? WHERE id=?', [
        boundedEnd,
        id,
      ]);
      await db.customStatement(
        'INSERT INTO slots(class_id,subject,weekday,period,start_time,valid_from,valid_to) VALUES (?,?,?,?,?,?,?)',
        [classId, subject.trim(), weekday, period, time, effectiveFrom, to],
      );
    });
  }

  Future<List<Map<String, Object?>>> searchStudents(String query, String day) =>
      rows(
        'SELECT s.id,s.first_name,s.last_name,c.id class_id,c.name class_name FROM students s JOIN enrollments e ON e.student_id=s.id JOIN classes c ON c.id=e.class_id WHERE e.start_date<=? AND (e.end_date IS NULL OR e.end_date>=?) AND (s.first_name LIKE ? OR s.last_name LIKE ?) ORDER BY s.last_name COLLATE NOCASE,s.first_name COLLATE NOCASE',
        [day, day, '%$query%', '%$query%'],
      );
  Future<List<Map<String, Object?>>> studentAttendance(int studentId) => rows(
    'SELECT l.id lesson_id,l.day,l.period,l.subject,a.status FROM attendance a JOIN lessons l ON l.id=a.lesson_id WHERE a.student_id=? AND l.completed=1 ORDER BY l.day DESC,l.period DESC',
    [studentId],
  );
  Future<List<Map<String, Object?>>> studentNotes(int studentId) => rows(
    'SELECT n.id,n.body,n.lesson_id,l.day,l.period,l.subject,l.completed FROM notes n JOIN lessons l ON l.id=n.lesson_id WHERE n.student_id=? ORDER BY l.day DESC,l.period DESC,n.created_at DESC',
    [studentId],
  );
  Future<List<Map<String, Object?>>> classAttendanceSummary(
    int classId,
    String from,
    String to,
  ) => rows(
    'SELECT a.student_id,a.status,l.day FROM attendance a JOIN lessons l ON l.id=a.lesson_id WHERE l.class_id=? AND l.completed=1 AND l.day>=? AND l.day<=?',
    [classId, from, to],
  );
  Future<String?> setting(String key) async {
    final result = await rows('SELECT value FROM app_settings WHERE key=?', [
      key,
    ]);
    return result.isEmpty ? null : result.single['value'] as String;
  }

  Future<void> setSetting(String key, String value) => db.customStatement(
    'INSERT INTO app_settings(key,value) VALUES (?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value',
    [key, value],
  );
  Future<void> setPeriodTimes(List<String> starts) async {
    if (starts.length != 8 ||
        starts.any(
          (start) => !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(start),
        )) {
      throw const FormatException('Unterrichtszeiten sind ungültig.');
    }
    final startMinutes = starts.map((start) {
      final parts = start.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }).toList();
    for (var index = 1; index < startMinutes.length; index++) {
      if (startMinutes[index] < startMinutes[index - 1] + 45) {
        throw const FormatException(
          'Unterrichtszeiten dürfen sich nicht überschneiden.',
        );
      }
    }
    await db.transaction(() async {
      for (var index = 0; index < starts.length; index++) {
        await setSetting('period_${index + 1}', starts[index]);
      }
    });
  }

  Future<void> changePassword(String newPassword) async {
    if (newPassword.isEmpty) {
      throw const FormatException('Passwort darf nicht leer sein.');
    }
    final escaped = newPassword.replaceAll("'", "''");
    await db.customStatement("PRAGMA rekey = '$escaped'");
  }

  Future<void> exportBackup(File destination) async {
    final source = _file;
    if (source == null) {
      throw const FormatException(
        'Backup nur für gespeicherte Datenbanken verfügbar.',
      );
    }
    if (p.normalize(source.absolute.path) ==
        p.normalize(destination.absolute.path)) {
      throw const FormatException('Ziel darf nicht die App-Datenbank sein.');
    }
    await rows('PRAGMA wal_checkpoint(TRUNCATE)');
    final temporary = File('${destination.path}.daymark-tmp');
    try {
      await source.copy(temporary.path);
      final previous = File('${destination.path}.previous');
      if (await previous.exists()) await previous.delete();
      if (await destination.exists()) await destination.rename(previous.path);
      try {
        await temporary.rename(destination.path);
        if (await previous.exists()) await previous.delete();
      } catch (_) {
        if (await previous.exists()) await previous.rename(destination.path);
        rethrow;
      }
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<void> _verifyPassword(String password, File file) async {
    final connection = sqlite.sqlite3.open(file.path);
    try {
      connection.execute("PRAGMA key = '${password.replaceAll("'", "''")}'");
      final result = connection.select('PRAGMA integrity_check');
      if (result.single.values.single != 'ok') {
        throw const FormatException('Datenbankprüfung fehlgeschlagen.');
      }
      connection.select('SELECT version FROM app_meta LIMIT 1');
      final version =
          connection.select('PRAGMA user_version').single.values.single as int;
      if (version < 1 || version > 6) {
        throw const FormatException('Nicht unterstützte Backup-Version.');
      }
    } on sqlite.SqliteException {
      throw const FormatException('Passwort falsch oder Datenbank beschädigt.');
    } finally {
      connection.close();
    }
  }

  Future<void> changePasswordVerified(
    String oldPassword,
    String newPassword,
  ) async {
    final file = _file;
    if (file == null) {
      throw const FormatException(
        'Passwortwechsel nur für gespeicherte Datenbanken verfügbar.',
      );
    }
    if (newPassword.isEmpty) {
      throw const FormatException('Neues Passwort darf nicht leer sein.');
    }
    await rows('PRAGMA wal_checkpoint(TRUNCATE)');
    await _verifyPassword(oldPassword, file);
    await changePassword(newPassword);
    await rows('PRAGMA wal_checkpoint(TRUNCATE)');
    await _verifyPassword(newPassword, file);
  }

  Future<void> importBackup(File source, String password) async {
    final file = _file;
    if (file == null) {
      throw const FormatException(
        'Import nur für gespeicherte Datenbanken verfügbar.',
      );
    }
    if (p.normalize(source.absolute.path) == p.normalize(file.absolute.path) ||
        p.normalize(source.absolute.path) ==
            p.normalize(File('${file.path}.before-import').absolute.path)) {
      throw const FormatException('Quelle darf nicht die App-Datenbank sein.');
    }
    await _verifyPassword(password, source);
    await close();
    for (final suffix in ['-wal', '-shm']) {
      final sidecar = File('${file.path}$suffix');
      if (await sidecar.exists()) await sidecar.delete();
    }
    final previous = File('${file.path}.before-import');
    if (await previous.exists()) await previous.delete();
    await file.rename(previous.path);
    try {
      await source.copy(file.path);
    } catch (_) {
      if (await file.exists()) await file.delete();
      await previous.rename(file.path);
      rethrow;
    }
  }

  Future<void> deleteAppData() async {
    final file = _file;
    if (file == null) {
      throw const FormatException(
        'Nur gespeicherte App-Daten können gelöscht werden.',
      );
    }
    await close();
    if (await file.exists()) await file.delete();
    for (final suffix in ['-wal', '-shm', '.before-import']) {
      final sidecar = File('${file.path}$suffix');
      if (await sidecar.exists()) await sidecar.delete();
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await db.close();
  }
}

class DaymarkDatabase extends GeneratedDatabase {
  DaymarkDatabase(super.executor);
  @override
  int get schemaVersion => 6;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 1 || from > 5 || to != 6) {
        throw StateError('Nicht unterstützte Datenbankmigration: $from → $to');
      }
      // Drift checks user_version before the store can initialize its SQL schema.
      await transaction(() => DaymarkStore._(this)._schema());
    },
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
}
