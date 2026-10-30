import 'package:flutter/material.dart';

import '../../data/daymark_store.dart';
import '../../domain/iso_day.dart';

class FreeDaysDialog extends StatefulWidget {
  const FreeDaysDialog({super.key, required this.store});
  final DaymarkStore store;

  @override
  State<FreeDaysDialog> createState() => _FreeDaysDialogState();
}

class _FreeDaysDialogState extends State<FreeDaysDialog> {
  late Future<List<(String, String)>> _days = _load();

  Future<List<(String, String)>> _load() async => [
    for (final row in await widget.store.freeDays())
      (row['day'] as String, row['label'] as String),
  ];

  void _reload() => setState(() => _days = _load());

  Future<void> _add() async {
    var day = '';
    var label = '';
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schulfreien Tag hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Datum (JJJJ-MM-TT)',
              ),
              onChanged: (value) => day = value,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Bezeichnung'),
              onChanged: (value) => label = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (!mounted || save != true) return;
    if (!isIsoDay(day) || label.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datum oder Bezeichnung ungültig.')),
      );
      return;
    }
    await _run(() => widget.store.addFreeDay(day, label));
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Schulfreie Tage'),
    content: SizedBox(
      width: 560,
      height: 420,
      child: FutureBuilder<List<(String, String)>>(
        future: _days,
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
          return ListView(
            children: [
              const ListTile(
                title: Text('NRW-Ferien und Feiertage sind integriert.'),
              ),
              for (final (day, label) in snapshot.data!)
                ListTile(
                  title: Text(day),
                  subtitle: Text(label),
                  trailing: IconButton(
                    tooltip: 'Löschen',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        _run(() => widget.store.removeFreeDay(day)),
                  ),
                ),
            ],
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Schließen'),
      ),
      FilledButton.icon(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Tag hinzufügen'),
      ),
    ],
  );
}
