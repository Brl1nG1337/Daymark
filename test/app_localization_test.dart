import 'package:daymark/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app configures German localization globally', (tester) async {
    await tester.pumpWidget(const DaymarkLogin());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('de', 'DE'));
    expect(app.supportedLocales, contains(const Locale('de', 'DE')));
    expect(app.localizationsDelegates, hasLength(3));
  });
}
