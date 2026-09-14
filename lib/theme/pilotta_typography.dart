import 'package:flutter/material.dart';

import 'pilotta_colors.dart';

/// Pilotta's type scale.
///
/// Body/UI text stays on Roboto (bundled directly as an app asset — see
/// pubspec.yaml), which renders identically on Android, iOS, and web with
/// zero dependency on a font CDN being reachable. The wordmark and section
/// headers use a bundled serif display face (Alegreya, same
/// zero-CDN-dependency bundling as Roboto) instead — a card-game wordmark
/// reads as a wordmark rather than a generic app title with a display
/// face, and that same face carried into headers gives every screen a
/// "printed ledger" feel instead of flat sans-serif signage everywhere.
abstract final class PilottaTypography {
  /// The wordmark / big screen titles ("ΠΙΛΟΤΤΑ").
  static const display = TextStyle(
    fontFamily: 'Alegreya',
    fontSize: 44,
    fontWeight: FontWeight.w800,
    letterSpacing: 2,
    color: PilottaColors.ink50,
    height: 1.05,
  );

  /// Screen-level titles (app bar titles, dialog headers).
  static const headline = TextStyle(
    fontFamily: 'Alegreya',
    fontSize: 23,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: PilottaColors.ink50,
  );

  /// Section / card titles ("Δημιουργία νέου δωματίου").
  static const title = TextStyle(
    fontFamily: 'Alegreya',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: PilottaColors.ink50,
  );

  /// Button labels, list item titles. w700 rather than w600 deliberately —
  /// the bundled Roboto only ships discrete weights 400/500/700/900 (see
  /// pubspec.yaml), and requesting an unregistered weight like 600 for a
  /// multi-file (non-variable) family isn't guaranteed to fall back onto a
  /// real glyph outline the way it does for a single-file variable font;
  /// it rendered as tofu boxes in testing. Every Roboto style in this
  /// class now requests only a weight that has an exact matching asset.
  static const label = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
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

  /// Big numeric readouts (score, bid value). w900 rather than w800 for
  /// the same exact-registered-weight reason as [label] above.
  static const numeric = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
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
