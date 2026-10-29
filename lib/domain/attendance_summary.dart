class AttendanceSummary {
  const AttendanceSummary(
    this.absentHours,
    this.excusedHours,
    this.missingDays,
  );
  final int absentHours;
  final int excusedHours;
  final int missingDays;

  static AttendanceSummary fromRows(List<Map<String, Object?>> rows) {
    final absent = rows.where((r) => r['status'] == 'absent').toList();
    final excused = rows.where((r) => r['status'] == 'excused').toList();
    final days = [...absent, ...excused].map((r) => r['day']).toSet().length;
    return AttendanceSummary(absent.length, excused.length, days);
  }
}

String schoolYearFor(String isoDate) {
  final year = int.parse(isoDate.substring(0, 4));
  final month = int.parse(isoDate.substring(5, 7));
  final first = month >= 8 ? year : year - 1;
  return '$first/${(first + 1).toString().substring(2)}';
}
