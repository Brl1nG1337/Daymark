import 'package:flutter/material.dart';

import '../../domain/date_formatting.dart';
import '../theme/daymark_theme.dart';

Future<DateTime?> showDaymarkDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) => showDialog<DateTime>(
  context: context,
  builder: (context) => DesktopDatePickerDialog(
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  ),
);

/// A roomy calendar dialog for mouse and keyboard use on desktop windows.
class DesktopDatePickerDialog extends StatefulWidget {
  const DesktopDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<DesktopDatePickerDialog> createState() =>
      _DesktopDatePickerDialogState();
}

class _DesktopDatePickerDialogState extends State<DesktopDatePickerDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  void _selectToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    if (today.isBefore(widget.firstDate) || today.isAfter(widget.lastDate)) {
      return;
    }
    setState(() => _selectedDate = today);
  }

  @override
  Widget build(BuildContext context) {
    final windowSize = MediaQuery.sizeOf(context);
    final availableWidth = (windowSize.width - 48).clamp(320.0, 820.0);
    final availableHeight = (windowSize.height - 48).clamp(480.0, 600.0);
    final useWideLayout = availableWidth >= 680;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: availableWidth,
        height: availableHeight,
        child: useWideLayout
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 240,
                    child: _SelectedDatePanel(date: _selectedDate),
                  ),
                  Expanded(child: _calendar()),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SelectedDatePanel(date: _selectedDate, compact: true),
                  Expanded(child: _calendar()),
                ],
              ),
      ),
    );
  }

  Widget _calendar() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 2),
        child: Text(
          'Datum auswählen',
          style: TextStyle(
            color: DaymarkColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Expanded(
        child: Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: const DatePickerThemeData(
              dayStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              weekdayStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              yearStyle: TextStyle(fontSize: 16),
            ),
          ),
          child: CalendarDatePicker(
            key: ValueKey(_selectedDate),
            initialDate: _selectedDate,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            currentDate: DateTime.now(),
            onDateChanged: (date) => setState(() => _selectedDate = date),
          ),
        ),
      ),
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _selectToday,
              icon: const Icon(Icons.today_outlined),
              label: const Text('Heute'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context, _selectedDate),
              child: const Text('Übernehmen'),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SelectedDatePanel extends StatelessWidget {
  const _SelectedDatePanel({required this.date, this.compact = false});

  final DateTime date;
  final bool compact;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: DaymarkColors.sidebar,
    child: Padding(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 24, vertical: 18)
          : const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: compact
          ? Row(
              children: [
                _calendarIcon(size: 30),
                const SizedBox(width: 16),
                Expanded(child: _dateText(compact: true)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _calendarIcon(size: 36),
                const SizedBox(height: 28),
                _dateText(compact: false),
              ],
            ),
    ),
  );

  Widget _calendarIcon({required double size}) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: DaymarkColors.onSidebar.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(
      Icons.calendar_month_outlined,
      color: DaymarkColors.onSidebar,
      size: size,
    ),
  );

  Widget _dateText({required bool compact}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        formatGermanLongDate(date),
        style: TextStyle(
          color: DaymarkColors.onSidebar,
          fontSize: compact ? 20 : 28,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        formatGermanDate(date),
        style: TextStyle(
          color: DaymarkColors.sidebarIcon,
          fontSize: compact ? 16 : 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
