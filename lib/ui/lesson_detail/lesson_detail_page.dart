import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/daymark_store.dart';
import '../../data/lesson_preparation_repository.dart';
import '../../data/offline_dictation.dart';
import '../../domain/today_schedule.dart';
import '../lesson_preparation/lesson_preparation_editor.dart';
import '../lesson_preparation/lesson_preparation_view_model.dart';
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
  Timer? _noteSaveTimer;
  Future<void> _noteSaveOperation = Future<void>.value();
  int _pendingNoteWrites = 0;
  String? _noteSaveError;
  final _contentKey = GlobalKey<_ContentEditorState>();
  late final LessonPreparationViewModel? _preparationViewModel;

  @override
  void initState() {
    super.initState();
    final slotId = widget.lesson.slotId;
    _preparationViewModel = slotId == null
        ? null
        : LessonPreparationViewModel(
            LessonPreparationRepository(widget.store),
            slotId: slotId,
            day: widget.lesson.day,
          );
    _preparationViewModel?.load();
  }

  @override
  void dispose() {
    _noteSaveTimer?.cancel();
    _dictation.cancel();
    _noteController.dispose();
    _preparationViewModel?.dispose();
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

  Future<void> _start() async {
    final preparation = _preparationViewModel;
    if (preparation?.dirty == true && !await preparation!.save()) return;
    await _change(() async {
      final slot = <String, Object?>{
        'id': widget.lesson.slotId,
        'class_id': widget.lesson.classId,
        'subject': widget.lesson.subject,
        'period': widget.lesson.period,
      };
      final id = await widget.store.openLesson(slot, dayKey(widget.lesson.day));
      if (mounted) setState(() => _lessonId = id);
    });
  }

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

  Future<bool> _savePendingNote() async {
    _noteSaveTimer?.cancel();
    await _persistCurrentNote();
    return _noteSaveError == null;
  }

  void _scheduleNoteSave(String _) {
    _noteSaveTimer?.cancel();
    if (_noteSaveError != null && mounted) {
      setState(() => _noteSaveError = null);
    }
    _noteSaveTimer = Timer(
      const Duration(milliseconds: 600),
      () => unawaited(_persistCurrentNote()),
    );
  }

  Future<void> _persistCurrentNote() {
    _noteSaveTimer?.cancel();
    _noteSaveTimer = null;
    final lessonId = _lessonId;
    final studentId = _selectedStudentId;
    final body = _noteController.text.trim();
    if (lessonId == null ||
        studentId == null ||
        body == (_savedNoteText ?? '')) {
      return _noteSaveOperation;
    }
    if (mounted) {
      setState(() {
        _pendingNoteWrites++;
        _noteSaveError = null;
      });
    }
    final operation = _noteSaveOperation.then((_) async {
      try {
        final noteId = await widget.store.saveStudentLessonNote(
          lessonId,
          studentId,
          body,
        );
        if (mounted && _selectedStudentId == studentId) {
          setState(() {
            _selectedNoteId = noteId;
            _savedNoteText = body;
            _data = _load();
          });
        }
      } catch (error) {
        if (mounted && _selectedStudentId == studentId) {
          setState(() => _noteSaveError = 'Speichern fehlgeschlagen');
          _showError(error);
        }
      } finally {
        if (mounted) {
          setState(() => _pendingNoteWrites--);
        }
      }
    });
    _noteSaveOperation = operation;
    return operation;
  }

  Future<void> _back() async {
    if (await _mayLeave() && mounted) {
      await _cancelRecording();
      if (mounted) widget.onBack();
    }
  }

  Future<bool> _mayLeave() async {
    if (!await _savePendingNote() || !mounted) return false;
    if (_contentKey.currentState?.dirty == true) {
      final discard =
          await showDialog<bool>(
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
      if (!discard) return false;
    }
    if (!mounted) return false;
    final preparation = _preparationViewModel;
    if (preparation?.dirty == true) {
      final discard =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Ungespeicherte Vorbereitung'),
              content: const Text(
                'Änderungen an den Vorbereitungsnotizen verwerfen?',
              ),
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
      if (!discard) return false;
      preparation!.discardChanges();
    }
    return true;
  }

  Future<void> _selectTab(_DetailTab tab) async {
    if (tab == _tab || !await _mayLeave() || !mounted) return;
    await _cancelRecording();
    if (mounted) setState(() => _tab = tab);
  }

  Future<void> _selectStudent(_StudentAttendance student) async {
    if (!await _savePendingNote() || !mounted) return;
    await _cancelRecording();
    try {
      final row = await widget.store.studentLessonNote(
        _lessonId!,
        student.studentId,
      );
      if (!mounted) return;
      final note = row == null ? null : _LessonNote.fromRow(row);
      setState(() {
        _selectedStudentId = student.studentId;
        _selectedNoteId = note?.id;
        _noteController.text = note?.body ?? '';
        _savedNoteText = _noteController.text.trim();
        _noteSaveError = null;
      });
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _deleteNote() async {
    final studentId = _selectedStudentId;
    if (studentId == null || _selectedNoteId == null) return;
    _noteSaveTimer?.cancel();
    await _change(() async {
      await widget.store.saveStudentLessonNote(_lessonId!, studentId, '');
      _selectedNoteId = null;
      _noteController.clear();
      _savedNoteText = '';
      _noteSaveError = null;
    });
  }

  Future<void> _closeNote() async {
    if (!await _savePendingNote() || !mounted) return;
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
          _scheduleNoteSave(_noteController.text);
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
        preparationViewModel: _preparationViewModel,
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
        final preparation = _preparationViewModel;
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
              child: switch (_tab) {
                _DetailTab.attendance => _AttendanceBody(
                  data: data,
                  selectedStudentId: _selectedStudentId,
                  enabled: !data.completed && !_busy,
                  onStatus: _setAttendance,
                  onAddNote: _selectStudent,
                  noteEditor: _selectedStudentId == null
                      ? null
                      : _NoteEditor(
                          student: data.student(_selectedStudentId!),
                          controller: _noteController,
                          hasNote: _selectedNoteId != null,
                          enabled: !data.completed && !_busy && !_recording,
                          saving: _pendingNoteWrites > 0,
                          saveError: _noteSaveError,
                          onChanged: _scheduleNoteSave,
                          onClose: _closeNote,
                          onDictate: _toggleDictation,
                          recording: _recording,
                          dictationEnabled: !data.completed && !_busy,
                          onDelete: _deleteNote,
                        ),
                ),
                _DetailTab.content => _ContentEditor(
                  key: _contentKey,
                  data: data,
                  store: widget.store,
                  lessonId: _lessonId!,
                  onSaved: _reload,
                ),
                _DetailTab.preparation =>
                  preparation == null
                      ? const _PreparationUnavailable()
                      : Padding(
                          padding: const EdgeInsets.all(22),
                          child: LessonPreparationEditor(
                            viewModel: preparation,
                            readOnly: data.completed,
                          ),
                        ),
              },
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
    required this.preparationViewModel,
  });

  final TodayLesson lesson;
  final VoidCallback? onStart;
  final VoidCallback onBack;
  final LessonPreparationViewModel? preparationViewModel;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _StaticHeader(lesson: lesson, onBack: onBack),
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final start = _PlannedLessonStart(onStart: onStart);
            final preparation = preparationViewModel == null
                ? const _PreparationUnavailable()
                : LessonPreparationEditor(viewModel: preparationViewModel!);
            if (constraints.maxWidth < 850) {
              return ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  SizedBox(height: 230, child: start),
                  const SizedBox(height: 16),
                  SizedBox(height: 500, child: preparation),
                ],
              );
            }
            return Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 2, child: start),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: preparation),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _PlannedLessonStart extends StatelessWidget {
  const _PlannedLessonStart({required this.onStart});

  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: DaymarkColors.surface,
      border: Border.all(color: DaymarkColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              textAlign: TextAlign.center,
              style: TextStyle(color: DaymarkColors.muted),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Stunde starten'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PreparationUnavailable extends StatelessWidget {
  const _PreparationUnavailable();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Für diese historische Stunde sind keine Vorbereitungsnotizen verfügbar.',
        textAlign: TextAlign.center,
        style: TextStyle(color: DaymarkColors.muted),
      ),
    ),
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
    started: true,
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
    started: false,
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
    required this.started,
    required this.completed,
    required this.onBack,
    this.onComplete,
    this.onReopen,
    this.onUndoStart,
  });

  final String className, subject, day;
  final int period;
  final String? startTime;
  final bool started, completed;
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
              if (!compact && started) ...[
                Icon(Icons.circle, size: 14, color: DaymarkColors.success),
                const SizedBox(width: 12),
                Text(
                  completed ? 'Abgeschlossen' : 'Begonnen',
                  style: TextStyle(fontSize: 18, color: DaymarkColors.success),
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

enum _DetailTab { attendance, content, preparation }

class _Tabs extends StatelessWidget {
  const _Tabs({required this.tab, required this.onChanged});

  final _DetailTab tab;
  final ValueChanged<_DetailTab> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('lesson-detail-tabs'),
    width: double.infinity,
    height: 58,
    padding: const EdgeInsets.only(left: 22),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: DaymarkColors.border)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tab('Anwesenheit', _DetailTab.attendance),
          _tab('Stundeninhalt', _DetailTab.content),
          _tab('Vorbereitung', _DetailTab.preparation),
        ],
      ),
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
    required this.onAddNote,
    this.noteEditor,
  });

  final _LessonDetailData data;
  final int? selectedStudentId;
  final bool enabled;
  final void Function(int, String) onStatus;
  final ValueChanged<_StudentAttendance> onAddNote;
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
        onAddNote: onAddNote,
        maxTableWidth: noteEditor == null ? null : 760,
      );
      final showNote = noteEditor != null;
      return Padding(
        padding: const EdgeInsets.all(22),
        child: split
            ? showNote
                  ? Row(
                      children: [
                        Expanded(flex: 3, child: table),
                        const SizedBox(width: 8),
                        SizedBox(width: 405, child: noteEditor!),
                      ],
                    )
                  : table
            : ListView(
                key: const ValueKey('lesson-detail-narrow-scroll'),
                children: [
                  SizedBox(height: 620, child: table),
                  if (showNote) ...[
                    const SizedBox(height: 10),
                    SizedBox(height: 470, child: noteEditor!),
                  ],
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
    required this.onAddNote,
    required this.maxTableWidth,
  });

  final _LessonDetailData data;
  final int? selectedStudentId;
  final bool enabled;
  final void Function(int, String) onStatus;
  final ValueChanged<_StudentAttendance> onAddNote;
  final double? maxTableWidth;

  @override
  Widget build(BuildContext context) {
    final studentList = Column(
      children: [
        const _AttendanceHeadings(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(right: 20),
            itemCount: data.students.length,
            itemBuilder: (context, index) {
              final student = data.students[index];
              return SizedBox(
                height: 50,
                child: _StudentRow(
                  student: student,
                  selected: student.studentId == selectedStudentId,
                  enabled: enabled,
                  onStatus: onStatus,
                  onAddNote: onAddNote,
                ),
              );
            },
          ),
        ),
      ],
    );
    return _Panel(
      key: const ValueKey('lesson-attendance-card'),
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
              child: maxTableWidth == null
                  ? studentList
                  : Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxTableWidth!),
                        child: studentList,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceHeadings extends StatelessWidget {
  const _AttendanceHeadings();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 24, 0),
    child: SizedBox(
      height: 34,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text('#', style: TextStyle(color: DaymarkColors.muted)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Schüler',
              style: TextStyle(color: DaymarkColors.muted),
            ),
          ),
          const SizedBox(width: 184, child: Center(child: Text('Anwesenheit'))),
          const Expanded(flex: 1,child: SizedBox()),
          const SizedBox(width: 48, child: Center(child: Text('Notiz'))),
        ],
      ),
    ),
  );
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.selected,
    required this.enabled,
    required this.onStatus,
    required this.onAddNote,
  });

  final _StudentAttendance student;
  final bool selected, enabled;
  final void Function(int, String) onStatus;
  final ValueChanged<_StudentAttendance> onAddNote;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: selected ? DaymarkColors.activeSurface : null,
      border: Border(bottom: BorderSide(color: DaymarkColors.border)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            '${student.number}',
            style: TextStyle(color: DaymarkColors.muted),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            student.name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16),
          ),
        ),
        SizedBox(
          width: 184,
          child: Row(
            children: [
              for (final choice in _AttendanceChoice.values)
                _StatusButton(
                  key: ValueKey(
                    'attendance-${student.studentId}-${choice.value}',
                  ),
                  choice: choice,
                  selected: student.status == choice.value,
                  enabled: enabled,
                  onTap: () => onStatus(student.studentId, choice.value),
                ),
            ],
          ),
        ),
        const Expanded(flex: 1,child: SizedBox()),
        IconButton(
          key: ValueKey('add-student-note-${student.studentId}'),
          tooltip: 'Bemerkung öffnen',
          onPressed: () => onAddNote(student),
          icon: Icon(
            student.hasNote
                ? Icons.sticky_note_2
                : Icons.sticky_note_2_outlined,
            color: student.hasNote || selected
                ? DaymarkColors.primary
                : DaymarkColors.muted,
          ),
        ),
      ],
    ),
  );
}

enum _AttendanceChoice {
  present('present', 'Anwesend', Icons.check_circle_outline),
  absent('absent', 'Fehlt', Icons.cancel_outlined),
  excused('excused', 'Entschuldigt', Icons.event_busy_outlined),
  late('late', 'Verspätet', Icons.schedule);

  const _AttendanceChoice(this.value, this.label, this.icon);

  final String value, label;
  final IconData icon;
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
  Widget build(BuildContext context) {
    final statusColor = switch (choice) {
      _AttendanceChoice.present => DaymarkColors.success,
      _AttendanceChoice.absent => DaymarkColors.error,
      _AttendanceChoice.excused => DaymarkColors.muted,
      _AttendanceChoice.late => DaymarkColors.warning,
    };
    final onStatusColor = switch (choice) {
      _AttendanceChoice.present => DaymarkColors.current.onSuccess,
      _AttendanceChoice.absent => DaymarkColors.current.onError,
      _AttendanceChoice.excused => DaymarkColors.background,
      _AttendanceChoice.late => DaymarkColors.current.onWarning,
    };
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: SizedBox(
        width: 42,
        height: 34,
        child: OutlinedButton(
          onPressed: enabled ? onTap : null,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            foregroundColor: selected ? onStatusColor : DaymarkColors.muted,
            backgroundColor: selected ? statusColor : DaymarkColors.background,
            side: BorderSide(
              color: selected ? statusColor : DaymarkColors.border,
            ),
          ),
          child: Tooltip(
            message: choice.label,
            child: Semantics(
              label: choice.label,
              button: true,
              selected: selected,
              child: Icon(choice.icon, size: 21),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteEditor extends StatelessWidget {
  const _NoteEditor({
    required this.student,
    required this.controller,
    required this.hasNote,
    required this.enabled,
    required this.saving,
    required this.saveError,
    required this.onChanged,
    required this.onDelete,
    required this.onClose,
    required this.onDictate,
    required this.recording,
    required this.dictationEnabled,
  });

  final _StudentAttendance student;
  final TextEditingController controller;
  final bool hasNote, enabled, saving, recording, dictationEnabled;
  final String? saveError;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete, onClose, onDictate;

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
          const SizedBox(height: 24),
          const Text(
            'Bemerkung',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              onChanged: onChanged,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Bemerkung zum Schüler',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            saveError ??
                (saving
                    ? 'Wird gespeichert…'
                    : hasNote
                    ? 'Gespeichert'
                    : 'Wird automatisch gespeichert'),
            style: TextStyle(
              color: saveError == null
                  ? DaymarkColors.muted
                  : DaymarkColors.error,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: dictationEnabled ? onDictate : null,
            icon: Icon(Icons.mic),
            label: Text(recording ? 'Aufnahme beenden' : 'Diktieren'),
          ),
          if (hasNote)
            Center(
              child: TextButton(
                onPressed: enabled ? onDelete : null,
                style: TextButton.styleFrom(
                  foregroundColor: DaymarkColors.error,
                ),
                child: const Text('Bemerkung löschen'),
              ),
            ),
        ],
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.child});

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
  });

  final String className, subject, day, topic, summary, homework;
  final int period;
  final String? startTime;
  final bool completed;
  final List<_StudentAttendance> students;

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
        _StudentAttendance.fromRow(
          attendance[index],
          index + 1,
          notes.any(
            (note) => note['student_id'] == attendance[index]['student_id'],
          ),
        ),
    ],
  );

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
    required this.hasNote,
  });

  final int studentId, number;
  final String name, status;
  final bool hasNote;

  factory _StudentAttendance.fromRow(
    Map<String, Object?> row,
    int number,
    bool hasNote,
  ) => _StudentAttendance(
    studentId: row['student_id'] as int,
    number: number,
    name: '${row['last_name']}, ${row['first_name']}',
    status: row['status'] as String,
    hasNote: hasNote,
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
