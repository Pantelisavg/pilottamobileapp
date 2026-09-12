import 'package:flutter/material.dart';

import 'pilotta_colors.dart';
import 'pilotta_spacing.dart';
import 'pilotta_typography.dart';

/// Builds the app's single [ThemeData]. Pilotta is a felt-table game — it
/// doesn't have a "light mode" any more than a real card table does — so
/// this is the only theme, and every screen should pull colors from
/// [PilottaColors] / this theme rather than hard-coding hex values.
ThemeData buildPilottaTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: PilottaColors.felt700,
    brightness: Brightness.dark,
  ).copyWith(
    primary: PilottaColors.gold500,
    onPrimary: PilottaColors.ink900,
    secondary: PilottaColors.wood600,
    onSecondary: PilottaColors.ink50,
    surface: PilottaColors.felt700,
    onSurface: PilottaColors.ink50,
    error: PilottaColors.danger500,
    onError: PilottaColors.ink900,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: PilottaColors.felt900,
    fontFamily: 'Roboto',
    textTheme: PilottaTypography.buildTextTheme(),
    splashFactory: InkSparkle.splashFactory,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: PilottaColors.ink50,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: PilottaTypography.headline,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: PilottaColors.gold500,
        foregroundColor: PilottaColors.ink900,
        disabledBackgroundColor: PilottaColors.felt600,
        disabledForegroundColor: PilottaColors.ink400,
        minimumSize: const Size.fromHeight(PilottaSpacing.xxl + 8),
        textStyle: PilottaTypography.label,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: PilottaSpacing.lg),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PilottaColors.ink50,
        side: const BorderSide(color: PilottaColors.ink400),
        minimumSize: const Size.fromHeight(PilottaSpacing.xxl + 8),
        textStyle: PilottaTypography.label,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: PilottaSpacing.lg),
      ),
    ),

    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: PilottaColors.felt700,
        foregroundColor: PilottaColors.ink200,
        selectedBackgroundColor: PilottaColors.gold500,
        selectedForegroundColor: PilottaColors.ink900,
        side: const BorderSide(color: PilottaColors.felt600),
        textStyle: PilottaTypography.label,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PilottaColors.felt800,
      hintStyle: PilottaTypography.body.copyWith(color: PilottaColors.ink400),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: PilottaSpacing.md, vertical: PilottaSpacing.sm + 2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PilottaColors.gold500, width: 1.5),
      ),
    ),

    cardTheme: CardThemeData(
      color: PilottaColors.felt700,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    dividerTheme: const DividerThemeData(color: PilottaColors.felt600, thickness: 1),
  );
}
