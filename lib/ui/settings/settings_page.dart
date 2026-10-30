import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/daymark_store.dart';
import '../../domain/date_formatting.dart';
import '../../domain/iso_day.dart';
import '../theme/daymark_theme.dart';
import 'free_days_dialog.dart';
import 'lesson_times_dialog.dart';

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
  bool _savingTheme = false;
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

  void _reload() {
    setState(() {
      _settings = _load();
    });
  }

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
  bool _validSchoolYear(String value) {
    if (!RegExp(r'^\d{4}/\d{2}$').hasMatch(value)) return false;
    final first = int.parse(value.substring(0, 4));
    return value == '$first/${((first + 1) % 100).toString().padLeft(2, '0')}';
  }

  Future<void> _editLessonTimes(Map<String, String> settings) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LessonTimesDialog(
        initialStartTimes: [
          for (var i = 1; i <= 8; i++)
            settings['period_$i'] ?? _defaultTimes[i - 1],
        ],
        onSave: widget.store.setPeriodTimes,
      ),
    );
    if (saved == true && mounted) {
      _reload();
      _message('Unterrichtszeiten gespeichert.');
    }
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
    String? badge,
  }) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: action,
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: DaymarkColors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: DaymarkColors.ink),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: DaymarkColors.ink, fontSize: 19),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: DaymarkColors.muted,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: DaymarkColors.success.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: DaymarkColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: DaymarkColors.ink),
          ],
        ),
      ),
    ),
  );

  Widget _toggleRow(
    String title,
    IconData icon, {
    required bool value,
    required ValueChanged<bool> onChanged,
    required String subtitle,
  }) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _savingTheme ? null : () => onChanged(!value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: DaymarkColors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: DaymarkColors.ink),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: DaymarkColors.ink, fontSize: 19),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: DaymarkColors.muted, fontSize: 16),
                  ),
                ],
              ),
            ),
            Switch(
              key: const ValueKey('theme-toggle'),
              value: value,
              onChanged: _savingTheme ? null : onChanged,
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _setDarkTheme(bool dark, {required bool previousDark}) async {
    final previous = previousDark ? 'dark' : 'light';
    final value = dark ? 'dark' : 'light';
    setState(() {
      _selectedTheme = value;
      _savingTheme = true;
    });
    widget.onThemeChanged(dark ? ThemeMode.dark : ThemeMode.light);
    try {
      await widget.store.setSetting('theme', value);
      if (mounted) setState(() => _savingTheme = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _selectedTheme = previous;
        _savingTheme = false;
      });
      widget.onThemeChanged(
        previous == 'dark' ? ThemeMode.dark : ThemeMode.light,
      );
      _error(error);
    }
  }

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
      final start = settings['school_start'] ?? '$year-08-01';
      final parsedStart = isIsoDay(start) ? DateTime.parse(start) : null;
      final startLabel = parsedStart == null
          ? start
          : formatGermanLongDate(parsedStart);
      final darkTheme = (_selectedTheme ?? settings['theme']) == 'dark';
      final calendar = _panel(
        'Schuljahr & Kalender',
        'Verwalte dein Schuljahr und wichtige Termine.',
        [
          _row('Aktuelles Schuljahr', Icons.school_outlined, () async {
            final value = await _prompt(
              'Schuljahr (JJJJ/JJ)',
              initial: schoolYear,
            );
            if (value == null) return;
            if (!_validSchoolYear(value)) {
              if (mounted) _error('Ungültiges Schuljahr.');
              return;
            }
            await _run(() => widget.store.setSetting('school_year', value));
          }, subtitle: schoolYear),
          _row('Standard-Startdatum', Icons.event_busy_outlined, () async {
            final value = await _prompt(
              'Standard-Startdatum (TT.MM.JJJJ)',
              initial: formatGermanIsoDate(start),
            );
            if (value == null) return;
            final isoDate = germanDateToIso(value);
            if (isoDate == null) {
              if (mounted) _error('Ungültiges Datum.');
              return;
            }
            await _run(() => widget.store.setSetting('school_start', isoDate));
          }, subtitle: startLabel),
          _row(
            'Schulfreie Tage',
            Icons.event_available_outlined,
            () => showDialog<void>(
              context: context,
              builder: (context) => FreeDaysDialog(store: widget.store),
            ),
          ),
        ],
      );
      final app = _panel('App', 'Verwalte deine App-Einstellungen.', [
        _row('Passwort ändern', Icons.key_outlined, _changePassword),
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
                _row('Modell verwalten', Icons.settings, _manageModel),
              ],
            ),
          ),
        ),
        _toggleRow(
          'Design',
          Icons.light_mode_outlined,
          value: darkTheme,
          onChanged: (dark) => _setDarkTheme(dark, previousDark: darkTheme),
          subtitle: darkTheme ? 'Dunkel' : 'Hell',
        ),
      ]);
      final teaching = _panel(
        'Unterricht',
        'Lege die Startzeiten für deinen Unterricht fest.',
        [
          _row(
            'Unterrichtszeiten',
            Icons.access_time_outlined,
            () => _editLessonTimes(settings),
            subtitle: '8 Stunden · jeweils 45 Minuten',
          ),
        ],
      );
      final data = _panel(
        'Daten & Sicherheit',
        'Deine Daten, sicher und in deiner Hand.',
        [
          _row(
            'Lokale Datenbank',
            Icons.lock_outline,
            () => _popup(
              'Lokale Datenbank',
              const Text(
                'Deine Daten werden lokal und verschlüsselt gespeichert.',
              ),
            ),
            badge: 'Aktiv',
          ),
          _row(
            'Backup exportieren',
            Icons.upload_outlined,
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
            Icons.download_outlined,
            () => _popup(
              'Backup importieren',
              FilledButton(
                onPressed: _import,
                child: const Text('Backup auswählen'),
              ),
            ),
          ),
        ],
      );
      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1050;
          return ListView(
            padding: const EdgeInsets.fromLTRB(36, 26, 36, 30),
            children: [
              Text(
                'ARBEITSBEREICH',
                style: TextStyle(
                  color: DaymarkColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Einstellungen',
                style: TextStyle(
                  color: DaymarkColors.ink,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Passe Daymark an deinen Schulalltag an.',
                style: TextStyle(color: DaymarkColors.muted, fontSize: 20),
              ),
              const SizedBox(height: 22),
              if (columns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [calendar, const SizedBox(height: 18), app],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        children: [teaching, const SizedBox(height: 18), data],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    calendar,
                    const SizedBox(height: 18),
                    teaching,
                    const SizedBox(height: 18),
                    data,
                    const SizedBox(height: 18),
                    app,
                  ],
                ),
            ],
          );
        },
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

  Widget _panel(String title, String description, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        decoration: BoxDecoration(
          color: DaymarkColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DaymarkColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: DaymarkColors.ink,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: TextStyle(color: DaymarkColors.muted, fontSize: 17),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: DaymarkColors.border),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Column(children: children),
              ),
            ),
          ],
        ),
      );
}
