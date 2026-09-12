import 'package:flutter/material.dart';

import 'pilotta_colors.dart';

/// Pilotta's type scale.
///
/// Deliberately uses Roboto (bundled directly as an app asset — see
/// pubspec.yaml) rather than a custom display face: it renders identically
/// on Android, iOS, and web with zero dependency on a font CDN being
/// reachable, and no per-platform substitution to design around later.
/// Character comes from weight, letter-spacing, and color instead of a
/// novelty typeface — a bold, tracked-out, uppercase display style reads
/// as "casino signage" without risking legibility.
abstract final class PilottaTypography {
  /// The wordmark / big screen titles ("ΠΙΛΟΤΤΑ").
  static const display = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: 4,
    color: PilottaColors.ink50,
    height: 1.05,
  );

  /// Screen-level titles (app bar titles, dialog headers).
  static const headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: PilottaColors.ink50,
  );

  /// Section / card titles ("Δημιουργία νέου δωματίου").
  static const title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: PilottaColors.ink50,
  );

  /// Button labels, list item titles.
  static const label = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: PilottaColors.ink50,
  );

  /// Primary body text.
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: PilottaColors.ink50,
    height: 1.3,
  );

  /// Secondary / supporting text.
  static const bodyMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: PilottaColors.ink200,
    height: 1.3,
  );

  /// Captions, badges, chip labels — small and tracked out for legibility
  /// at tiny sizes.
  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: PilottaColors.ink200,
  );

  /// Big numeric readouts (score, bid value).
  static const numeric = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: PilottaColors.ink50,
    height: 1,
  );

  static TextTheme buildTextTheme() {
    return const TextTheme(
      displayLarge: display,
      headlineMedium: headline,
      titleLarge: title,
      titleMedium: label,
      bodyLarge: body,
      bodyMedium: bodyMuted,
      labelSmall: caption,
    );
  }
}
