import 'dart:io';

import 'package:daymark/data/daymark_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('version 2 database gains settings without losing rows', () async {
    final dir = await Directory.systemTemp.createTemp('daymark-v2-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/daymark.sqlite');
    final first = await DaymarkStore.openFile(file, 'old');
    await first.addClass('8b');
    await first.db.customStatement('PRAGMA user_version = 2');
    await first.close();
    final upgraded = await DaymarkStore.openFile(file, 'old');
    expect((await upgraded.classes()).single['name'], '8b');
    await upgraded.setSetting('period_1', '08:15');
    expect(await upgraded.setting('period_1'), '08:15');
    expect(
      (await upgraded.rows('PRAGMA user_version')).single['user_version'],
      4,
    );
    await upgraded.close();
  });

  test('encrypted backup and password change preserve data', () async {
    final dir = await Directory.systemTemp.createTemp('daymark-backup-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/app.sqlite');
    final backup = File('${dir.path}/backup.sqlite');
    final store = await DaymarkStore.openFile(file, 'first');
    await store.addClass('8b');
    await store.exportBackup(backup);
    final unkeyed = sqlite.sqlite3.open(backup.path);
    expect(
      () => unkeyed.select('SELECT name FROM sqlite_master'),
      throwsA(isA<sqlite.SqliteException>()),
    );
    unkeyed.close();
    final corrupt = File('${dir.path}/corrupt.sqlite');
    await corrupt.writeAsString('invalid');
    await expectLater(store.importBackup(corrupt, 'first'), throwsA(anything));
    expect((await store.classes()).single['name'], '8b');
    await store.changePasswordVerified('first', 'second');
    await store.close();
    await expectLater(
      DaymarkStore.openFile(file, 'first'),
      throwsFormatException,
    );
    final reopened = await DaymarkStore.openFile(file, 'second');
    expect((await reopened.classes()).single['name'], '8b');
    await reopened.importBackup(backup, 'first');
    final restored = await DaymarkStore.openFile(file, 'first');
    expect((await restored.classes()).single['name'], '8b');
    await restored.close();
    final deleted = await DaymarkStore.openFile(file, 'first');
    await deleted.deleteAppData();
    expect(await file.exists(), isFalse);
    expect(await File('${file.path}.before-import').exists(), isFalse);
  });
  test('editing a used slot preserves historical lesson time', () async {
    final store = await DaymarkStore.inMemory();
    addTearDown(store.close);
    await store.addClass('8b');
    await store.addSlot(1, 'Englisch', 1, 3, '09:55', '2020-01-01');
    final slot = (await store.slots()).single;
    final lessonId = await store.openLesson(slot, '2026-10-26');
    await store.updateSlot(
      slot['id'] as int,
      1,
      'Deutsch',
      1,
      3,
      '10:00',
      '2020-01-01',
      null,
    );
    final slots = await store.slots();
    expect(slots, hasLength(2));
    expect((await store.lesson(lessonId))['start_time'], '09:55');
    expect((await store.lesson(lessonId))['subject'], 'Englisch');
    expect((await store.slotsFor(DateTime(2026, 10, 27))), isEmpty);
    expect(
      (await store.slotsFor(DateTime(2026, 11, 2))).single['subject'],
      'Deutsch',
    );
  });
  test(
    'bulk lesson times reject invalid entries without partial writes',
    () async {
      final store = await DaymarkStore.inMemory();
      addTearDown(store.close);
      final starts = [
        '08:00',
        '08:55',
        '09:55',
        '10:55',
        '11:50',
        '12:45',
        '13:45',
        '14:40',
      ];
      await store.setPeriodTimes(starts);
      expect(await store.setting('period_3'), '09:55');
      await expectLater(
        store.setPeriodTimes([...starts]..[3] = '25:00'),
        throwsFormatException,
      );
      expect(await store.setting('period_4'), '10:55');
      await expectLater(
        store.setPeriodTimes([...starts]..[3] = '10:30'),
        throwsFormatException,
      );
      expect(await store.setting('period_4'), '10:55');
    },
  );
}
