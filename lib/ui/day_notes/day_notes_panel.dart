import 'package:flutter/material.dart';

import '../../data/day_notes_repository.dart';
import '../../data/daymark_store.dart';
import '../../domain/day_note.dart';
import '../theme/daymark_theme.dart';

class DayNotesPanel extends StatefulWidget {
  const DayNotesPanel({super.key, required this.store, required this.date});

  final DaymarkStore store;
  final DateTime date;

  @override
  State<DayNotesPanel> createState() => _DayNotesPanelState();
}

class _DayNotesPanelState extends State<DayNotesPanel> {
  late Future<List<DayNote>> _notes = _repository.forDay(widget.date);
  bool _saving = false;

  DayNotesRepository get _repository => DayNotesRepository(widget.store);

  void _reload() => setState(() => _notes = _repository.forDay(widget.date));

  Future<void> _edit([DayNote? note]) async {
    var text = note?.body ?? '';
    final body = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note == null ? 'Eintrag hinzufügen' : 'Eintrag bearbeiten'),
        content: SizedBox(
          width: 440,
          child: TextFormField(
            initialValue: text,
            onChanged: (value) => text = value,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Notiz',
              hintText: 'Was ist an diesem Tag wichtig?',
              border: OutlineInputBorder(),
            ),
          ),
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
    if (body == null || !mounted) return;
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte eine Notiz eingeben.')),
      );
      return;
    }
    await _run(
      () => note == null
          ? _repository.add(widget.date, body)
          : _repository.update(note, body),
    );
  }

  Future<void> _delete(DayNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: const Text('Die Notiz wird dauerhaft entfernt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _run(() => _repository.delete(note));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
      if (mounted) _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eintrag konnte nicht gespeichert werden: $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<DayNote>>(
    future: _notes,
    builder: (context, snapshot) {
      final notes = snapshot.data;
      return Container(
        decoration: BoxDecoration(
          color: DaymarkColors.surface,
          border: Border.all(color: DaymarkColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tagesnotizen',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (notes?.isNotEmpty ?? false)
                    Tooltip(
                      message: 'Eintrag hinzufügen',
                      child: TextButton.icon(
                        onPressed: _saving ? null : _edit,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Eintrag'),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 22, endIndent: 22),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (snapshot.hasError) {
                    return Center(
                      child: TextButton(
                        onPressed: _reload,
                        child: const Text(
                          'Einträge konnten nicht geladen werden · Wiederholen',
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final loadedNotes = notes!;
                  if (loadedNotes.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sticky_note_2_outlined,
                              size: 38,
                              color: DaymarkColors.muted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Noch keine Einträge für diesen Tag.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: DaymarkColors.muted),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _saving ? null : _edit,
                              icon: const Icon(Icons.add),
                              label: const Text('Eintrag hinzufügen'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(18),
                    itemCount: loadedNotes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final note = loadedNotes[index];
                      return Container(
                        constraints: const BoxConstraints(minHeight: 66),
                        decoration: BoxDecoration(
                          color: DaymarkColors.background,
                          border: Border.all(color: DaymarkColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 9),
                                  child: Text(
                                    note.body,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Eintragsaktionen',
                                enabled: !_saving,
                                onSelected: (action) => action == 'edit'
                                    ? _edit(note)
                                    : _delete(note),
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Bearbeiten'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Löschen'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
