import 'package:flutter_test/flutter_test.dart';
import 'package:daymark/domain/school_calendar.dart';

void main() {
  test('NRW autumn holiday suppresses regular school day', () {
    expect(SchoolCalendar.reason(DateTime(2026, 10, 26), {}), 'Herbstferien');
  });
  test('school-specific day suppresses regular school day', () {
    expect(
      SchoolCalendar.reason(DateTime(2026, 11, 16), {'2026-11-16'}),
      'Schulfreier Tag',
    );
  });
  test('movable holiday is calculated locally', () {
    expect(SchoolCalendar.reason(DateTime(2027, 3, 26), {}), 'Karfreitag');
  });
  test('regular school day remains available', () {
    expect(SchoolCalendar.reason(DateTime(2026, 11, 17), {}), isNull);
  });
}
