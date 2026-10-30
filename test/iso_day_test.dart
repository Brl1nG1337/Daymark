import 'package:daymark/domain/iso_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only canonical, real calendar days are accepted', () {
    expect(isIsoDay('2028-02-29'), isTrue);
    expect(isIsoDay('2026-02-29'), isFalse);
    expect(isIsoDay('2026-02-30'), isFalse);
    expect(isIsoDay('2026-2-03'), isFalse);
    expect(isIsoDay('2026-12-31'), isTrue);
  });
}
