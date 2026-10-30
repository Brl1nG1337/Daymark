import 'package:daymark/ui/theme/daymark_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Daymark theme', () {
    test('uses the reduced semantic light palette', () {
      const colors = DaymarkSemanticColors.light();

      expect(colors.background, const Color(0xfff8f9f7));
      expect(colors.backgroundSecondary, const Color(0xfff1f4f1));
      expect(colors.surface, const Color(0xffffffff));
      expect(colors.primary, const Color(0xff327378));
      expect(colors.secondary, const Color(0xffdce8df));
      expect(colors.accent, const Color(0xfff3e9d6));
      expect(colors.textPrimary, const Color(0xff263035));
      expect(colors.textSecondary, const Color(0xff667475));
      expect(colors.border, const Color(0xffe3e8e5));
    });

    test('uses the requested semantic dark palette', () {
      const colors = DaymarkSemanticColors.dark();

      expect(colors.background, const Color(0xff171c1d));
      expect(colors.backgroundSecondary, const Color(0xff293132));
      expect(colors.surface, const Color(0xff202728));
      expect(colors.surfaceElevated, const Color(0xff293132));
      expect(colors.primary, const Color(0xff8ebdb9));
      expect(colors.secondary, const Color(0xff34443c));
      expect(colors.accent, const Color(0xff4a4133));
      expect(colors.textPrimary, const Color(0xfff1f3f0));
      expect(colors.textSecondary, const Color(0xffa7b3b0));
      expect(colors.border, const Color(0xff343e3d));
    });

    test('builds light and dark ThemeData independently', () {
      DaymarkColors.dark = true;
      addTearDown(() => DaymarkColors.dark = false);

      final light = daymarkTheme();
      final dark = daymarkTheme(dark: true);

      expect(light.brightness, Brightness.light);
      expect(
        light.extension<DaymarkSemanticColors>(),
        const DaymarkSemanticColors.light(),
      );
      expect(dark.brightness, Brightness.dark);
      expect(
        dark.extension<DaymarkSemanticColors>(),
        const DaymarkSemanticColors.dark(),
      );
    });

    test('normal text and colored controls meet WCAG AA contrast', () {
      for (final colors in const [
        DaymarkSemanticColors.light(),
        DaymarkSemanticColors.dark(),
      ]) {
        expect(
          _contrast(colors.textPrimary, colors.background),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(colors.textSecondary, colors.background),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(colors.onPrimary, colors.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(colors.onSecondary, colors.secondary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(colors.onAccent, colors.accent),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(colors.onSuccess, colors.success),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(colors.onWarning, colors.warning),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(colors.onError, colors.error),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(colors.focus, colors.background),
          greaterThanOrEqualTo(3),
        );
      }
    });
  });
}

double _contrast(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first
      : second;
  final darker = identical(lighter, first) ? second : first;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
