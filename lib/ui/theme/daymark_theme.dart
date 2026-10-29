import 'package:flutter/material.dart';

abstract final class DaymarkColors {
  static const background = Color(0xfff7f9fb);
  static const surface = Color(0xfffcfdff);
  static const sidebar = Color(0xff152c42);
  static const sidebarSelected = Color(0xff164b6c);
  static const ink = Color(0xff0d2043);
  static const muted = Color(0xff4c648a);
  static const border = Color(0xffdfe6ef);
  static const primary = Color(0xff006fa6);
  static const active = Color(0xff0785ff);
  static const activeSurface = Color(0xffe5f4ff);
  static const success = Color(0xff128348);
}

ThemeData daymarkTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: DaymarkColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: DaymarkColors.primary,
    primary: DaymarkColors.primary,
    surface: DaymarkColors.surface,
    onSurface: DaymarkColors.ink,
  ),
  dividerColor: DaymarkColors.border,
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: DaymarkColors.ink,
    displayColor: DaymarkColors.ink,
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: DaymarkColors.muted,
      backgroundColor: DaymarkColors.surface,
      side: const BorderSide(color: DaymarkColors.border),
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
