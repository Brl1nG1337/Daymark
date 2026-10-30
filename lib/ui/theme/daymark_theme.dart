import 'package:flutter/material.dart';

abstract final class DaymarkColors {
  static bool dark = false;
  static Color backgroundFor(bool value) =>
      Color(value ? 0xff101a26 : 0xfff7f9fb);
  static Color surfaceFor(bool value) => Color(value ? 0xff182738 : 0xfffcfdff);
  static Color inkFor(bool value) => Color(value ? 0xffedf4fb : 0xff0d2043);
  static Color mutedFor(bool value) => Color(value ? 0xffb0c4d8 : 0xff4c648a);
  static Color borderFor(bool value) => Color(value ? 0xff344b60 : 0xffdfe6ef);
  static Color primaryFor(bool value) => Color(value ? 0xff52aeed : 0xff006fa6);
  static Color get background => backgroundFor(dark);
  static Color get surface => surfaceFor(dark);
  static Color get sidebar => Color(dark ? 0xff09131e : 0xff152c42);
  static Color get sidebarSelected => Color(dark ? 0xff164b6c : 0xff164b6c);
  static Color get ink => inkFor(dark);
  static Color get muted => mutedFor(dark);
  static Color get border => borderFor(dark);
  static Color get primary => primaryFor(dark);
  static Color get active => Color(dark ? 0xff52aeed : 0xff0785ff);
  static Color get activeSurface => Color(dark ? 0xff203e58 : 0xffe5f4ff);
  static Color get success => Color(dark ? 0xff63c68b : 0xff128348);
}

ThemeData daymarkTheme({bool dark = false}) => ThemeData(
  useMaterial3: true,
  brightness: dark ? Brightness.dark : Brightness.light,
  scaffoldBackgroundColor: DaymarkColors.backgroundFor(dark),
  colorScheme: ColorScheme.fromSeed(
    brightness: dark ? Brightness.dark : Brightness.light,
    seedColor: DaymarkColors.primaryFor(dark),
    primary: DaymarkColors.primaryFor(dark),
    surface: DaymarkColors.surfaceFor(dark),
    onSurface: DaymarkColors.inkFor(dark),
  ),
  dividerColor: DaymarkColors.borderFor(dark),
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: DaymarkColors.inkFor(dark),
    displayColor: DaymarkColors.inkFor(dark),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: DaymarkColors.mutedFor(dark),
      backgroundColor: DaymarkColors.surfaceFor(dark),
      side: BorderSide(color: DaymarkColors.borderFor(dark)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      minimumSize: const Size(44, 46),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    ),
  ),
);
