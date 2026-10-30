import 'package:flutter/material.dart';

/// Die reduzierte Schul- und Markenpalette. Widgets verwenden stattdessen die
/// semantischen Farben aus [DaymarkSemanticColors].
abstract final class DaymarkBrandColors {
  static const petrol = Color(0xff327378);
  static const sage = Color(0xffdce8df);
  static const sand = Color(0xfff3e9d6);
  static const white = Color(0xffffffff);
}

@immutable
class DaymarkSemanticColors extends ThemeExtension<DaymarkSemanticColors> {
  const DaymarkSemanticColors({
    required this.background,
    required this.backgroundSecondary,
    required this.surface,
    required this.surfaceElevated,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.accent,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.divider,
    required this.hover,
    required this.selected,
    required this.disabled,
    required this.onDisabled,
    required this.focus,
    required this.sidebar,
    required this.sidebarSelected,
    required this.onSidebar,
    required this.sidebarIcon,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.error,
    required this.onError,
    required this.info,
    required this.onInfo,
  });

  factory DaymarkSemanticColors.forBrightness(Brightness brightness) =>
      brightness == Brightness.dark
      ? const DaymarkSemanticColors.dark()
      : const DaymarkSemanticColors.light();

  const DaymarkSemanticColors.light()
    : background = const Color(0xfff8f9f7),
      backgroundSecondary = const Color(0xfff1f4f1),
      surface = DaymarkBrandColors.white,
      surfaceElevated = const Color(0xfff1f4f1),
      primary = DaymarkBrandColors.petrol,
      onPrimary = DaymarkBrandColors.white,
      secondary = DaymarkBrandColors.sage,
      onSecondary = const Color(0xff263035),
      accent = DaymarkBrandColors.sand,
      onAccent = const Color(0xff4b4030),
      textPrimary = const Color(0xff263035),
      textSecondary = const Color(0xff667475),
      border = const Color(0xffe3e8e5),
      divider = const Color(0xffe3e8e5),
      hover = const Color(0xfff1f4f1),
      selected = const Color(0xffe5f0ef),
      disabled = const Color(0xffdfe5e1),
      onDisabled = const Color(0xff7b8785),
      focus = DaymarkBrandColors.petrol,
      sidebar = const Color(0xfff1f4f1),
      sidebarSelected = const Color(0xffe5f0ef),
      onSidebar = const Color(0xff263035),
      sidebarIcon = const Color(0xff667475),
      success = const Color(0xff4e765b),
      onSuccess = DaymarkBrandColors.white,
      warning = const Color(0xff80621a),
      onWarning = DaymarkBrandColors.white,
      error = const Color(0xffb3261e),
      onError = DaymarkBrandColors.white,
      info = DaymarkBrandColors.petrol,
      onInfo = DaymarkBrandColors.white;

  const DaymarkSemanticColors.dark()
    : background = const Color(0xff171c1d),
      backgroundSecondary = const Color(0xff293132),
      surface = const Color(0xff202728),
      surfaceElevated = const Color(0xff293132),
      primary = const Color(0xff8ebdb9),
      onPrimary = const Color(0xff172526),
      secondary = const Color(0xff34443c),
      onSecondary = const Color(0xfff1f3f0),
      accent = const Color(0xff4a4133),
      onAccent = const Color(0xfff1f3f0),
      textPrimary = const Color(0xfff1f3f0),
      textSecondary = const Color(0xffa7b3b0),
      border = const Color(0xff343e3d),
      divider = const Color(0xff343e3d),
      hover = const Color(0xff293132),
      selected = const Color(0xff293f40),
      disabled = const Color(0xff303938),
      onDisabled = const Color(0xff87918e),
      focus = const Color(0xff8ebdb9),
      sidebar = const Color(0xff202728),
      sidebarSelected = const Color(0xff293f40),
      onSidebar = const Color(0xfff1f3f0),
      sidebarIcon = const Color(0xffa7b3b0),
      success = const Color(0xff9bc3a7),
      onSuccess = const Color(0xff1d2a24),
      warning = const Color(0xffd8b978),
      onWarning = const Color(0xff2a241a),
      error = const Color(0xffffb4ab),
      onError = const Color(0xff690005),
      info = const Color(0xff8ebdb9),
      onInfo = const Color(0xff172526);

  final Color background;
  final Color backgroundSecondary;
  final Color surface;
  final Color surfaceElevated;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color accent;
  final Color onAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color divider;
  final Color hover;
  final Color selected;
  final Color disabled;
  final Color onDisabled;
  final Color focus;
  final Color sidebar;
  final Color sidebarSelected;
  final Color onSidebar;
  final Color sidebarIcon;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color error;
  final Color onError;
  final Color info;
  final Color onInfo;

  @override
  DaymarkSemanticColors copyWith({
    Color? background,
    Color? backgroundSecondary,
    Color? surface,
    Color? surfaceElevated,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? accent,
    Color? onAccent,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? divider,
    Color? hover,
    Color? selected,
    Color? disabled,
    Color? onDisabled,
    Color? focus,
    Color? sidebar,
    Color? sidebarSelected,
    Color? onSidebar,
    Color? sidebarIcon,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? error,
    Color? onError,
    Color? info,
    Color? onInfo,
  }) => DaymarkSemanticColors(
    background: background ?? this.background,
    backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
    surface: surface ?? this.surface,
    surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    secondary: secondary ?? this.secondary,
    onSecondary: onSecondary ?? this.onSecondary,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    border: border ?? this.border,
    divider: divider ?? this.divider,
    hover: hover ?? this.hover,
    selected: selected ?? this.selected,
    disabled: disabled ?? this.disabled,
    onDisabled: onDisabled ?? this.onDisabled,
    focus: focus ?? this.focus,
    sidebar: sidebar ?? this.sidebar,
    sidebarSelected: sidebarSelected ?? this.sidebarSelected,
    onSidebar: onSidebar ?? this.onSidebar,
    sidebarIcon: sidebarIcon ?? this.sidebarIcon,
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    error: error ?? this.error,
    onError: onError ?? this.onError,
    info: info ?? this.info,
    onInfo: onInfo ?? this.onInfo,
  );

  @override
  DaymarkSemanticColors lerp(covariant DaymarkSemanticColors? other, double t) {
    if (other == null) return this;
    return DaymarkSemanticColors(
      background: Color.lerp(background, other.background, t)!,
      backgroundSecondary: Color.lerp(
        backgroundSecondary,
        other.backgroundSecondary,
        t,
      )!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      onDisabled: Color.lerp(onDisabled, other.onDisabled, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      sidebarSelected: Color.lerp(sidebarSelected, other.sidebarSelected, t)!,
      onSidebar: Color.lerp(onSidebar, other.onSidebar, t)!,
      sidebarIcon: Color.lerp(sidebarIcon, other.sidebarIcon, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
    );
  }
}

/// Kompatibler Zugriff für bestehende Widgets. Die Theme-Erzeugung selbst ist
/// unabhängig von diesem Zustand.
abstract final class DaymarkColors {
  static bool dark = false;

  static DaymarkSemanticColors forBrightness(Brightness brightness) =>
      DaymarkSemanticColors.forBrightness(brightness);
  static DaymarkSemanticColors forDark(bool value) =>
      DaymarkSemanticColors.forBrightness(
        value ? Brightness.dark : Brightness.light,
      );
  static DaymarkSemanticColors get current => forDark(dark);

  static Color backgroundFor(bool value) => forDark(value).background;
  static Color surfaceFor(bool value) => forDark(value).surface;
  static Color inkFor(bool value) => forDark(value).textPrimary;
  static Color mutedFor(bool value) => forDark(value).textSecondary;
  static Color borderFor(bool value) => forDark(value).border;
  static Color primaryFor(bool value) => forDark(value).primary;

  static Color get background => current.background;
  static Color get backgroundSecondary => current.backgroundSecondary;
  static Color get surface => current.surface;
  static Color get surfaceElevated => current.surfaceElevated;
  static Color get primary => current.primary;
  static Color get onPrimary => current.onPrimary;
  static Color get secondary => current.secondary;
  static Color get onSecondary => current.onSecondary;
  static Color get accent => current.accent;
  static Color get onAccent => current.onAccent;
  static Color get ink => current.textPrimary;
  static Color get muted => current.textSecondary;
  static Color get border => current.border;
  static Color get divider => current.divider;
  static Color get hover => current.hover;
  static Color get selected => current.selected;
  static Color get disabled => current.disabled;
  static Color get onDisabled => current.onDisabled;
  static Color get focus => current.focus;
  static Color get sidebar => current.sidebar;
  static Color get sidebarSelected => current.sidebarSelected;
  static Color get onSidebar => current.onSidebar;
  static Color get sidebarIcon => current.sidebarIcon;
  static Color get active => current.focus;
  static Color get activeSurface => current.selected;
  static Color get success => current.success;
  static Color get warning => current.warning;
  static Color get error => current.error;
  static Color get info => current.info;

  static List<Color> get subjectAccents => [primary, secondary, accent];
}

extension DaymarkThemeContext on BuildContext {
  DaymarkSemanticColors get daymarkColors =>
      Theme.of(this).extension<DaymarkSemanticColors>()!;
}

ThemeData daymarkTheme({bool dark = false}) {
  final brightness = dark ? Brightness.dark : Brightness.light;
  final colors = DaymarkSemanticColors.forBrightness(brightness);
  final scheme = ColorScheme.fromSeed(
    brightness: brightness,
    seedColor: DaymarkBrandColors.petrol,
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    secondary: colors.secondary,
    onSecondary: colors.onSecondary,
    tertiary: colors.accent,
    onTertiary: colors.onAccent,
    error: colors.error,
    onError: colors.onError,
    surface: colors.surface,
    onSurface: colors.textPrimary,
    surfaceContainerLowest: colors.background,
    surfaceContainerLow: colors.backgroundSecondary,
    surfaceContainer: colors.surface,
    surfaceContainerHigh: colors.surfaceElevated,
    outline: colors.border,
    outlineVariant: colors.divider,
  );
  final baseTextTheme = ThemeData(brightness: brightness).textTheme
      .apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary);
  final roundedShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(7),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [colors],
    scaffoldBackgroundColor: colors.background,
    canvasColor: colors.background,
    cardColor: colors.surface,
    dividerColor: colors.divider,
    disabledColor: colors.disabled,
    focusColor: colors.focus.withValues(alpha: .22),
    hoverColor: colors.hover,
    highlightColor: colors.selected,
    splashColor: colors.primary.withValues(alpha: .12),
    textTheme: baseTextTheme,
    iconTheme: IconThemeData(color: colors.textSecondary),
    dividerTheme: DividerThemeData(color: colors.divider, thickness: 1),
    cardTheme: CardThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: colors.onPrimary,
        backgroundColor: colors.primary,
        disabledForegroundColor: colors.onDisabled,
        disabledBackgroundColor: colors.disabled,
        shape: roundedShape,
        minimumSize: const Size(44, 46),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        backgroundColor: colors.surface,
        disabledForegroundColor: colors.onDisabled,
        side: BorderSide(color: colors.border),
        shape: roundedShape,
        minimumSize: const Size(44, 46),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        disabledForegroundColor: colors.onDisabled,
        shape: roundedShape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.onDisabled
              : colors.primary,
        ),
        overlayColor: WidgetStatePropertyAll(
          colors.primary.withValues(alpha: .12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      hintStyle: TextStyle(color: colors.textSecondary),
      labelStyle: TextStyle(color: colors.textSecondary),
      floatingLabelStyle: TextStyle(color: colors.primary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(color: colors.focus, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(color: colors.disabled),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TextStyle(color: colors.textPrimary),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.surfaceElevated),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(color: colors.textPrimary),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.primary
            : colors.surface,
      ),
      checkColor: WidgetStatePropertyAll(colors.onPrimary),
      side: BorderSide(color: colors.border),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.primary
            : colors.textSecondary,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.onPrimary
            : colors.textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.primary
            : colors.disabled,
      ),
      trackOutlineColor: WidgetStatePropertyAll(colors.border),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: colors.primary,
      unselectedLabelColor: colors.textSecondary,
      indicatorColor: colors.primary,
      dividerColor: colors.divider,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border),
      ),
      textStyle: TextStyle(color: colors.textPrimary),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.surfaceElevated,
      contentTextStyle: TextStyle(color: colors.textPrimary),
      actionTextColor: colors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.primary,
      linearTrackColor: colors.disabled,
      circularTrackColor: colors.disabled,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(
        colors.textSecondary.withValues(alpha: .55),
      ),
      trackColor: WidgetStatePropertyAll(
        colors.backgroundSecondary.withValues(alpha: .7),
      ),
      trackBorderColor: WidgetStatePropertyAll(colors.border),
    ),
  );
}
