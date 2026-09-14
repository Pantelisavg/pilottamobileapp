/// The visual style used to draw every playing card in the app — both
/// fully original CustomPainter-drawn looks (see [PlayingCardWidget]), no
/// bundled image assets either way.
enum CardDeckStyle {
  /// The original look: plain white face, corner index, one centered
  /// suit glyph.
  classic,

  /// An alternate look: ivory face, a bordered corner badge, and a
  /// decorative ringed suit glyph — a different deck, not a reskin.
  modern;

  String get displayName => switch (this) {
        CardDeckStyle.classic => 'Κλασική',
        CardDeckStyle.modern => 'Μοντέρνα',
      };
}
