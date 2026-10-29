import 'package:daymark/ui/daymark_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats valid weekdays', () {
    expect(scheduleWeekdayLabel(1), 'Mo');
    expect(scheduleWeekdayLabel(5), 'Fr');
    expect(scheduleWeekdayLabel(7), 'So');
  });

  test('handles missing and invalid weekdays', () {
    expect(scheduleWeekdayLabel(null), 'Tag fehlt');
    expect(scheduleWeekdayLabel(0), 'Tag fehlt');
    expect(scheduleWeekdayLabel(8), 'Tag fehlt');
  });
}
