import 'package:flutter/material.dart';

/// Design tokens for Pilotta's visual identity: a "felt table" direction —
/// deep card-table green with warm wood and gold accents — chosen because
/// this is a social, tactile game people play in short bursts (often
/// outdoors, often mid-conversation), not a productivity app. The palette
/// stays deliberately warm and high-contrast so it reads clearly in bright
/// light, and it's intentionally distinct from the red/black of the cards
/// themselves: suit colors ([suitRed]/[suitBlack]) are reserved for card
/// faces only, never used as general UI accents, so the eye always knows
/// "that red means hearts/diamonds," not "that's an error."
///
/// Naming follows a 900 (darkest) -> 50 (lightest) scale per hue, so a
/// screen can pick "two steps lighter than the base surface" without
/// hand-picking a new hex value.
abstract final class PilottaColors {
  // ---- Felt (surfaces) ---------------------------------------------
  // The table itself. Scaffold background is the darkest; each step up is
  // a surface that visually sits "on top of" the felt (cards, panels,
  // sheets), like stacking objects on a real table.
  static const felt900 = Color(0xFF07231A); // app background
  static const felt800 = Color(0xFF0E3428); // base table surface
  static const felt700 = Color(0xFF154536); // panels, list rows
  static const felt600 = Color(0xFF1F5A47); // hover / active / selected

  // ---- Gold (primary accent) -----------------------------------------
  // The "chip and card-edge" color: primary actions, the active turn
  // indicator, trump-suit emphasis, the app's one "look here" color.
  static const gold500 = Color(0xFFD9A94E);
  static const gold300 = Color(0xFFEAC97E); // lighter, for borders/glows
  static const gold700 = Color(0xFFA9793A); // pressed/darker state

  // ---- Wood (secondary tactile accent) -------------------------------
  // Used sparingly for dividers, card-back trim, and secondary buttons —
  // gives the "wooden table edge" warmth without competing with gold.
  static const wood600 = Color(0xFF8A5A3B);
  static const wood800 = Color(0xFF5C3B27);

  // ---- Semantic ---------------------------------------------------------
  static const success500 = Color(0xFF4FAE85); // contract made, won a hand
  static const danger500 = Color(0xFFE0654A); // failed contract, errors —
  // deliberately terracotta/orange-red rather than crimson, so it never
  // reads as "that's a heart/diamond".
  static const infoOnline = Color(0xFF4FA3D1); // Online mode accent
  static const localBluetooth = Color(0xFFE08A3C); // Bluetooth/local accent

  // ---- Ink (text on the felt) -----------------------------------------
  static const ink50 = Color(0xFFF7F3E8); // primary text (warm ivory)
  static const ink200 = Color(0xFFDCD4C0); // secondary text
  static const ink400 = Color(0xFFA79C86); // tertiary / disabled text
  static const ink900 = Color(0xFF1B1B1B); // text on light/gold surfaces

  // ---- Card faces (functional only — never used as app chrome) -------
  static const cardFace = Color(0xFFFDFBF6);
  static const suitRed = Color(0xFFC62828);
  static const suitBlack = Color(0xFF1B1B1B);

  /// Soft, warm-tinted shadows instead of Material's default cool-gray
  /// ones, so elevated surfaces feel like they're resting on felt rather
  /// than floating over a generic app background.
  static List<BoxShadow> shadowResting = [
    BoxShadow(color: felt900.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> shadowRaised = [
    BoxShadow(color: felt900.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 6)),
  ];

  static List<BoxShadow> shadowFloating = [
    BoxShadow(color: felt900.withValues(alpha: 0.55), blurRadius: 28, offset: const Offset(0, 12)),
  ];
}
