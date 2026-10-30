import 'package:daymark/domain/date_formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats dates consistently in German', () {
    final date = DateTime(2026, 5, 12);

    expect(formatGermanDate(date), '12.05.2026');
    expect(formatGermanDayLabel(date), 'Dienstag, 12. Mai');
    expect(formatGermanLongDate(date), 'Dienstag, 12. Mai 2026');
    expect(formatGermanIsoDate('2026-05-12'), '12.05.2026');
  });

  test('converts strict German input to the canonical stored date', () {
    expect(germanDateToIso('29.02.2028'), '2028-02-29');
    expect(germanDateToIso('29.02.2027'), isNull);
    expect(germanDateToIso('2028-02-29'), isNull);
    expect(germanDateToIso('1.2.2028'), isNull);
  });
}
