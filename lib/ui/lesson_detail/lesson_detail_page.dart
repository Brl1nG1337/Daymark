import 'package:flutter/material.dart';

import '../../data/daymark_store.dart';
import '../../data/offline_dictation.dart';
import '../../domain/today_schedule.dart';
import '../theme/daymark_theme.dart';

/// The working view for a single scheduled lesson.
///
/// A planned lesson is deliberately not created until the teacher presses
/// "Stunde starten". This keeps opening a row on the Today screen side-effect
/// free.
class LessonDetailPage extends StatefulWidget {
  const LessonDetailPage({
    super.key,
    required this.store,
    required this.lesson,
    required this.onBack,
  });

  final DaymarkStore store;
  final TodayLesson lesson;
  final VoidCallback onBack;

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  late int? _lessonId = widget.lesson.lessonId;
  late Future<_LessonDetailData>? _data = _lessonId == null ? null : _load();
  _DetailTab _tab = _DetailTab.attendance;
  int? _selectedStudentId;
  int? _selectedNoteId;
  final _noteController = TextEditingController();
  bool _busy = false;
  bool _recording = false;
  final _dictation = OfflineDictation();
  String? _savedNoteText;
  final _contentKey = GlobalKey<_ContentEditorState>();

  @override
  void dispose() {
    _dictation.cancel();
    _noteController.dispose();
    super.dispose();
  }

  Future<_LessonDetailData> _load() async {
    final id = _lessonId!;
    final results = await Future.wait<Object>([
      widget.store.lesson(id),
      widget.store.attendance(id),
      widget.store.notes(id),
    ]);
    return _LessonDetailData.fromRows(
      results[0] as Map<String, Object?>,
      results[1] as List<Map<String, Object?>>,
      results[2] as List<Map<String, Object?>>,
    );
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _data = _load();
      });
    }
  }

  Future<void> _change(Future<void> Function() work) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await work();
      _reload();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() => _change(() async {
    final slot = <String, Object?>{
      'id': widget.lesson.slotId,
      'class_id': widget.lesson.classId,
      'subject': widget.lesson.subject,
      'period': widget.lesson.period,
    };
    final id = await widget.store.openLesson(slot, dayKey(widget.lesson.day));
    if (mounted) setState(() => _lessonId = id);
  });

  Future<void> _complete(_LessonDetailData data) async {
    if (!await _mayLeave() || !mounted) return;
    await _cancelRecording();
    if (!mounted) return;
    await _change(
      () => data.completed
          ? widget.store.reopen(_lessonId!)
          : widget.store.complete(_lessonId!),
    );
  }

  Future<void> _undoStart() async {
    if (_busy || !await _mayLeave() || !mounted) return;
    await _cancelRecording();
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stundenstart rückgängig machen?'),
        content: const Text(
          'Anwesenheit, Stundeninhalt und Bemerkungen dieser Stunde werden gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start rückgängig'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.store.undoLessonStart(_lessonId!);
      if (!mounted) return;
      setState(() {
        _lessonId = null;
        _data = null;
        _tab = _DetailTab.attendance;
        _selectedStudentId = null;
        _selectedNoteId = null;
        _noteController.clear();
        _savedNoteText = null;
      });
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setAttendance(int studentId, String status) =>
      _change(() => widget.store.setAttendance(_lessonId!, studentId, status));

  Future<bool> _mayDiscardNote() async {
    if (_selectedStudentId == null ||
        _noteController.text == (_savedNoteText ?? '')) {
      return true;
    }
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ungespeicherte Bemerkung'),
            content: const Text('Änderungen an der Bemerkung verwerfen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Weiter bearbeiten'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Verwerfen'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _back() async {
    if (await _mayLeave() && mounted) {
      await _cancelRecording();
      if (mounted) widget.onBack();
    }
  }

  Future<bool> _mayLeave() async {
    if (!await _mayDiscardNote() || !mounted) return false;
    if (_contentKey.currentState?.dirty == true) {
      return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Ungespeicherter Stundeninhalt'),
              content: const Text('Änderungen am Stundeninhalt verwerfen?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Weiter bearbeiten'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Verwerfen'),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  Future<void> _selectTab(_DetailTab tab) async {
    if (tab == _tab || !await _mayLeave() || !mounted) return;
    await _cancelRecording();
    if (mounted) setState(() => _tab = tab);
  }

  Future<void> _selectStudent(
    _StudentAttendance student,
    _LessonDetailData data,
  ) async {
    if (student.studentId != _selectedStudentId && !await _mayDiscardNote()) {
      return;
    }
    if (!mounted) return;
    final note = data.latestNoteFor(student.studentId);
    setState(() {
      _selectedStudentId = student.studentId;
      _selectedNoteId = note?.id;
      _noteController.text = note?.body ?? '';
      _savedNoteText = _noteController.text;
    });
  }

  Future<void> _saveNote(_LessonDetailData data) async {
    final studentId = _selectedStudentId;
    if (studentId == null) return;
    await _change(() async {
      final existing = data
          .notesFor(studentId)
          .where((note) => note.id == _selectedNoteId)
          .firstOrNull;
      final body = _noteController.text.trim();
      if (existing == null) {
        if (body.isNotEmpty) {
          await widget.store.addNote(_lessonId!, studentId, body);
          final saved = await widget.store.notes(_lessonId!);
          _selectedNoteId =
              (saved.firstWhere((row) => row['student_id'] == studentId))['id']
                  as int;
        }
      } else {
        await widget.store.updateNote(existing.id, body);
      }
      _savedNoteText = body;
    });
  }

  Future<void> _deleteNote(_LessonDetailData data) async {
    final studentId = _selectedStudentId;
    final note = studentId == null
        ? null
        : data
              .notesFor(studentId)
              .where((note) => note.id == _selectedNoteId)
              .firstOrNull;
    if (note == null) return;
    await _change(() async {
      await widget.store.deleteNote(note.id);
      final remaining = data
          .notesFor(studentId!)
          .where((item) => item.id != note.id)
          .firstOrNull;
      _selectedNoteId = remaining?.id;
      _noteController.text = remaining?.body ?? '';
      _savedNoteText = _noteController.text;
    });
  }

  Future<void> _closeNote() async {
    if (!await _mayDiscardNote() || !mounted) return;
    await _cancelRecording();
    if (!mounted) return;
    setState(() {
      _selectedStudentId = null;
      _selectedNoteId = null;
      _noteController.clear();
      _savedNoteText = null;
    });
  }

  Future<void> _cancelRecording() async {
    if (_recording) await _dictation.cancel();
    _recording = false;
  }

  Future<void> _toggleDictation() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_recording) {
        final text = await _dictation.stopAndTranscribe();
        if (mounted) {
          _noteController.text = [
            _noteController.text,
            text,
          ].where((part) => part.trim().isNotEmpty).join(' ');
          _recording = false;
        }
      } else {
        await _dictation.start();
        if (mounted) _recording = true;
      }
    } catch (error) {
      if (mounted) _showError(error);
      await _dictation.cancel();
      _recording = false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showHistory(int studentId) async {
    try {
      final rows = await widget.store.history(studentId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Schülerhistorie'),
          content: SizedBox(
            width: 540,
            height: 420,
            child: rows.isEmpty
                ? const Center(
                    child: Text('Noch keine abgeschlossenen Stunden.'),
                  )
                : ListView(
                    children: [
                      for (final row in rows)
                        ListTile(
                          title: Text(
                            "${row['day']} · ${row['period']}. ${row['subject']}",
                          ),
                          subtitle: Text(
                            "${row['status']}${row['body'] == null ? '' : ' · ${row['body']}'}",
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Änderung konnte nicht gespeichert werden: $error')),
  );

  @override
  Widget build(BuildContext context) {
    if (_lessonId == null) {
      return _PlannedLesson(
        onStart: _busy ? null : _start,
        lesson: widget.lesson,
        onBack: _back,
      );
    }
    return FutureBuilder<_LessonDetailData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Stunde konnte nicht geladen werden: ${snapshot.error}'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _reload,
                  child: const Text('Wiederholen'),
                ),
                TextButton(
                  onPressed: _back,
                  child: const Text('Zurück zu Heute'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        return Column(
          children: [
            _Header(
              lesson: data,
              onBack: _back,
              onUndoStart: !data.completed && !_busy ? _undoStart : null,
              onComplete: data.completed || _busy
                  ? null
                  : () => _complete(data),
              onReopen: data.completed && !_busy ? () => _complete(data) : null,
            ),
            _Tabs(tab: _tab, onChanged: _selectTab),
            Expanded(
              child: _tab == _DetailTab.attendance
                  ? _AttendanceBody(
                      data: data,
                      selectedStudentId: _selectedStudentId,
                      enabled: !data.completed && !_busy,
                      onStatus: _setAttendance,
                      onSelect: (student) => _selectStudent(student, data),
                      onHistory: _showHistory,
                      noteEditor: _selectedStudentId == null
                          ? null
                          : _NoteEditor(
                              student: data.student(_selectedStudentId!),
                              controller: _noteController,
                              hasNote: _selectedNoteId != null,
                              notes: data.notesFor(_selectedStudentId!),
                              selectedNoteId: _selectedNoteId,
                              onSelectNote: (note) {
                                setState(() {
                                  _selectedNoteId = note?.id;
                                  _noteController.text = note?.body ?? '';
                                  _savedNoteText = _noteController.text;
                                });
                              },
                              enabled: !data.completed && !_busy && !_recording,
                              onClose: _closeNote,
                              onDictate: _toggleDictation,
                              recording: _recording,
                              dictationEnabled: !data.completed && !_busy,
                              onSave: () => _saveNote(data),
                              onDelete: () => _deleteNote(data),
                            ),
                    )
                  : _ContentEditor(
                      key: _contentKey,
                      data: data,
                      store: widget.store,
                      lessonId: _lessonId!,
                      onSaved: _reload,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PlannedLesson extends StatelessWidget {
  const _PlannedLesson({
    required this.lesson,
    required this.onStart,
    required this.onBack,
  });
  final TodayLesson lesson;
  final VoidCallback? onStart;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _StaticHeader(lesson: lesson, onBack: onBack),
      Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_outline,
                size: 54,
                color: DaymarkColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Geplante Stunde',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Die Anwesenheit wird beim Start der Stunde angelegt.',
                style: TextStyle(color: DaymarkColors.muted),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onStart,
                icon: Icon(Icons.play_arrow_rounded),
                label: const Text('Stunde starten'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.lesson,
    required this.onBack,
    this.onUndoStart,
    this.onComplete,
    this.onReopen,
  });
  final _LessonDetailData lesson;
  final VoidCallback onBack;
  final VoidCallback? onUndoStart;
  final VoidCallback? onComplete;
  final VoidCallback? onReopen;
  @override
  Widget build(BuildContext context) => _HeaderLayout(
    className: lesson.className,
    subject: lesson.subject,
    day: lesson.day,
    period: lesson.period,
    startTime: lesson.startTime,
    completed: lesson.completed,
    onBack: onBack,
    onUndoStart: onUndoStart,
    onComplete: onComplete,
    onReopen: onReopen,
  );
}

class _StaticHeader extends StatelessWidget {
  const _StaticHeader({required this.lesson, required this.onBack});
  final TodayLesson lesson;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => _HeaderLayout(
    className: lesson.className,
    subject: lesson.subject,
    day: dayKey(lesson.day),
    period: lesson.period,
    startTime: lesson.startTime,
    completed: false,
    onBack: onBack,
  );
}

class _HeaderLayout extends StatelessWidget {
  const _HeaderLayout({
    required this.className,
    required this.subject,
    required this.day,
    required this.period,
    required this.startTime,
    required this.completed,
    required this.onBack,
    this.onComplete,
    this.onReopen,
    this.onUndoStart,
  });
  final String className, subject, day;
  final int period;
  final String? startTime;
  final bool completed;
  final VoidCallback onBack;
  final VoidCallback? onComplete, onReopen, onUndoStart;
  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(day);
    final start = TodayLesson(
      slotId: null,
      classId: 0,
      className: '',
      subject: '',
      period: period,
      day: date,
      startTime: startTime,
    ).startsAt;
    final time =
        '${lessonTime(start)} – ${lessonTime(start?.add(const Duration(minutes: 45)))}';
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 800;
        return Container(
          height: 112,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: DaymarkColors.border)),
          ),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(46, 46),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(Icons.chevron_left, size: 30),
              ),
              const SizedBox(width: 12),
              if (!compact) ...[
                TextButton(
                  onPressed: onBack,
                  child: const Text('Heute', style: TextStyle(fontSize: 20)),
                ),
                const VerticalDivider(width: 40, indent: 24, endIndent: 24),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$className · $subject',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${germanDayLabel(date)} · $period. Stunde · $time',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        color: DaymarkColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                Icon(
                  Icons.circle,
                  size: 14,
                  color: completed
                      ? DaymarkColors.success
                      : const Color(0xff009a4f),
                ),
                const SizedBox(width: 12),
                Text(
                  completed ? 'Abgeschlossen' : 'Begonnen',
                  style: TextStyle(
                    fontSize: 18,
                    color: completed
                        ? DaymarkColors.success
                        : const Color(0xff009a4f),
                  ),
                ),
                const SizedBox(width: 26),
              ],
              if (onUndoStart != null) ...[
                IconButton(
                  onPressed: onUndoStart,
                  tooltip: 'Stundenstart rückgängig machen',
                  icon: const Icon(Icons.refresh_rounded),
                ),
                const SizedBox(width: 8),
              ],
              if (onComplete != null)
                FilledButton(
                  onPressed: onComplete,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(230, 60),
                  ),
                  child: const Text(
                    'Stunde abschließen',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              else if (onReopen != null)
                OutlinedButton(
                  onPressed: onReopen,
                  child: const Text('Stunde erneut öffnen'),
                ),
            ],
          ),
        );
      },
    );
  }
}

enum _DetailTab { attendance, content }

class _Tabs extends StatelessWidget {
  const _Tabs({required this.tab, required this.onChanged});
  final _DetailTab tab;
  final ValueChanged<_DetailTab> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.only(left: 22),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: DaymarkColors.border)),
    ),
    child: Row(
      children: [
        _tab('Anwesenheit', _DetailTab.attendance),
        _tab('Stundeninhalt', _DetailTab.content),
      ],
    ),
  );
  Widget _tab(String label, _DetailTab value) {
    final selected = tab == value;
    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? DaymarkColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 19,
            color: selected ? DaymarkColors.primary : DaymarkColors.muted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _AttendanceBody extends StatelessWidget {
  const _AttendanceBody({
    required this.data,
    required this.selectedStudentId,
    required this.enabled,
    required this.onStatus,
    required this.onSelect,
    required this.onHistory,
    this.noteEditor,
  });
  final _LessonDetailData data;
  final int? selectedStudentId;
  final bool enabled;
  final void Function(int, String) onStatus;
  final ValueChanged<_StudentAttendance> onSelect;
  final ValueChanged<int> onHistory;
  final Widget? noteEditor;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final split = constraints.maxWidth >= 980;
      final table = _AttendancePanel(
        data: data,
        selectedStudentId: selectedStudentId,
        enabled: enabled,
        onStatus: onStatus,
        onSelect: onSelect,
        onHistory: onHistory,
        columns: split ? 2 : 1,
      );
      final note = noteEditor ?? const _EmptyNote();
      return Padding(
        padding: const EdgeInsets.all(10),
        child: split
            ? Row(
                children: [
                  Expanded(flex: 3, child: table),
                  const SizedBox(width: 8),
                  SizedBox(width: 405, child: note),
                ],
              )
            : ListView(
                key: const ValueKey('lesson-detail-narrow-scroll'),
                children: [
                  SizedBox(height: 620, child: table),
                  const SizedBox(height: 10),
                  SizedBox(height: 470, child: note),
                ],
              ),
      );
    },
  );
}

class _AttendancePanel extends StatelessWidget {
  const _AttendancePanel({
    required this.data,
    required this.selectedStudentId,
    required this.enabled,
    required this.onStatus,
    required this.onSelect,
    required this.onHistory,
    required this.columns,
  });
  final _LessonDetailData data;
  final int? selectedStudentId;
  final bool enabled;
  final void Function(int, String) onStatus;
  final ValueChanged<_StudentAttendance> onSelect;
  final ValueChanged<int> onHistory;
  final int columns;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anwesenheit',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            data.attendanceSummary,
            style: TextStyle(fontSize: 18, color: DaymarkColors.muted),
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: constraints.maxWidth < (columns == 2 ? 760 : 380)
                      ? (columns == 2 ? 760 : 380)
                      : constraints.maxWidth,
                  child: Row(
                    children: [
                      for (var column = 0; column < columns; column++)
                        Expanded(
                          child: Column(
                            children: [
                              const _AttendanceHeadings(),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: columns == 1
                                      ? data.students.length
                                      : (data.students.length + 1) ~/ 2,
                                  itemBuilder: (context, index) {
                                    final studentIndex =
                                        index +
                                        (column == 0
                                            ? 0
                                            : (data.students.length + 1) ~/ 2);
                                    if (studentIndex >= data.students.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final student = data.students[studentIndex];
                                    return SizedBox(
                                      height: 42,
                                      child: _StudentRow(
                                        student: student,
                                        selected:
                                            student.studentId ==
                                            selectedStudentId,
                                        enabled: enabled,
                                        onStatus: onStatus,
                                        onSelect: onSelect,
                                        onHistory: onHistory,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AttendanceHeadings extends StatelessWidget {
  const _AttendanceHeadings();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 34,
    child: Row(
      children: [
        SizedBox(width: 28, child: Text('#')),
        Expanded(child: Text('Schüler')),
        SizedBox(width: 46, child: Text('A')),
        SizedBox(width: 46, child: Text('F')),
        SizedBox(width: 46, child: Text('E')),
        SizedBox(width: 46, child: Text('V')),
        SizedBox(width: 48),
      ],
    ),
  );
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.selected,
    required this.enabled,
    required this.onStatus,
    required this.onSelect,
    required this.onHistory,
  });
  final _StudentAttendance student;
  final bool selected, enabled;
  final void Function(int, String) onStatus;
  final ValueChanged<_StudentAttendance> onSelect;
  final ValueChanged<int> onHistory;
  @override
  Widget build(BuildContext context) => Container(
    color: selected ? DaymarkColors.activeSurface : null,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '${student.number}',
            style: TextStyle(color: DaymarkColors.muted),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => onSelect(student),
            child: Text(
              student.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        for (final choice in _AttendanceChoice.values)
          _StatusButton(
            key: ValueKey('attendance-${student.studentId}-${choice.value}'),
            choice: choice,
            selected: student.status == choice.value,
            enabled: enabled,
            onTap: () => onStatus(student.studentId, choice.value),
          ),
        PopupMenuButton<String>(
          tooltip: 'Bemerkung und Historie',
          onSelected: (value) => value == 'history'
              ? onHistory(student.studentId)
              : onSelect(student),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'note', child: Text('Bemerkung')),
            PopupMenuItem(value: 'history', child: Text('Schülerhistorie')),
          ],
          icon: Icon(
            Icons.description_outlined,
            color: selected ? DaymarkColors.primary : DaymarkColors.muted,
          ),
        ),
      ],
    ),
  );
}

enum _AttendanceChoice {
  present('present', 'A', Color(0xff128348)),
  absent('absent', 'F', Color(0xffdf2525)),
  excused('excused', 'E', Color(0xff4c648a)),
  late('late', 'V', Color(0xffe97c00));

  const _AttendanceChoice(this.value, this.label, this.color);
  final String value, label;
  final Color color;
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    super.key,
    required this.choice,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final _AttendanceChoice choice;
  final bool selected, enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: SizedBox(
      width: 42,
      height: 34,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          foregroundColor: selected ? Colors.white : DaymarkColors.muted,
          backgroundColor: selected ? choice.color : DaymarkColors.background,
          side: BorderSide(
            color: selected ? choice.color : DaymarkColors.border,
          ),
        ),
        child: Text(choice.label),
      ),
    ),
  );
}

class _NoteEditor extends StatelessWidget {
  const _NoteEditor({
    required this.student,
    required this.controller,
    required this.hasNote,
    required this.notes,
    required this.selectedNoteId,
    required this.onSelectNote,
    required this.enabled,
    required this.onSave,
    required this.onDelete,
    required this.onClose,
    required this.onDictate,
    required this.recording,
    required this.dictationEnabled,
  });
  final _StudentAttendance student;
  final TextEditingController controller;
  final bool hasNote, enabled, recording, dictationEnabled;
  final List<_LessonNote> notes;
  final int? selectedNoteId;
  final ValueChanged<_LessonNote?> onSelectNote;
  final VoidCallback onSave, onDelete, onClose, onDictate;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bemerkung',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close),
                tooltip: 'Bemerkung schließen',
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            student.name,
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            student.lessonLabel,
            style: TextStyle(fontSize: 18, color: DaymarkColors.muted),
          ),
          if (notes.isNotEmpty)
            DropdownButton<int?>(
              value: selectedNoteId,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Neue Bemerkung'),
                ),
                for (var index = 0; index < notes.length; index++)
                  DropdownMenuItem<int?>(
                    value: notes[index].id,
                    child: Text('Bemerkung ${index + 1}'),
                  ),
              ],
              onChanged: (id) => onSelectNote(
                id == null ? null : notes.firstWhere((note) => note.id == id),
              ),
            ),
          const SizedBox(height: 30),
          const Text(
            'Bemerkung',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Bemerkung zum Schüler',
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: dictationEnabled ? onDictate : null,
            icon: Icon(Icons.mic),
            label: Text(recording ? 'Aufnahme beenden' : 'Diktieren'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: enabled ? onSave : null,
              child: const Text('Bemerkung speichern'),
            ),
          ),
          if (hasNote)
            Center(
              child: TextButton(
                onPressed: enabled ? onDelete : null,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Bemerkung löschen'),
              ),
            ),
        ],
      ),
    ),
  );
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote();
  @override
  Widget build(BuildContext context) => _Panel(
    child: Center(
      child: Text(
        'Schüler für eine Bemerkung auswählen.',
        textAlign: TextAlign.center,
        style: TextStyle(color: DaymarkColors.muted),
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: DaymarkColors.surface,
      border: Border.all(color: DaymarkColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: child,
  );
}

class _ContentEditor extends StatefulWidget {
  const _ContentEditor({
    super.key,
    required this.data,
    required this.store,
    required this.lessonId,
    required this.onSaved,
  });
  final _LessonDetailData data;
  final DaymarkStore store;
  final int lessonId;
  final VoidCallback onSaved;
  @override
  State<_ContentEditor> createState() => _ContentEditorState();
}

class _ContentEditorState extends State<_ContentEditor> {
  bool _saving = false;
  late String _savedTopic = widget.data.topic;
  late String _savedSummary = widget.data.summary;
  late String _savedHomework = widget.data.homework;
  bool get dirty =>
      _topic.text != _savedTopic ||
      _summary.text != _savedSummary ||
      _homework.text != _savedHomework;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.store.updateLessonDetails(
        widget.lessonId,
        _topic.text,
        _summary.text,
        _homework.text,
      );
      _savedTopic = _topic.text.trim();
      _savedSummary = _summary.text.trim();
      _savedHomework = _homework.text.trim();
      if (mounted) widget.onSaved();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stundeninhalt konnte nicht gespeichert werden: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  late final TextEditingController _topic = TextEditingController(
    text: widget.data.topic,
  );
  late final TextEditingController _summary = TextEditingController(
    text: widget.data.summary,
  );
  late final TextEditingController _homework = TextEditingController(
    text: widget.data.homework,
  );
  @override
  void dispose() {
    _topic.dispose();
    _summary.dispose();
    _homework.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(22),
    child: _Panel(
      child: ListView(
        padding: const EdgeInsets.all(26),
        children: [
          const Text(
            'Stundeninhalt',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 22),
          _editorField(context, 'Thema', 'Thema eingeben', _topic),
          const SizedBox(height: 20),
          _editorField(
            context,
            'Stundennotiz',
            'Was wurde in der Stunde behandelt?',
            _summary,
            lines: 5,
          ),
          const SizedBox(height: 20),
          _editorField(
            context,
            'Hausaufgaben',
            'Hausaufgaben eintragen',
            _homework,
            lines: 4,
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: widget.data.completed || _saving ? null : _save,
              child: const Text('Speichern'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _editorField(
    BuildContext context,
    String label,
    String hint,
    TextEditingController controller, {
    int lines = 1,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          key: ValueKey('lesson-${label.toLowerCase()}'),
          controller: controller,
          enabled: !widget.data.completed,
          maxLines: lines,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.onSurfaceVariant),
            filled: true,
            fillColor: colors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _LessonDetailData {
  const _LessonDetailData({
    required this.className,
    required this.subject,
    required this.day,
    required this.period,
    required this.startTime,
    required this.completed,
    required this.topic,
    required this.summary,
    required this.homework,
    required this.students,
    required this.notes,
  });
  final String className, subject, day, topic, summary, homework;
  final int period;
  final String? startTime;
  final bool completed;
  final List<_StudentAttendance> students;
  final List<_LessonNote> notes;
  factory _LessonDetailData.fromRows(
    Map<String, Object?> lesson,
    List<Map<String, Object?>> attendance,
    List<Map<String, Object?>> notes,
  ) => _LessonDetailData(
    className: lesson['class_name'] as String,
    subject: lesson['subject'] as String,
    day: lesson['day'] as String,
    period: lesson['period'] as int,
    startTime: lesson['start_time'] as String?,
    completed: lesson['completed'] == 1,
    topic: lesson['topic'] as String? ?? '',
    summary: lesson['summary'] as String? ?? '',
    homework: lesson['homework'] as String? ?? '',
    students: [
      for (var index = 0; index < attendance.length; index++)
        _StudentAttendance.fromRow(attendance[index], index + 1, lesson),
    ],
    notes: notes.map(_LessonNote.fromRow).toList(),
  );
  List<_LessonNote> notesFor(int studentId) =>
      notes.where((note) => note.studentId == studentId).toList();

  _LessonNote? latestNoteFor(int studentId) {
    for (final note in notes) {
      if (note.studentId == studentId) return note;
    }
    return null;
  }

  _StudentAttendance student(int id) =>
      students.firstWhere((student) => student.studentId == id);
  String get attendanceSummary {
    final present = students.where((s) => s.status == 'present').length;
    final absent = students.where((s) => s.status == 'absent').length;
    final late = students.where((s) => s.status == 'late').length;
    return '$present anwesend · $absent fehlt · $late verspätet';
  }
}

class _StudentAttendance {
  const _StudentAttendance({
    required this.studentId,
    required this.number,
    required this.name,
    required this.status,
    required this.lessonLabel,
  });
  final int studentId, number;
  final String name, status, lessonLabel;
  factory _StudentAttendance.fromRow(
    Map<String, Object?> row,
    int number,
    Map<String, Object?> lesson,
  ) => _StudentAttendance(
    studentId: row['student_id'] as int,
    number: number,
    name: '${row['last_name']}, ${row['first_name']}',
    status: row['status'] as String,
    lessonLabel:
        '${lesson['class_name']} · ${lesson['subject']} · ${lesson['period']}. Stunde',
  );
}

class _LessonNote {
  const _LessonNote({
    required this.id,
    required this.studentId,
    required this.body,
  });
  final int id, studentId;
  final String body;
  factory _LessonNote.fromRow(Map<String, Object?> row) => _LessonNote(
    id: row['id'] as int,
    studentId: row['student_id'] as int,
    body: row['body'] as String,
  );
}
