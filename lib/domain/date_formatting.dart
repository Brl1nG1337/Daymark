import 'package:intl/intl.dart';

import 'iso_day.dart';

final DateFormat _germanDateFormat = DateFormat('dd.MM.yyyy', 'en_US');
final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd', 'en_US');

const _germanWeekdays = [
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
];

const _germanMonths = [
  'Januar',
  'Februar',
  'März',
  'April',
  'Mai',
  'Juni',
  'Juli',
  'August',
  'September',
  'Oktober',
  'November',
  'Dezember',
];

String formatGermanDate(DateTime date) => _germanDateFormat.format(date);

String formatGermanLongDate(DateTime date) =>
    '${formatGermanDayLabel(date)} ${date.year}';

String formatGermanDayLabel(DateTime date) =>
    '${_germanWeekdays[date.weekday - 1]}, ${date.day}. ${_germanMonths[date.month - 1]}';

String formatGermanIsoDate(String value) {
  if (!isIsoDay(value)) return value;
  return formatGermanDate(DateTime.parse(value));
}

DateTime? parseGermanDate(String value) {
  final normalized = value.trim();
  if (!RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(normalized)) return null;
  try {
    return _germanDateFormat.parseStrict(normalized);
  } on FormatException {
    return null;
  }
}

String? germanDateToIso(String value) {
  final date = parseGermanDate(value);
  return date == null ? null : _isoDateFormat.format(date);
}
