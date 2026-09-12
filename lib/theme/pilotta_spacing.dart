/// A 4px-base spacing scale, used instead of hand-picked padding numbers so
/// density stays consistent across screens. Names describe relative size,
/// not pixel values, so the scale can be retuned in one place later.
abstract final class PilottaSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii. [pill] is used for buttons/badges/chips (fully rounded);
/// [lg] is the standard "panel resting on the table" radius.
abstract final class PilottaRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}

/// Minimum touch target size (Material/HIG accessibility baseline). Used
/// for every tappable control so the game stays usable one-handed,
/// mid-conversation, in bright outdoor light.
abstract final class PilottaTouchTarget {
  static const double min = 48;
  static const double comfortable = 56;
}
