import 'package:flutter/material.dart';

import '../../data/daymark_store.dart';
import '../../domain/attendance_summary.dart';
import '../../domain/today_schedule.dart';
import '../theme/daymark_theme.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({
    super.key,
    required this.store,
    required this.onOpenLesson,
  });
  final DaymarkStore store;
  final ValueChanged<TodayLesson> onOpenLesson;
  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  late Future<List<_ClassItem>> _classes = _loadClasses();
  int? _classId;
  int? _studentId;
  String _search = '';
  final _searchController = TextEditingController();
  Future<List<_SearchHit>>? _searchResultsFuture;
  String _sort = 'name';
  bool _descending = false;
  int _revision = 0;
  late int _schoolYear = DateTime.now().month >= 8
      ? DateTime.now().year
      : DateTime.now().year - 1;
  final _rosterFutures = <int, Future<_Roster>>{};

  @override
  void initState() {
    super.initState();
    _loadSchoolYear();
  }

  Future<void> _loadSchoolYear() async {
    final saved = await widget.store.setting('school_year');
    final year = saved == null ? null : int.tryParse(saved.substring(0, 4));
    if (year != null && mounted) {
      setState(() {
        _schoolYear = year;
        _rosterFutures.clear();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<_SearchHit>> _searchAll(String text) async => [
    for (final row in await widget.store.searchStudents(
      text,
      dayKey(DateTime.now()),
    ))
      _SearchHit(
        row['id'] as int,
        row['class_id'] as int,
        row['first_name'] as String,
        row['last_name'] as String,
        row['class_name'] as String,
      ),
  ];
  Future<List<_ClassItem>> _loadClasses() async => [
    for (final row in await widget.store.classes())
      _ClassItem(row['id'] as int, row['name'] as String),
  ];
  void _reload() => setState(() {
    _classes = _loadClasses();
    _rosterFutures.clear();
    _revision++;
  });
  Future<void> _run(Future<void> Function() work) async {
    try {
      await work();
      if (mounted) _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<String?> _ask(String title, String initial) async {
    var text = initial;
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initial,
          onChanged: (value) => text = value,
          autofocus: true,
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text.trim()),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    return value?.isNotEmpty == true ? value : null;
  }

  Future<void> _addClass() async {
    final name = await _ask('Klasse', '');
    if (name != null) await _run(() => widget.store.addClass(name));
  }

  Future<void> _renameClass(_ClassItem item) async {
    final name = await _ask('Klasse bearbeiten', item.name);
    if (name != null) await _run(() => widget.store.renameClass(item.id, name));
  }

  Future<void> _addStudent(_ClassItem item) async {
    final first = await _ask('Vorname', '');
    if (first == null || !mounted) return;
    final last = await _ask('Nachname', '');
    if (last != null) {
      await _run(() => widget.store.addStudent(item.id, first, last));
    }
  }

  Future<void> _renameStudent(_Student student) async {
    final first = await _ask('Vorname', student.first);
    if (first == null || !mounted) return;
    final last = await _ask('Nachname', student.last);
    if (last != null) {
      await _run(() => widget.store.renameStudent(student.id, first, last));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<_ClassItem>>(
    future: _classes,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: TextButton(
            onPressed: _reload,
            child: Text('Fehler: ${snapshot.error} · Wiederholen'),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final classes = snapshot.data!;
      final selected =
          classes.where((item) => item.id == _classId).firstOrNull ??
          classes.firstOrNull;
      if (_studentId != null && selected != null) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: _StudentDetailPage(
            key: ValueKey('student-${_studentId}_$_revision'),
            onOpenLesson: widget.onOpenLesson,
            onRename: _renameStudent,
            store: widget.store,
            classItem: selected,
            initialYear: _schoolYear,
            studentId: _studentId!,
            onBack: () => setState(() => _studentId = null),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Klassen',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Schüler/in suchen',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() {
                      _search = value;
                      _searchResultsFuture = value.trim().isEmpty
                          ? null
                          : _searchAll(value.trim());
                    }),
                  ),
                ),
                const SizedBox(width: 20),
                FilledButton.icon(
                  onPressed: _addClass,
                  icon: Icon(Icons.add),
                  label: const Text('Klasse'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final item in classes)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(item.name),
                        selected: item.id == selected?.id,
                        onSelected: (_) => setState(() {
                          _classId = item.id;
                          _studentId = null;
                        }),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _search.isNotEmpty
                  ? _searchResults()
                  : selected == null
                  ? const Center(child: Text('Noch keine Klasse vorhanden.'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final info = _classInfo(selected);
                        final roster = _roster(selected);
                        return constraints.maxWidth < 850
                            ? ListView(
                                children: [
                                  SizedBox(height: 270, child: info),
                                  const SizedBox(height: 8),
                                  SizedBox(height: 520, child: roster),
                                ],
                              )
                            : Row(
                                children: [
                                  SizedBox(width: 340, child: info),
                                  const SizedBox(width: 8),
                                  Expanded(child: roster),
                                ],
                              );
                      },
                    ),
            ),
          ],
        ),
      );
    },
  );
  Widget _searchResults() => FutureBuilder<List<_SearchHit>>(
    future: _searchResultsFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Suche fehlgeschlagen: ${snapshot.error}'));
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.data!.isEmpty) {
        return const Center(child: Text('Keine Schüler/innen gefunden.'));
      }
      return _Card(
        child: ListView(
          children: [
            for (final hit in snapshot.data!)
              ListTile(
                title: Text('${hit.last}, ${hit.first}'),
                subtitle: Text('Klasse ${hit.className}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _search = '';
                    _classId = hit.classId;
                    _studentId = hit.id;
                  });
                },
              ),
          ],
        ),
      );
    },
  );
  Widget _classInfo(_ClassItem item) => _Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Klasse ${item.name}',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 30),
          Text(
            'Schuljahr $_schoolYear/${(_schoolYear + 1).toString().substring(2)}',
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _renameClass(item),
            icon: Icon(Icons.edit_outlined),
            label: const Text('Klasse bearbeiten'),
          ),
          TextButton.icon(
            onPressed: () => _addStudent(item),
            icon: Icon(Icons.add),
            label: const Text('+ Schüler/in'),
          ),
        ],
      ),
    ),
  );
  Widget _roster(_ClassItem item) => FutureBuilder<_Roster>(
    future: _rosterFutures.putIfAbsent(item.id, () => _loadRoster(item.id)),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: TextButton(
            onPressed: _reload,
            child: Text('Fehler: ${snapshot.error} · Wiederholen'),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final students = snapshot.data!.students
          .where(
            (student) => '${student.first} ${student.last}'
                .toLowerCase()
                .contains(_search.toLowerCase()),
          )
          .toList();
      students.sort((a, b) {
        final roster = snapshot.data!;
        final comparison = switch (_sort) {
          'absences' => (roster.absences[a.id] ?? 0).compareTo(
            roster.absences[b.id] ?? 0,
          ),
          'lates' => (roster.lates[a.id] ?? 0).compareTo(
            roster.lates[b.id] ?? 0,
          ),
          'last' => (roster.lastEntries[a.id] ?? '').compareTo(
            roster.lastEntries[b.id] ?? '',
          ),
          _ => a.last.compareTo(b.last),
        };
        return _descending ? -comparison : comparison;
      });
      return _Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schülerinnen und Schüler (${snapshot.data!.students.length})',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 25),
              LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth < 740
                    ? const SizedBox.shrink()
                    : Row(
                        children: [
                          Expanded(flex: 3, child: _sortButton('Name', 'name')),
                          Expanded(
                            child: _sortButton('Fehlstunden', 'absences'),
                          ),
                          Expanded(child: _sortButton('Verspätet', 'lates')),
                          Expanded(
                            flex: 2,
                            child: _sortButton('Letzter Eintrag', 'last'),
                          ),
                        ],
                      ),
              ),
              Expanded(
                child: students.isEmpty
                    ? const Center(child: Text('Keine Schüler/innen gefunden.'))
                    : ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final roster = snapshot.data!;
                          return LayoutBuilder(
                            builder: (context, constraints) =>
                                constraints.maxWidth < 740
                                ? ListTile(
                                    title: Text(
                                      '${student.last}, ${student.first}',
                                    ),
                                    subtitle: Text(
                                      '${roster.absences[student.id] ?? 0} Fehlstunden · ${roster.lates[student.id] ?? 0} verspätet',
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () =>
                                        setState(() => _studentId = student.id),
                                  )
                                : InkWell(
                                    onTap: () =>
                                        setState(() => _studentId = student.id),
                                    child: SizedBox(
                                      height: 46,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              '${student.last}, ${student.first}',
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              '${roster.absences[student.id] ?? 0}',
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              '${roster.lates[student.id] ?? 0}',
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              roster.lastEntries[student.id] ??
                                                  '–',
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right),
                                        ],
                                      ),
                                    ),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
  Widget _sortButton(String label, String key) => TextButton(
    onPressed: () => setState(() {
      if (_sort == key) {
        _descending = !_descending;
      } else {
        _sort = key;
        _descending = false;
      }
    }),
    child: Text(
      '$label ${_sort == key ? (_descending ? '↓' : '↑') : ''}',
      overflow: TextOverflow.ellipsis,
    ),
  );
  Future<_Roster> _loadRoster(int classId) async {
    final rows = await widget.store.students(classId, dayKey(DateTime.now()));
    final attendance = await widget.store.classAttendanceSummary(
      classId,
      '$_schoolYear-08-01',
      '${_schoolYear + 1}-07-31',
    );
    final students = [
      for (final row in rows)
        _Student(
          row['id'] as int,
          row['first_name'] as String,
          row['last_name'] as String,
        ),
    ];
    final absences = <int, int>{}, lates = <int, int>{};
    final lastEntries = <int, String>{};
    for (final row in attendance) {
      final id = row['student_id'] as int;
      final day = row['day'] as String;
      if (day.compareTo(lastEntries[id] ?? '') > 0) lastEntries[id] = day;
      if (row['status'] == 'absent' || row['status'] == 'excused') {
        absences[id] = (absences[id] ?? 0) + 1;
      }
      if (row['status'] == 'late') lates[id] = (lates[id] ?? 0) + 1;
    }
    return _Roster(students, absences, lates, lastEntries);
  }
}

class _StudentDetailPage extends StatefulWidget {
  const _StudentDetailPage({
    super.key,
    required this.store,
    required this.classItem,
    required this.initialYear,
    required this.studentId,
    required this.onBack,
    required this.onOpenLesson,
    required this.onRename,
  });
  final ValueChanged<TodayLesson> onOpenLesson;
  final Future<void> Function(_Student) onRename;
  final DaymarkStore store;
  final _ClassItem classItem;
  final int initialYear;
  final int studentId;
  final VoidCallback onBack;
  @override
  State<_StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<_StudentDetailPage> {
  late Future<_StudentHistory> _data = _load();
  late int _year = widget.initialYear;
  Future<_StudentHistory> _load() async {
    final students = await widget.store.students(
      widget.classItem.id,
      dayKey(DateTime.now()),
    );
    final student = students
        .where((row) => row['id'] == widget.studentId)
        .firstOrNull;
    if (student == null) throw StateError('Schüler/in nicht gefunden.');
    return _StudentHistory(
      _Student(
        widget.studentId,
        student['first_name'] as String,
        student['last_name'] as String,
      ),
      [
        for (final row in await widget.store.studentNotes(widget.studentId))
          _StudentNote.fromRow(row),
      ],
      [
        for (final row in await widget.store.studentAttendance(
          widget.studentId,
        ))
          _AttendanceEntry.fromRow(row),
      ],
    );
  }

  Future<void> _openNote(_StudentNote note) async {
    try {
      final row = await widget.store.lesson(note.lessonId);
      if (!mounted) return;
      widget.onOpenLesson(
        TodayLesson(
          slotId: row['slot_id'] as int?,
          classId: widget.classItem.id,
          className: widget.classItem.name,
          subject: row['subject'] as String,
          period: row['period'] as int,
          day: DateTime.parse(row['day'] as String),
          startTime: row['start_time'] as String?,
          lessonId: note.lessonId,
          completed: row['completed'] == 1,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_StudentHistory>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: TextButton(
            onPressed: () => setState(() => _data = _load()),
            child: Text('Fehler: ${snapshot.error} · Wiederholen'),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final data = snapshot.data!;
      final notes = data.notes
          .where((row) => schoolYearFor(row.day).startsWith('$_year/'))
          .toList();
      final attendance = data.attendance
          .where((row) => schoolYearFor(row.day).startsWith('$_year/'))
          .toList();
      final absent = attendance
          .where((entry) => entry.status == 'absent')
          .length;
      final excused = attendance
          .where((entry) => entry.status == 'excused')
          .length;
      final late = attendance.where((entry) => entry.status == 'late').length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: widget.onBack,
                icon: Icon(Icons.arrow_back),
                label: Text('Klasse ${widget.classItem.name}'),
              ),
              const Spacer(),
              DropdownButton<int>(
                value: _year,
                items: [
                  for (
                    var year = (widget.initialYear > DateTime.now().year + 1
                        ? widget.initialYear
                        : DateTime.now().year + 1);
                    year >= 1900;
                    year--
                  )
                    DropdownMenuItem(
                      value: year,
                      child: Text('Schuljahr $year/${(year + 1) % 100}'),
                    ),
                ],
                onChanged: (year) => setState(() => _year = year!),
              ),
            ],
          ),
          Text(
            '${data.student.last}, ${data.student.first}',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          Text('Klasse ${widget.classItem.name}'),
          TextButton.icon(
            onPressed: () async {
              await widget.onRename(data.student);
              if (mounted) {
                setState(() {
                  _data = _load();
                });
              }
            },
            icon: Icon(Icons.edit_outlined),
            label: const Text('Schüler/in bearbeiten'),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final left = _Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bemerkungen',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: notes.isEmpty
                              ? const Center(child: Text('Keine Bemerkungen.'))
                              : ListView(
                                  children: [
                                    for (final row in notes)
                                      ListTile(
                                        title: Text(
                                          '${row.day} · ${row.period}. Stunde · ${row.subject}',
                                        ),
                                        subtitle: Text(row.body),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (_) => _openNote(row),
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(
                                              value: 'open',
                                              child: Text('Stunde öffnen'),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                );
                final right = _Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fehlzeiten',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${absent + excused} Fehlstunden · $late Verspätungen',
                        ),
                        const Divider(),
                        Expanded(
                          child: attendance.isEmpty
                              ? const Center(child: Text('Keine Einträge.'))
                              : ListView(
                                  children: [
                                    for (final row in attendance)
                                      ListTile(
                                        title: Text(
                                          '${row.day} · ${row.period}. ${row.subject}',
                                        ),
                                        subtitle: Text(row.status),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                );
                return constraints.maxWidth < 900
                    ? ListView(
                        children: [
                          SizedBox(height: 450, child: left),
                          const SizedBox(height: 10),
                          SizedBox(height: 450, child: right),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 3, child: left),
                          const SizedBox(width: 8),
                          Expanded(flex: 2, child: right),
                        ],
                      );
              },
            ),
          ),
        ],
      );
    },
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: DaymarkColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: DaymarkColors.border),
    ),
    child: child,
  );
}

class _ClassItem {
  const _ClassItem(this.id, this.name);
  final int id;
  final String name;
}

class _Student {
  const _Student(this.id, this.first, this.last);
  final int id;
  final String first, last;
}

class _Roster {
  const _Roster(this.students, this.absences, this.lates, this.lastEntries);
  final List<_Student> students;
  final Map<int, int> absences, lates;
  final Map<int, String> lastEntries;
}

class _StudentHistory {
  const _StudentHistory(this.student, this.notes, this.attendance);
  final _Student student;
  final List<_StudentNote> notes;
  final List<_AttendanceEntry> attendance;
}

class _StudentNote {
  const _StudentNote(
    this.lessonId,
    this.day,
    this.period,
    this.subject,
    this.body,
  );
  final int lessonId, period;
  final String day, subject, body;
  factory _StudentNote.fromRow(Map<String, Object?> row) => _StudentNote(
    row['lesson_id'] as int,
    row['day'] as String,
    row['period'] as int,
    row['subject'] as String,
    row['body'] as String,
  );
}

class _AttendanceEntry {
  const _AttendanceEntry(this.day, this.period, this.subject, this.status);
  final int period;
  final String day, subject, status;
  factory _AttendanceEntry.fromRow(Map<String, Object?> row) =>
      _AttendanceEntry(
        row['day'] as String,
        row['period'] as int,
        row['subject'] as String,
        row['status'] as String,
      );
}

class _SearchHit {
  const _SearchHit(
    this.id,
    this.classId,
    this.first,
    this.last,
    this.className,
  );
  final int id, classId;
  final String first, last, className;
}
