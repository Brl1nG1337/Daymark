import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/daymark_store.dart';
import '../../domain/iso_day.dart';
import '../theme/daymark_theme.dart';
import 'free_days_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.store,
    required this.onSessionEnded,
    required this.onThemeChanged,
  });
  final DaymarkStore store;
  final VoidCallback onSessionEnded;
  final ValueChanged<ThemeMode> onThemeChanged;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _selectedTheme;
  static const _defaultTimes = [
    '08:00',
    '08:55',
    '09:55',
    '10:55',
    '11:50',
    '12:45',
    '13:45',
    '14:40',
  ];
  late Future<Map<String, String>> _settings = _load();
  Future<Map<String, String>> _load() async {
    final keys = [
      'school_year',
      'school_start',
      'theme',
      for (var i = 1; i <= 8; i++) 'period_$i',
    ];
    final values = await Future.wait(keys.map(widget.store.setting));
    return {
      for (var i = 0; i < keys.length; i++)
        if (values[i] != null) keys[i]: values[i]!,
    };
  }

  void _reload() => setState(() => _settings = _load());
  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  void _error(Object error) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
  Future<bool> _run(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) _reload();
      return true;
    } catch (error) {
      if (mounted) _error(error);
      return false;
    }
  }

  Future<String?> _prompt(
    String title, {
    String initial = '',
    bool secret = false,
  }) async {
    var text = initial;
    final answer = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initial,
          onChanged: (value) => text = value,
          obscureText: secret,
          autofocus: true,
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text),
            child: const Text('Übernehmen'),
          ),
        ],
      ),
    );
    return answer;
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Bestätigen'),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _editTime(int period, String current) async {
    final value = await _prompt(
      '$period. Stunde: Startzeit (HH:MM)',
      initial: current,
    );
    if (value == null) return;
    if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value)) {
      if (mounted) _error('Ungültige Uhrzeit.');
      return;
    }
    await _run(() => widget.store.setSetting('period_$period', value));
  }

  bool _validSchoolYear(String value) {
    if (!RegExp(r'^\d{4}/\d{2}$').hasMatch(value)) return false;
    final first = int.parse(value.substring(0, 4));
    return value == '$first/${((first + 1) % 100).toString().padLeft(2, '0')}';
  }

  Future<void> _editAllTimes(Map<String, String> settings) async {
    final starts = [
      for (var i = 1; i <= 8; i++)
        settings['period_$i'] ?? _defaultTimes[i - 1],
    ];
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unterrichtszeiten bearbeiten'),
        content: SizedBox(
          width: 420,
          height: 480,
          child: ListView(
            children: [
              for (var index = 0; index < 8; index++)
                TextFormField(
                  initialValue: starts[index],
                  decoration: InputDecoration(
                    labelText: '${index + 1}. Stunde · Startzeit',
                  ),
                  onChanged: (value) => starts[index] = value,
                ),
            ],
          ),
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
    if (accepted == true) await _run(() => widget.store.setPeriodTimes(starts));
  }

  Future<void> _export() async {
    final location = await getSaveLocation(
      suggestedName: 'daymark-backup.sqlite',
    );
    if (location == null) return;
    if (!mounted) return;
    if (await File(location.path).exists() &&
        !await _confirm(
          'Backup ersetzen?',
          'Die Datei am Ziel wird überschrieben.',
        )) {
      return;
    }
    if (await _run(() => widget.store.exportBackup(File(location.path))) &&
        mounted) {
      _message('Verschlüsseltes Backup exportiert.');
    }
  }

  Future<void> _import() async {
    final chosen = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Daymark-Datenbank', extensions: ['sqlite']),
      ],
    );
    if (chosen == null || !mounted) return;
    final password = await _prompt('Passwort des Backups', secret: true);
    if (password == null || !mounted) return;
    if (!await _confirm(
      'Backup importieren?',
      'Die aktuelle Datenbank wird ersetzt und die App kehrt zur Anmeldung zurück.',
    )) {
      return;
    }
    try {
      await widget.store.importBackup(File(chosen.path), password);
      if (mounted) widget.onSessionEnded();
    } catch (error) {
      if (mounted) {
        _error(error);
        if (widget.store.isClosed) widget.onSessionEnded();
      }
    }
  }

  Future<void> _changePassword() async {
    final old = await _prompt('Aktuelles Passwort', secret: true);
    if (old == null || !mounted) return;
    final next = await _prompt('Neues Passwort', secret: true);
    if (next == null || !mounted) return;
    final again = await _prompt('Neues Passwort wiederholen', secret: true);
    if (again != next) {
      if (mounted) _error('Passwörter stimmen nicht überein.');
      return;
    }
    if (await _run(() => widget.store.changePasswordVerified(old, next)) &&
        mounted) {
      _message('Passwort geändert.');
    }
  }

  Future<void> _delete() async {
    if (!await _confirm(
      'App-Daten löschen?',
      'Alle lokalen Klassen, Stunden und Bemerkungen werden unwiderruflich gelöscht.',
    )) {
      return;
    }
    try {
      await widget.store.deleteAppData();
      if (mounted) widget.onSessionEnded();
    } catch (error) {
      if (mounted) _error(error);
    }
  }

  Future<void> _manageModel() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline-Modell verwalten'),
        content: const Text(
          'Ein eigenes lokales Whisper-Modell importieren oder entfernen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'remove'),
            child: const Text('Eigenes Modell entfernen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'import'),
            child: const Text('Modell importieren'),
          ),
        ],
      ),
    );
    if (choice == 'import') await _importModel();
    if (choice == 'remove') {
      if (!mounted ||
          !await _confirm(
            'Modell entfernen?',
            'Das eigene lokale Modell wird gelöscht. Ein mitgeliefertes Modell bleibt erhalten.',
          )) {
        return;
      }
      await _run(() async {
        final root = await getApplicationSupportDirectory();
        final model = File(p.join(root.path, 'whisper', 'ggml-base.bin'));
        if (await model.exists()) await model.delete();
      });
    }
  }

  Future<void> _importModel() async {
    final chosen = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Whisper-Modell', extensions: ['bin']),
      ],
    );
    if (chosen == null) return;
    await _run(() async {
      final root = await getApplicationSupportDirectory();
      final directory = Directory(p.join(root.path, 'whisper'));
      await directory.create(recursive: true);
      final destination = File(p.join(directory.path, 'ggml-base.bin'));
      final temporary = File('${destination.path}.tmp');
      try {
        await File(chosen.path).copy(temporary.path);
        if (await temporary.length() == 0) {
          throw const FormatException('Modell-Datei ist leer.');
        }
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
    });
  }

  Future<void> _popup(String title, Widget content) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(child: content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _row(
    String title,
    IconData icon,
    VoidCallback action, {
    String? subtitle,
  }) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: action,
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, String>>(
    future: _settings,
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
      final settings = snapshot.data!;
      final year = DateTime.now().month >= 8
          ? DateTime.now().year
          : DateTime.now().year - 1;
      final schoolYear =
          settings['school_year'] ??
          '$year/${(year + 1).toString().substring(2)}';
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Einstellungen',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _panel('Alle Einstellungen', [
                    _row(
                      'Unterrichtszeiten',
                      Icons.schedule,
                      () => _popup(
                        'Unterrichtszeiten',
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 1; i <= 8; i++)
                              ListTile(
                                title: Text('$i. Stunde'),
                                subtitle: Text(
                                  _timeLabel(
                                    settings['period_$i'] ??
                                        _defaultTimes[i - 1],
                                  ),
                                ),
                                onTap: () => _editTime(
                                  i,
                                  settings['period_$i'] ?? _defaultTimes[i - 1],
                                ),
                              ),
                            FilledButton(
                              onPressed: () => _editAllTimes(settings),
                              child: const Text('Zeiten bearbeiten'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _row(
                      'Aktuelles Schuljahr',
                      Icons.school_outlined,
                      () async {
                        final value = await _prompt(
                          'Schuljahr (JJJJ/JJ)',
                          initial: schoolYear,
                        );
                        if (value == null) return;
                        if (!_validSchoolYear(value)) {
                          if (mounted) _error('Ungültiges Schuljahr.');
                          return;
                        }
                        await _run(
                          () => widget.store.setSetting('school_year', value),
                        );
                      },
                      subtitle: schoolYear,
                    ),
                    _row('Standard-Startdatum', Icons.event_outlined, () async {
                      final value = await _prompt(
                        'Standard-Startdatum (JJJJ-MM-TT)',
                        initial: settings['school_start'] ?? '$year-08-01',
                      );
                      if (value == null) return;
                      if (!isIsoDay(value)) {
                        if (mounted) _error('Ungültiges Datum.');
                        return;
                      }
                      await _run(
                        () => widget.store.setSetting('school_start', value),
                      );
                    }, subtitle: settings['school_start'] ?? '$year-08-01'),
                    _row(
                      'Schulfreie Tage',
                      Icons.event_busy_outlined,
                      () => showDialog<void>(
                        context: context,
                        builder: (context) =>
                            FreeDaysDialog(store: widget.store),
                      ),
                    ),
                    const ListTile(
                      leading: Icon(Icons.lock_outline),
                      title: Text('Lokale Datenbank verschlüsselt'),
                      trailing: Text('Aktiv'),
                    ),
                    _row(
                      'Backup exportieren',
                      Icons.download,
                      () => _popup(
                        'Backup exportieren',
                        FilledButton(
                          onPressed: _export,
                          child: const Text('Speicherort auswählen'),
                        ),
                      ),
                    ),
                    _row(
                      'Backup importieren',
                      Icons.upload,
                      () => _popup(
                        'Backup importieren',
                        FilledButton(
                          onPressed: _import,
                          child: const Text('Backup auswählen'),
                        ),
                      ),
                    ),
                    _row('Passwort ändern', Icons.key, _changePassword),
                    _row('App-Daten löschen', Icons.delete_outline, _delete),
                    _row(
                      'Offline-Diktat',
                      Icons.mic_none,
                      () => _popup(
                        'Offline-Diktat',
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FutureBuilder<bool>(
                              future: _modelAvailable(),
                              builder: (context, snapshot) => ListTile(
                                title: const Text('Modell verfügbar'),
                                trailing: Text(
                                  snapshot.hasError
                                      ? 'Nicht prüfbar'
                                      : snapshot.data == true
                                      ? 'OK'
                                      : 'Fehlt',
                                ),
                              ),
                            ),
                            _row(
                              'Modell verwalten',
                              Icons.settings,
                              _manageModel,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _row(
                      'Design',
                      Icons.light_mode_outlined,
                      () => _popup(
                        'Design',
                        DropdownButton<String>(
                          value: _selectedTheme ?? settings['theme'] ?? 'light',
                          items: const [
                            DropdownMenuItem(
                              value: 'light',
                              child: Text('Hell'),
                            ),
                            DropdownMenuItem(
                              value: 'dark',
                              child: Text('Dunkel'),
                            ),
                          ],
                          onChanged: (value) async {
                            if (value == null) return;
                            try {
                              await widget.store.setSetting('theme', value);
                              if (!mounted) return;
                              setState(() => _selectedTheme = value);
                              widget.onThemeChanged(
                                value == 'dark'
                                    ? ThemeMode.dark
                                    : ThemeMode.light,
                              );
                            } catch (error) {
                              if (mounted) _error(error);
                            }
                          },
                        ),
                      ),
                      subtitle: (_selectedTheme ?? settings['theme']) == 'dark'
                          ? 'Dunkel'
                          : 'Hell',
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
  Future<bool> _modelAvailable() async {
    final root = await getApplicationSupportDirectory();
    final installed = File(p.join(root.path, 'whisper', 'ggml-base.bin'));
    final bundled = File(
      p.join(
        p.dirname(Platform.resolvedExecutable),
        'data',
        'whisper',
        'ggml-base.bin',
      ),
    );
    return await installed.exists() || await bundled.exists();
  }

  String _timeLabel(String start) {
    final parts = start.split(':').map(int.parse).toList();
    final end = DateTime(
      2000,
      1,
      1,
      parts[0],
      parts[1],
    ).add(const Duration(minutes: 45));
    return '$start – ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }

  Widget _panel(String title, List<Widget> children) => Material(
    color: DaymarkColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: DaymarkColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 26),
          ...children,
        ],
      ),
    ),
  );
}
