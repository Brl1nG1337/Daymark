import 'package:flutter/material.dart';

import '../../data/daymark_store.dart';
import '../../domain/date_formatting.dart';
import '../theme/daymark_theme.dart';

const _weekdays = <String>[
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
];

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key, required this.store});
  final DaymarkStore store;
  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  late int _year = DateTime.now().month >= 8
      ? DateTime.now().year
      : DateTime.now().year - 1;
  int _startMonth = 8;
  int _startDay = 1;
  int? _selectedId;
  int? _hoveredCell;
  bool _showList = false;
  late Future<List<_Slot>> _slots = _loadSlots();
  @override
  void initState() {
    super.initState();
    _loadSchoolSettings();
  }

  Future<void> _loadSchoolSettings() async {
    final year = await widget.store.setting('school_year');
    final start = await widget.store.setting('school_start');
    if (!mounted) return;
    setState(() {
      if (year != null) _year = int.tryParse(year.substring(0, 4)) ?? _year;
      final parsed = start == null ? null : DateTime.tryParse(start);
      if (parsed != null) {
        _startMonth = parsed.month;
        _startDay = parsed.day;
      }
    });
  }

  Future<List<_Slot>> _loadSlots() async => [
    for (final row in await widget.store.slots()) _Slot.fromRow(row),
  ];
  void _reload() => setState(() {
    _slots = _loadSlots();
  });
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

  Future<void> _edit(_Slot? slot, {int? weekday, int? period}) async {
    final classes = await widget.store.classes();
    if (!mounted) return;
    if (classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zuerst eine Klasse anlegen.')),
      );
      return;
    }
    var classId = slot?.classId ?? classes.first['id'] as int;
    weekday = slot?.weekday ?? weekday ?? 1;
    period = slot?.period ?? period ?? 1;
    var subject = slot?.subject ?? '';

    final configuredTime = await widget.store.setting('period_$period');
    if (!mounted) return;
    var time = slot?.time ?? configuredTime ?? '';
    var from = formatGermanIsoDate(slot?.from ?? dayKey(DateTime(_year, 8, 1)));
    var to = slot?.to == null ? '' : formatGermanIsoDate(slot!.to!);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(slot == null ? 'Eintrag anlegen' : 'Eintrag bearbeiten'),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: classId,
                    decoration: const InputDecoration(labelText: 'Klasse'),
                    items: [
                      for (final item in classes)
                        DropdownMenuItem(
                          value: item['id'] as int,
                          child: Text(item['name'] as String),
                        ),
                    ],
                    onChanged: (value) => update(() => classId = value!),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: subject,
                    onChanged: (value) => subject = value,
                    decoration: const InputDecoration(labelText: 'Fach'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: weekday,
                    decoration: const InputDecoration(labelText: 'Wochentag'),
                    items: [
                      for (var index = 0; index < 7; index++)
                        DropdownMenuItem(
                          value: index + 1,
                          child: Text(
                            [
                              'Montag',
                              'Dienstag',
                              'Mittwoch',
                              'Donnerstag',
                              'Freitag',
                              'Samstag',
                              'Sonntag',
                              'Samstag',
                              'Sonntag',
                            ][index],
                          ),
                        ),
                    ],
                    onChanged: (value) => update(() => weekday = value!),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: period,
                    decoration: const InputDecoration(labelText: 'Stunde'),
                    items: [
                      for (var index = 1; index <= 12; index++)
                        DropdownMenuItem(
                          value: index,
                          child: Text('$index. Stunde'),
                        ),
                    ],
                    onChanged: (value) => update(() => period = value!),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: time,
                    onChanged: (value) => time = value,
                    decoration: const InputDecoration(
                      labelText: 'Startzeit (HH:MM)',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: from,
                    onChanged: (value) => from = value,
                    decoration: const InputDecoration(
                      labelText: 'Gültig ab (TT.MM.JJJJ)',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: to,
                    onChanged: (value) => to = value,
                    decoration: const InputDecoration(
                      labelText: 'Gültig bis (optional)',
                    ),
                  ),
                ],
              ),
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
      ),
    );
    if (accepted == true) {
      final fromIso = germanDateToIso(from);
      final toIso = to.isEmpty ? null : germanDateToIso(to);
      final validDate = fromIso != null && (to.isEmpty || toIso != null);
      final validRange =
          fromIso != null && (toIso == null || fromIso.compareTo(toIso) <= 0);
      final validTime =
          time.isEmpty || RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(time);
      if (subject.trim().isEmpty || !validDate || !validRange || !validTime) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fach, Datum oder Startzeit ungültig.'),
            ),
          );
        }
      } else if (slot == null) {
        await _run(
          () => widget.store.addSlot(
            classId,
            subject,
            weekday!,
            period!,
            time.isEmpty ? null : time,
            fromIso,
          ),
        );
      } else {
        await _run(
          () => widget.store.updateSlot(
            slot.id,
            classId,
            subject,
            weekday!,
            period!,
            time.isEmpty ? null : time,
            fromIso,
            toIso,
          ),
        );
      }
    }
  }

  Future<void> _endSlot(_Slot slot) async {
    var end = formatGermanDate(DateTime.now());
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag beenden'),
        content: TextFormField(
          initialValue: end,
          onChanged: (value) => end = value,
          decoration: const InputDecoration(
            labelText: 'Letzter Gültigkeitstag (TT.MM.JJJJ)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Beenden'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    final endIso = germanDateToIso(end);
    if (endIso == null || endIso.compareTo(slot.from) < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Das Ende muss nach dem Beginn liegen.'),
          ),
        );
      }
      return;
    }
    await _run(() => widget.store.endSlot(slot.id, endIso));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final addButton = FilledButton.icon(
              onPressed: () => _edit(null),
              icon: const Icon(Icons.add),
              label: const Text('Stunde hinzufügen'),
            );
            if (constraints.maxWidth < 720) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stundenplan',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Regelstundenplan · Schuljahr $_year/${(_year + 1).toString().substring(2)}',
                    style: TextStyle(color: DaymarkColors.muted),
                  ),
                  const SizedBox(height: 14),
                  addButton,
                ],
              );
            }
            return Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stundenplan',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Regelstundenplan · Schuljahr $_year/${(_year + 1).toString().substring(2)}',
                      style: TextStyle(color: DaymarkColors.muted),
                    ),
                  ],
                ),
                const Spacer(),
                addButton,
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Expanded(child: _gridView()),
      ],
    ),
  );
  Widget _gridView() => FutureBuilder<List<_Slot>>(
    future: _slots,
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
      final now = DateTime.now();
      final currentYear = now.month >= 8 ? now.year : now.year - 1;
      final yearStart = _year == currentYear
          ? dayKey(now)
          : dayKey(DateTime(_year, _startMonth, _startDay));
      final visible = snapshot.data!
          .where(
            (slot) =>
                slot.from.compareTo(yearStart) <= 0 &&
                (slot.to == null || slot.to!.compareTo(yearStart) >= 0),
          )
          .toList();
      final dayCount = visible.any((slot) => slot.weekday > 5) ? 7 : 5;
      final maxPeriod = visible.fold<int>(
        8,
        (max, slot) => slot.period > max ? slot.period : max,
      );
      final selected = snapshot.data!
          .where((slot) => slot.id == _selectedId)
          .firstOrNull;
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800 || _showList) {
            return ListView(
              children: [
                _yearPicker(),
                for (var weekday = 1; weekday <= dayCount; weekday++)
                  _panel(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            _weekdays[weekday - 1],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        for (final slot in visible.where(
                          (slot) => slot.weekday == weekday,
                        ))
                          ListTile(
                            leading: _SubjectMarker(
                              accent: _accentForSubject(slot.subject),
                            ),
                            title: Text(
                              slot.subject,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${slot.period}. Stunde · ${slot.time ?? '–'} · ${slot.className}',
                            ),
                            onTap: () => setState(() => _selectedId = slot.id),
                          ),
                      ],
                    ),
                  ),
                if (selected != null)
                  SizedBox(height: 220, child: _entry(selected)),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _panel(
                  child: Column(
                    children: [
                      _yearPicker(),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, grid) => SingleChildScrollView(
                            child: Column(
                              children: [
                                Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: DaymarkColors.primary.withValues(
                                      alpha: DaymarkColors.dark ? .14 : .07,
                                    ),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: DaymarkColors.border,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 110),
                                      for (final day in _weekdays.take(
                                        dayCount,
                                      ))
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              day,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                for (
                                  var period = 1;
                                  period <= maxPeriod;
                                  period++
                                )
                                  Container(
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: period.isEven
                                          ? DaymarkColors.background.withValues(
                                              alpha: DaymarkColors.dark
                                                  ? .22
                                                  : .45,
                                            )
                                          : Colors.transparent,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: DaymarkColors.border
                                              .withValues(alpha: .7),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 110,
                                          decoration: BoxDecoration(
                                            color: DaymarkColors.primary
                                                .withValues(
                                                  alpha: DaymarkColors.dark
                                                      ? .08
                                                      : .035,
                                                ),
                                            border: Border(
                                              right: BorderSide(
                                                color: DaymarkColors.border,
                                              ),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$period. Stunde',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  _periodTime(visible, period),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: DaymarkColors.muted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        for (
                                          var weekday = 1;
                                          weekday <= dayCount;
                                          weekday++
                                        )
                                          Expanded(
                                            child: _cell(
                                              visible,
                                              weekday,
                                              period,
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
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(width: 290, child: _entry(selected)),
            ],
          );
        },
      );
    },
  );
  Future<void> _showAllEntries() async {
    final entries = await _slots;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle Stundenplan-Einträge'),
        content: SizedBox(
          width: 600,
          height: 500,
          child: entries.isEmpty
              ? const Center(child: Text('Noch keine Einträge.'))
              : ListView(
                  children: [
                    for (final slot in entries)
                      ListTile(
                        leading: _SubjectMarker(
                          accent: _accentForSubject(slot.subject),
                        ),
                        title: Text(
                          '${slot.className} · ${slot.subject} · ${slot.period}. Stunde',
                        ),
                        subtitle: Text(
                          '${formatGermanIsoDate(slot.from)}${slot.to == null ? '' : ' – ${formatGermanIsoDate(slot.to!)}'}',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _selectedId = slot.id);
                        },
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
  }

  String _periodTime(List<_Slot> slots, int period) {
    final start = slots
        .where((slot) => slot.period == period && slot.time != null)
        .firstOrNull
        ?.time;
    if (start == null) return '–';
    final parts = start.split(':');
    if (parts.length != 2) return start;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return start;
    }
    final minutes = hour * 60 + minute + 45;
    return '$start – ${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
  }

  Widget _yearPicker() => SizedBox(
    height: 64,
    child: Row(
      children: [
        const SizedBox(width: 14),
        IconButton.outlined(
          onPressed: () => setState(() => _year--),
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Vorheriges Schuljahr',
        ),
        Expanded(
          child: Center(
            child: Text(
              'Regelstundenplan · Schuljahr $_year/${(_year + 1).toString().substring(2)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _year++),
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Nächstes Schuljahr',
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: _showAllEntries,
          icon: const Icon(Icons.list_alt_outlined),
          tooltip: 'Alle Einträge',
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: () => setState(() => _showList = !_showList),
          icon: Icon(
            _showList ? Icons.grid_on_outlined : Icons.calendar_today_outlined,
          ),
          tooltip: _showList
              ? 'Wochenraster anzeigen'
              : 'Listenansicht anzeigen',
        ),
        const SizedBox(width: 14),
      ],
    ),
  );
  Widget _cell(List<_Slot> slots, int weekday, int period) {
    final cellId = weekday * 100 + period;
    final entries = slots
        .where((slot) => slot.weekday == weekday && slot.period == period)
        .toList();
    final selected = entries.any((slot) => slot.id == _selectedId);
    final accent = entries.isEmpty
        ? null
        : _accentForSubject(entries.first.subject);
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Material(
        key: ValueKey('planning-slot-$weekday-$period'),
        color: entries.isEmpty
            ? DaymarkColors.background
            : selected
            ? DaymarkColors.activeSurface
            : DaymarkColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? DaymarkColors.active : DaymarkColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onHover: (hovering) =>
              setState(() => _hoveredCell = hovering ? cellId : null),
          onTap: entries.isEmpty
              ? () => _edit(null, weekday: weekday, period: period)
              : () => setState(() => _selectedId = entries.first.id),
          child: Padding(
            padding: EdgeInsets.fromLTRB(entries.isEmpty ? 12 : 0, 6, 8, 6),
            child: entries.isEmpty
                ? Center(
                    child: _hoveredCell == cellId
                        ? Text(
                            'Stunde hinzufügen',
                            style: TextStyle(
                              fontSize: 12,
                              color: DaymarkColors.primary,
                            ),
                          )
                        : Icon(
                            Icons.add,
                            size: 16,
                            color: DaymarkColors.border,
                          ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 4,
                        height: 52,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? DaymarkColors.active
                              : accent!.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entries.first.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _ClassBadge(
                              label:
                                  'Klasse ${entries.map((slot) => slot.className).join(', ')}',
                              accent: accent!,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _entry(_Slot? slot) => _panel(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: slot == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unterrichtsstunde',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 90),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(
                            color: DaymarkColors.backgroundSecondary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calendar_month_outlined,
                            size: 46,
                            color: DaymarkColors.muted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Keine Stunde ausgewählt',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Wähle eine Stunde im Plan aus, um sie anzusehen oder zu bearbeiten.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: DaymarkColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Eintrag',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _accentForSubject(slot.subject).surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: _accentForSubject(slot.subject).color,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.subject,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ClassBadge(
                          label: slot.className,
                          accent: _accentForSubject(slot.subject),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${_weekdays[slot.weekday - 1]} · ${slot.period}. Stunde',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    slot.time ?? 'Keine Startzeit',
                    style: TextStyle(color: DaymarkColors.muted),
                  ),
                  const Divider(height: 32),
                  Text('Gültig ab ${formatGermanIsoDate(slot.from)}'),
                  if (slot.to != null)
                    Text('Bis ${formatGermanIsoDate(slot.to!)}'),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _edit(slot),
                    icon: Icon(Icons.edit_outlined),
                    label: const Text('Bearbeiten'),
                  ),
                  if (slot.to == null)
                    TextButton.icon(
                      onPressed: () => _endSlot(slot),
                      icon: Icon(Icons.delete_outline),
                      label: const Text('Eintrag beenden'),
                    ),
                ],
              ),
      ),
    ),
  );
  Widget _panel({required Widget child}) => Material(
    color: DaymarkColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: DaymarkColors.border),
    ),
    child: child,
  );
}

class _ClassBadge extends StatelessWidget {
  const _ClassBadge({required this.label, required this.accent});

  final String label;
  final _SubjectAccent accent;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 190),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: DaymarkColors.activeSurface,
      border: Border.all(
        color: DaymarkColors.dark
            ? DaymarkColors.primary.withValues(alpha: .55)
            : DaymarkColors.primary.withValues(alpha: .28),
      ),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: accent.foreground,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _SubjectMarker extends StatelessWidget {
  const _SubjectMarker({required this.accent});

  final _SubjectAccent accent;

  @override
  Widget build(BuildContext context) => Container(
    width: 5,
    height: 38,
    decoration: BoxDecoration(
      color: accent.color,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

class _SubjectAccent {
  const _SubjectAccent({
    required this.color,
    required this.surface,
    required this.foreground,
  });

  final Color color;
  final Color surface;
  final Color foreground;
}

_SubjectAccent _accentForSubject(String subject) {
  final colors = DaymarkColors.subjectAccents;
  final normalized = subject.trim().toLowerCase();
  final colorIndex =
      normalized.runes.fold<int>(0, (sum, rune) => sum + rune) % colors.length;
  final color = colors[colorIndex];
  return _SubjectAccent(
    color: color,
    surface: DaymarkColors.surface,
    foreground: DaymarkColors.primary,
  );
}

class _Slot {
  const _Slot(
    this.id,
    this.classId,
    this.className,
    this.subject,
    this.weekday,
    this.period,
    this.time,
    this.from,
    this.to,
  );
  final int id, classId, weekday, period;
  final String className, subject, from;
  final String? time, to;
  factory _Slot.fromRow(Map<String, Object?> row) => _Slot(
    row['id'] as int,
    row['class_id'] as int,
    row['class_name'] as String,
    row['subject'] as String,
    row['weekday'] as int,
    row['period'] as int,
    row['start_time'] as String?,
    row['valid_from'] as String,
    row['valid_to'] as String?,
  );
}
