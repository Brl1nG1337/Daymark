import 'dart:io';

import 'package:daymark/data/daymark_store.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  for (final alreadyExtended in [false, true]) {
    test('opens encrypted version 1 (extended: $alreadyExtended)', () async {
      final directory = await Directory.systemTemp.createTemp('daymark-test-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/daymark.sqlite');
      final legacy = sqlite3.open(file.path);
      try {
        legacy.execute("PRAGMA key = 'admin123'");
        legacy.execute('PRAGMA user_version = 1');
        legacy.execute(
          'CREATE TABLE app_meta (id INTEGER PRIMARY KEY, version INTEGER NOT NULL)',
        );
        legacy.execute('INSERT INTO app_meta VALUES (1, 1)');
        legacy.execute(
          'CREATE TABLE lessons (id INTEGER PRIMARY KEY, slot_id INTEGER, class_id INTEGER NOT NULL, subject TEXT NOT NULL, period INTEGER NOT NULL, day TEXT NOT NULL, completed INTEGER NOT NULL DEFAULT 0, UNIQUE(slot_id, day))',
        );
        legacy.execute(
          "INSERT INTO lessons VALUES (1,NULL,1,'Mathe',2,'2026-11-02',1)",
        );
        if (alreadyExtended) {
          for (final column in ['started_at', 'topic', 'summary', 'homework']) {
            legacy.execute('ALTER TABLE lessons ADD COLUMN $column TEXT');
          }
          legacy.execute("UPDATE lessons SET topic = 'Brüche' WHERE id = 1");
          legacy.execute('UPDATE app_meta SET version = 2');
        }
      } finally {
        legacy.close();
      }

      Future<DaymarkStore> open() => DaymarkStore.inMemory(
        database: DaymarkDatabase(
          NativeDatabase.createInBackground(
            file,
            setup: (raw) => raw.execute("PRAGMA key = 'admin123'"),
          ),
        ),
      );

      final store = await open();
      try {
        final lesson = (await store.rows('SELECT * FROM lessons')).single;
        expect(lesson['subject'], 'Mathe');
        expect(lesson['completed'], 1);
        expect(lesson['topic'], alreadyExtended ? 'Brüche' : isNull);
        expect(lesson.keys, containsAll(['started_at', 'summary', 'homework']));
        expect(
          (await store.rows('PRAGMA user_version')).single['user_version'],
          2,
        );
        expect(
          (await store.rows('SELECT version FROM app_meta')).single['version'],
          2,
        );
        await store.updateLessonDetails(1, 'Brüche', 'Wiederholung', 'Seite 5');
      } finally {
        await store.close();
      }
      final reopened = await open();
      try {
        final lesson = (await reopened.rows('SELECT * FROM lessons')).single;
        expect(lesson['topic'], 'Brüche');
        expect(lesson['homework'], 'Seite 5');
        expect(lesson['completed'], 1);
      } finally {
        await reopened.close();
      }
    });
  }
}
