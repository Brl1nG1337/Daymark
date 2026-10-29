import 'package:flutter/material.dart';

import '../data/daymark_store.dart';
import '../data/offline_dictation.dart';
import 'daymark_sidebar.dart';
import 'today/today_page.dart';
import '../domain/attendance_summary.dart';

String scheduleWeekdayLabel(Object? weekday) => switch (weekday) {
  1 => 'Mo',
  2 => 'Di',
  3 => 'Mi',
  4 => 'Do',
  5 => 'Fr',
  6 => 'Sa',
  7 => 'So',
  _ => 'Tag fehlt',
};

Future<String?> showTextInputDialog(
  BuildContext context,
  String title, {
  String hint = '',
  String initial = '',
}) async {
  final value = await showDialog<String>(
    context: context,
    builder: (context) =>
        _TextInputDialog(title: title, hint: hint, initial: initial),
  );
  return value?.trim().isNotEmpty == true ? value!.trim() : null;
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.hint,
    required this.initial,
  });

  final String title;
  final String hint;
  final String initial;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      decoration: InputDecoration(hintText: widget.hint),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Übernehmen')),
    ],
  );
}

class DaymarkApp extends StatefulWidget {
  const DaymarkApp({super.key, required this.store, this.initialDate});
  final DateTime? initialDate;
  final DaymarkStore store;
  @override
  State<DaymarkApp> createState() => _DaymarkAppState();
}

class _DaymarkAppState extends State<DaymarkApp> {
  int page = 0, classId = 0, lessonId = 0, studentId = 0;
  late DateTime selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialDate ?? DateTime.now();
  }

  Map<String, Object?>? selectedSlot;
  int refresh = 0;
  void reload() => setState(() => refresh++);
  Future<void> action(Future<void> Function() work) async {
    try {
      await work();
      if (mounted) reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<String?> input(
    String title, {
    String hint = '',
    String initial = '',
  }) => showTextInputDialog(context, title, hint: hint, initial: initial);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        DaymarkSidebar(
          selectedIndex: page,
          onSelected: (index) => setState(() {
            page = index;
            selectedSlot = null;
            lessonId = 0;
            studentId = 0;
          }),
        ),
        Expanded(
          child: switch (page) {
            0 => selectedSlot == null ? dashboard() : lessonDetail(),
            1 => classes(),
            2 => schedule(),
            _ => freeDays(),
          },
        ),
      ],
    ),
  );
  Widget frame(String title, List<Widget> actions, Widget child) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        if (actions.isNotEmpty)
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          ),
        const SizedBox(height: 20),
        Expanded(child: child),
      ],
    ),
  );
  Widget load(
    Future<List<Map<String, Object?>>> future,
    Widget Function(List<Map<String, Object?>>) builder,
  ) => FutureBuilder<List<Map<String, Object?>>>(
    key: ValueKey(refresh),
    future: future,
    builder: (context, s) {
      if (s.hasError) return Center(child: Text('Fehler: ${s.error}'));
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      return builder(s.data!);
    },
  );
  DateTime get weekStart {
    final date = DateTime(selected.year, selected.month, selected.day);
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Widget dashboard() => TodayPage(
    store: widget.store,
    initialDate: selected,
    onDateChanged: (date) => selected = date,
    onOpenLesson: (lesson) => setState(() {
      selectedSlot = {
        'id': lesson.slotId,
        'class_id': lesson.classId,
        'class_name': lesson.className,
        'subject': lesson.subject,
        'period': lesson.period,
        'day': dayKey(lesson.day),
        'start_time': lesson.startTime,
      };
      lessonId = lesson.lessonId ?? 0;
      studentId = 0;
    }),
  );
  Widget classes() => load(
    widget.store.classes(),
    (classes) => frame(
      'Klassen',
      [
        FilledButton.icon(
          onPressed: () async {
            final n = await input('Neue Klasse', hint: 'z. B. 3a');
            if (n != null) await action(() => widget.store.addClass(n));
          },
          icon: const Icon(Icons.add),
          label: const Text('Klasse'),
        ),
      ],
      Row(
        children: [
          SizedBox(
            width: 190,
            child: ListView(
              children: classes
                  .map(
                    (c) => ListTile(
                      title: Text('${c['name']}'),
                      selected: classId == c['id'],
                      onTap: () => setState(() {
                        classId = c['id'] as int;
                        studentId = 0;
                      }),
                    ),
                  )
                  .toList(),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: classId == 0
                ? const Center(child: Text('Klasse auswählen.'))
                : classDetail(),
          ),
        ],
      ),
    ),
  );
  Widget classDetail() => FutureBuilder<List<Map<String, Object?>>>(
    key: ValueKey('roster$classId$refresh'),
    future: widget.store.students(classId, dayKey(DateTime.now())),
    builder: (ctx, s) {
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final roster = s.data!;
      return Column(
        children: [
          Row(
            children: [
              Text('Schüler', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final first = await input('Vorname');
                  if (first == null) return;
                  final last = await input('Nachname');
                  if (last != null) {
                    await action(
                      () => widget.store.addStudent(classId, first, last),
                    );
                  }
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Schüler hinzufügen'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: roster
                  .map(
                    (st) => ListTile(
                      title: Text('${st['last_name']}, ${st['first_name']}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => setState(() => studentId = st['id'] as int),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (studentId != 0) SizedBox(height: 250, child: studentHistory()),
        ],
      );
    },
  );
  Widget lessonDetail() {
    final slot = selectedSlot!;
    return frame(
      'Stundendetail',
      [
        TextButton.icon(
          onPressed: () => setState(() {
            selectedSlot = null;
            lessonId = 0;
            studentId = 0;
          }),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Zum Stundenplan'),
        ),
      ],
      lessonId == 0
          ? ListView(
              children: [
                Text(
                  '${slot['subject']} · ${slot['class_name']}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${slot['day']} · ${slot['period']}. Stunde${slot['start_time'] == null ? '' : ' · ${slot['start_time']}'}',
                ),
                const SizedBox(height: 12),
                const Chip(label: Text('Geplant')),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () async {
                      try {
                        final id = await widget.store.openLesson(
                          slot,
                          slot['day'] as String,
                        );
                        if (mounted) {
                          setState(() {
                            lessonId = id;
                            refresh++;
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Stunde starten'),
                  ),
                ),
              ],
            )
          : lessonView(),
    );
  }

  Widget lessonView() => FutureBuilder<List<dynamic>>(
    key: ValueKey('lesson$lessonId$refresh'),
    future: Future.wait([
      widget.store.lesson(lessonId),
      widget.store.attendance(lessonId),
      widget.store.notes(lessonId),
    ]),
    builder: (ctx, s) {
      if (s.hasError) return Center(child: Text('Fehler: ${s.error}'));
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final lesson = s.data![0] as Map<String, Object?>,
          attendance = s.data![1] as List<Map<String, Object?>>,
          notes = s.data![2] as List<Map<String, Object?>>;
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${lesson['subject']} · ${lesson['class_name']} · ${lesson['day']} · ${lesson['period']}. Stunde',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (lesson['completed'] == 1)
                TextButton.icon(
                  onPressed: () => action(() => widget.store.reopen(lessonId)),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Stunde erneut öffnen'),
                )
              else
                FilledButton(
                  onPressed: () =>
                      action(() => widget.store.complete(lessonId)),
                  child: const Text('Stunde abschließen'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        lesson['completed'] == 1 ? 'Abgeschlossen' : 'Begonnen',
                      ),
                    ),
                    if (lesson['start_time'] != null)
                      Chip(label: Text('${lesson['start_time']}')),
                    OutlinedButton.icon(
                      onPressed: lesson['completed'] == 1
                          ? null
                          : () => editLessonDetails(lesson),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Stundeninhalt bearbeiten'),
                    ),
                  ],
                ),
                ListTile(
                  title: const Text('Thema'),
                  subtitle: Text(
                    '${lesson['topic'] ?? ''}'.isEmpty
                        ? 'Noch kein Thema'
                        : '${lesson['topic']}',
                  ),
                ),
                ListTile(
                  title: const Text('Stundennotiz'),
                  subtitle: Text(
                    '${lesson['summary'] ?? ''}'.isEmpty
                        ? 'Noch keine Notiz'
                        : '${lesson['summary']}',
                  ),
                ),
                ListTile(
                  title: const Text('Hausaufgaben'),
                  subtitle: Text(
                    '${lesson['homework'] ?? ''}'.isEmpty
                        ? 'Keine Hausaufgaben'
                        : '${lesson['homework']}',
                  ),
                ),
                const Divider(),
                Text(
                  'Anwesenheit',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ...attendance.map(
                  (a) => Card(
                    child: ListTile(
                      title: Text('${a['last_name']}, ${a['first_name']}'),
                      subtitle: Text(_statusLabel('${a['status']}')),
                      leading: IconButton(
                        icon: Icon(
                          a['status'] == 'present'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: a['status'] == 'present'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        onPressed: lesson['completed'] == 1
                            ? null
                            : () => action(
                                () => widget.store.setAttendance(
                                  lessonId,
                                  a['student_id'] as int,
                                  a['status'] == 'present'
                                      ? 'absent'
                                      : 'present',
                                ),
                              ),
                      ),
                      trailing: PopupMenuButton<String>(
                        enabled: lesson['completed'] != 1,
                        onSelected: (v) {
                          if (v == 'note') {
                            addNote(a['student_id'] as int);
                            return;
                          }
                          if (v == 'history') {
                            setState(() => studentId = a['student_id'] as int);
                            return;
                          }
                          action(
                            () => widget.store.setAttendance(
                              lessonId,
                              a['student_id'] as int,
                              v,
                            ),
                          );
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'present',
                            child: Text('Anwesend'),
                          ),
                          PopupMenuItem(
                            value: 'absent',
                            child: Text('Abwesend'),
                          ),
                          PopupMenuItem(
                            value: 'excused',
                            child: Text('Entschuldigt'),
                          ),
                          PopupMenuItem(
                            value: 'late',
                            child: Text('Verspätet'),
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'note',
                            child: Text('Anmerkung hinzufügen'),
                          ),
                          PopupMenuItem(
                            value: 'history',
                            child: Text('Schülerhistorie'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Anmerkungen',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ...notes.map(
                  (n) => ListTile(
                    title: Text('${n['last_name']}, ${n['first_name']}'),
                    subtitle: Text('${n['body']}'),
                    trailing: PopupMenuButton<String>(
                      enabled: lesson['completed'] != 1,
                      onSelected: (choice) async {
                        if (choice == 'edit') {
                          final value = await input(
                            'Anmerkung bearbeiten',
                            initial: '${n['body']}',
                          );
                          if (value != null) {
                            await action(
                              () => widget.store.updateNote(
                                n['id'] as int,
                                value,
                              ),
                            );
                          }
                        } else {
                          await action(
                            () => widget.store.deleteNote(n['id'] as int),
                          );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                        PopupMenuItem(value: 'delete', child: Text('Löschen')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (studentId != 0) SizedBox(height: 190, child: studentHistory()),
        ],
      );
    },
  );
  String _statusLabel(String s) => switch (s) {
    'absent' => 'Abwesend',
    'excused' => 'Entschuldigt',
    'late' => 'Verspätet',
    _ => 'Anwesend',
  };
  Future<void> editLessonDetails(Map<String, Object?> lesson) async {
    var topic = '${lesson['topic'] ?? ''}';
    var summary = '${lesson['summary'] ?? ''}';
    var homework = '${lesson['homework'] ?? ''}';
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Stundeninhalt'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: topic,
                  onChanged: (value) => topic = value,
                  decoration: const InputDecoration(labelText: 'Thema'),
                ),
                TextFormField(
                  initialValue: summary,
                  onChanged: (value) => summary = value,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Stundennotiz'),
                ),
                TextFormField(
                  initialValue: homework,
                  onChanged: (value) => homework = value,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Hausaufgaben'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (save == true) {
      await action(
        () => widget.store.updateLessonDetails(
          lessonId,
          topic,
          summary,
          homework,
        ),
      );
    }
  }

  Future<void> addNote(int student) async {
    final controller = TextEditingController();
    final dictation = OfflineDictation();
    var busy = false;
    var recording = false;
    String? error;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: const Text('Anmerkung'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 5,
                  minLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Text',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          update(() {
                            busy = true;
                            error = null;
                          });
                          try {
                            if (recording) {
                              final text = await dictation.stopAndTranscribe();
                              controller.text = [controller.text, text]
                                  .where((part) => part.trim().isNotEmpty)
                                  .join(' ');
                              recording = false;
                            } else {
                              await dictation.start();
                              recording = true;
                            }
                          } catch (e) {
                            error = e.toString();
                            recording = false;
                          }
                          if (dialogContext.mounted) update(() => busy = false);
                        },
                  icon: Icon(recording ? Icons.stop : Icons.mic),
                  label: Text(
                    busy
                        ? 'Verarbeite…'
                        : recording
                        ? 'Aufnahme beenden'
                        : 'Offline diktieren',
                  ),
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await dictation.cancel();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: busy || recording
                  ? null
                  : () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
    await dictation.cancel();
    controller.dispose();
    if (value != null && value.trim().isNotEmpty) {
      await action(() => widget.store.addNote(lessonId, student, value));
    }
  }

  Widget studentHistory() => load(widget.store.history(studentId), (rows) {
    final byYear = <String, List<Map<String, Object?>>>{};
    for (final row in rows) {
      byYear
          .putIfAbsent(schoolYearFor(row['day'] as String), () => [])
          .add(row);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Schülerhistorie', style: Theme.of(context).textTheme.titleMedium),
        Expanded(
          child: ListView(
            children: [
              for (final entry in byYear.entries) ...[
                Builder(
                  builder: (context) {
                    final summary = AttendanceSummary.fromRows(entry.value);
                    return ListTile(
                      title: Text('Schuljahr ${entry.key}'),
                      subtitle: Text(
                        '${summary.absentHours} unentschuldigte · ${summary.excusedHours} entschuldigte Fehlstunden · ${summary.missingDays} Fehltage',
                      ),
                    );
                  },
                ),
                for (final r in entry.value)
                  ListTile(
                    dense: true,
                    title: Text(
                      '${r['day']} · ${r['period']}. ${r['subject']} · ${_statusLabel('${r['status']}')}',
                    ),
                    subtitle: r['body'] != null ? Text('${r['body']}') : null,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  });
  Widget schedule() => load(
    widget.store.slots(),
    (slots) => frame(
      'Stundenplan',
      [
        FilledButton.icon(
          onPressed: () => addSlot(),
          icon: const Icon(Icons.add),
          label: const Text('Eintrag'),
        ),
      ],
      ListView(
        children: slots
            .map(
              (sl) => ListTile(
                title: Text(
                  '${scheduleWeekdayLabel(sl['weekday'])} · ${sl['period'] ?? '–'}. Stunde · ${sl['class_name']} · ${sl['subject']}',
                ),
                subtitle: Text(
                  'Ab ${sl['valid_from']}${sl['valid_to'] == null ? '' : ' bis ${sl['valid_to']}'}',
                ),
                trailing: sl['valid_to'] == null
                    ? IconButton(
                        icon: const Icon(Icons.stop_circle_outlined),
                        tooltip: 'Ab Datum beenden',
                        onPressed: () async {
                          final end = await input(
                            'Letzter Gültigkeitstag (JJJJ-MM-TT)',
                            hint: dayKey(DateTime.now()),
                          );
                          if (end != null) {
                            await action(
                              () => widget.store.endSlot(sl['id'] as int, end),
                            );
                          }
                        },
                      )
                    : null,
              ),
            )
            .toList(),
      ),
    ),
  );
  Future<void> addSlot() async {
    final classes = await widget.store.classes();
    if (classes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zuerst eine Klasse anlegen.')),
        );
      }
      return;
    }
    if (!mounted) return;
    int cid = classes.first['id'] as int, weekday = 1, period = 1;
    final subject = TextEditingController(),
        time = TextEditingController(),
        from = TextEditingController(text: dayKey(DateTime.now()));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Stundenplan-Eintrag'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: cid,
                  items: classes
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['id'] as int,
                          child: Text('${c['name']}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => set(() => cid = v!),
                ),
                TextField(
                  controller: subject,
                  decoration: const InputDecoration(labelText: 'Fach'),
                ),
                DropdownButtonFormField<int>(
                  initialValue: weekday,
                  items: List.generate(
                    5,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(
                        [
                          'Montag',
                          'Dienstag',
                          'Mittwoch',
                          'Donnerstag',
                          'Freitag',
                        ][i],
                      ),
                    ),
                  ),
                  onChanged: (v) => set(() => weekday = v!),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Stundennummer'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => period = int.tryParse(v) ?? 1,
                ),
                TextField(
                  controller: time,
                  decoration: const InputDecoration(
                    labelText: 'Uhrzeit (optional)',
                  ),
                ),
                TextField(
                  controller: from,
                  decoration: const InputDecoration(
                    labelText: 'Gültig ab (JJJJ-MM-TT)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Anlegen'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && subject.text.trim().isNotEmpty) {
      await action(
        () => widget.store.addSlot(
          cid,
          subject.text,
          weekday,
          period,
          time.text.isEmpty ? null : time.text,
          from.text,
        ),
      );
    }
    subject.dispose();
    time.dispose();
    from.dispose();
  }

  Widget freeDays() => load(
    widget.store.freeDays(),
    (days) => frame(
      'Schulfreie Tage',
      [
        FilledButton.icon(
          onPressed: () async {
            final day = await input('Datum (JJJJ-MM-TT)');
            if (day == null) return;
            final label = await input('Bezeichnung');
            if (label != null) {
              await action(() => widget.store.addFreeDay(day, label));
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Freien Tag eintragen'),
        ),
      ],
      ListView(
        children: [
          const ListTile(
            title: Text(
              'NRW-Ferien und gesetzliche Feiertage sind integriert.',
            ),
          ),
          ...days.map(
            (d) => ListTile(
              title: Text('${d['day']} · ${d['label']}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    action(() => widget.store.removeFreeDay('${d['day']}')),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
