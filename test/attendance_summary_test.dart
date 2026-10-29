import 'package:daymark/domain/attendance_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts hours and distinct days separately', () {
    final s = AttendanceSummary.fromRows([
      {'day': '2026-11-03', 'status': 'absent'},
      {'day': '2026-11-03', 'status': 'excused'},
      {'day': '2026-11-04', 'status': 'absent'},
      {'day': '2026-11-05', 'status': 'late'},
    ]);
    expect(s.absentHours, 2);
    expect(s.excusedHours, 1);
    expect(s.missingDays, 2);
  });
  test('school year rolls over in August', () {
    expect(schoolYearFor('2027-07-31'), '2026/27');
    expect(schoolYearFor('2027-08-01'), '2027/28');
  });
}
