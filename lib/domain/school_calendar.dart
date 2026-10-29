String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class SchoolCalendar {
  static const vacations = <(String, String, String)>[
    ('2026-07-20', '2026-09-01', 'Sommerferien'),
    ('2026-10-17', '2026-10-31', 'Herbstferien'),
    ('2026-12-23', '2027-01-06', 'Weihnachtsferien'),
    ('2027-03-22', '2027-04-03', 'Osterferien'),
    ('2027-05-18', '2027-05-18', 'Pfingstferien'),
    ('2027-07-19', '2027-08-31', 'Sommerferien'),
    ('2027-10-23', '2027-11-06', 'Herbstferien'),
    ('2027-12-24', '2028-01-08', 'Weihnachtsferien'),
    ('2028-04-10', '2028-04-22', 'Osterferien'),
    ('2028-07-10', '2028-08-22', 'Sommerferien'),
    ('2028-10-23', '2028-11-04', 'Herbstferien'),
    ('2028-12-21', '2029-01-05', 'Weihnachtsferien'),
    ('2029-03-26', '2029-04-07', 'Osterferien'),
    ('2029-05-22', '2029-05-22', 'Pfingstferien'),
    ('2029-07-02', '2029-08-14', 'Sommerferien'),
    ('2029-10-15', '2029-10-27', 'Herbstferien'),
    ('2029-12-20', '2030-01-04', 'Weihnachtsferien'),
    ('2030-04-15', '2030-04-27', 'Osterferien'),
  ];
  static DateTime easter(int year) {
    final a = year % 19,
        b = year ~/ 100,
        c = year % 100,
        d = b ~/ 4,
        e = b % 4,
        f = (b + 8) ~/ 25,
        g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30,
        i = c ~/ 4,
        k = c % 4,
        l = (32 + 2 * e + 2 * i - h - k) % 7,
        m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31,
        day = (h + l - 7 * m + 114) % 31 + 1;
    return DateTime(year, month, day);
  }

  static String? reason(DateTime date, Set<String> custom) {
    final key = _dayKey(date);
    if (custom.contains(key)) return 'Schulfreier Tag';
    final e = easter(date.year);
    final fixed = <String, String>{
      '${date.year}-01-01': 'Neujahr',
      '${date.year}-05-01': 'Tag der Arbeit',
      '${date.year}-10-03': 'Tag der Deutschen Einheit',
      '${date.year}-11-01': 'Allerheiligen',
      '${date.year}-12-25': '1. Weihnachtstag',
      '${date.year}-12-26': '2. Weihnachtstag',
    };
    if (fixed.containsKey(key)) return fixed[key];
    final movable = <int, String>{
      -2: 'Karfreitag',
      1: 'Ostermontag',
      39: 'Christi Himmelfahrt',
      50: 'Pfingstmontag',
      60: 'Fronleichnam',
    };
    for (final entry in movable.entries) {
      if (_dayKey(e.add(Duration(days: entry.key))) == key) return entry.value;
    }
    for (final (from, to, name) in vacations) {
      if (key.compareTo(from) >= 0 && key.compareTo(to) <= 0) return name;
    }
    return date.weekday > 5 ? 'Wochenende' : null;
  }
}
