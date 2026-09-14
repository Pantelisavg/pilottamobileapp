import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import '../settings/card_deck_style.dart';
import '../theme/pilotta_colors.dart';
import 'suit_icon.dart';

Color suitColor(Suit suit) =>
    suit.isRed ? const Color(0xFFC62828) : const Color(0xFF1B1B1B);

/// Renders one playing card, either face up or as a card back, in
/// whichever [CardDeckStyle] the caller passes — the one rendering seam
/// every card in the app goes through, so a deck-style choice applies
/// everywhere uniformly. Defaults to [CardDeckStyle.classic] so existing
/// call sites that don't care about the setting need no changes.
class PlayingCardWidget extends StatelessWidget {
  final PlayingCard? card;
  final bool faceUp;
  final bool selectable;
  final bool dimmed;
  final VoidCallback? onTap;
  final double width;
  final CardDeckStyle style;

  const PlayingCardWidget({
    super.key,
    this.card,
    this.faceUp = true,
    this.selectable = false,
    this.dimmed = false,
    this.onTap,
    this.width = 56,
    this.style = CardDeckStyle.classic,
  });

  @override
  Widget build(BuildContext context) {
    final height = width * 1.45;
    final child = faceUp && card != null
        ? (style == CardDeckStyle.modern ? _modernFace(card!) : _face(card!))
        : (style == CardDeckStyle.modern ? _modernBack() : _back());

    return GestureDetector(
      onTap: selectable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        margin: EdgeInsets.only(bottom: selectable ? 0 : 0),
        transform: selectable
            ? (Matrix4.identity()..translateByDouble(0, -6, 0, 1))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          // A faint top-left-to-bottom-right gradient rather than a flat
          // fill, so the face reads as having a touch of glossy thickness
          // instead of a plain white rectangle.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: style == CardDeckStyle.modern
                ? const [Color(0xFFFFFDF7), PilottaColors.cardFace]
                : [Colors.white, PilottaColors.cardFace],
          ),
          borderRadius: BorderRadius.circular(width * 0.12),
          border: Border.all(
            color: selectable
                ? const Color(0xFFFFC107)
                : (style == CardDeckStyle.modern
                    ? const Color(0xFFD9A94E)
                    : Colors.black26),
            width: selectable ? 2.5 : (style == CardDeckStyle.modern ? 1.4 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Opacity(opacity: dimmed ? 0.45 : 1, child: child),
      ),
    );
  }

  Widget _face(PlayingCard c) {
    final color = suitColor(c.suit);
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = constraints.maxWidth * 0.34;
        return Padding(
          padding: EdgeInsets.all(constraints.maxWidth * 0.08),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.rank.short,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize * 0.62,
                            height: 1)),
                    SuitIcon(c.suit, size: fontSize * 0.5, color: color),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: SuitIcon(c.suit, size: fontSize, color: color),
              ),
            ],
          ),
        );
      },
    );
  }

  /// [CardDeckStyle.modern]'s face: a bordered corner badge mirrored at
  /// both ends of the card (as on a real card, so it reads right-way-up
  /// from either side of the table) and a centered suit glyph inside a
  /// decorative ring, rather than classic's plain stacked corner + glyph.
  Widget _modernFace(PlayingCard c) {
    final color = suitColor(c.suit);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final fontSize = w * 0.3;
        Widget corner() => Container(
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.05, vertical: w * 0.02),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 1),
                borderRadius: BorderRadius.circular(w * 0.06),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.rank.short,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize * 0.5,
                          height: 1)),
                  SuitIcon(c.suit, size: fontSize * 0.4, color: color),
                ],
              ),
            );

        return Padding(
          padding: EdgeInsets.all(w * 0.07),
          child: Stack(
            children: [
              Align(alignment: Alignment.topLeft, child: corner()),
              Align(
                alignment: Alignment.bottomRight,
                child: Transform.rotate(angle: 3.14159, child: corner()),
              ),
              Center(
                child: Container(
                  padding: EdgeInsets.all(fontSize * 0.18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: color.withValues(alpha: 0.5), width: 1.2),
                  ),
                  child: SuitIcon(c.suit, size: fontSize, color: color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// [CardDeckStyle.modern]'s back: a navy field with a gold diamond
  /// lattice, in place of classic's plain green gradient + circle.
  Widget _modernBack() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16213A), Color(0xFF0B1424)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.12),
        child: CustomPaint(
          size: Size(width, width * 1.45),
          painter: _ModernBackPainter(),
        ),
      ),
    );
  }

  Widget _back() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PilottaColors.felt600, PilottaColors.felt900],
        ),
      ),
      child: Center(
        child: Container(
          width: width * 0.55,
          height: width * 0.55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: PilottaColors.gold300.withValues(alpha: 0.45), width: 2),
          ),
        ),
      ),
    );
  }
}

/// A gold diagonal lattice over the navy field of the modern card back —
/// drawn rather than an image so the deck stays asset-free like the rest
/// of the app.
class _ModernBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFFD9A94E).withValues(alpha: 0.35)
      ..strokeWidth = 1;
    const step = 10.0;
    for (var x = -size.height; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), line);
      canvas.drawLine(Offset(x + size.height, 0), Offset(x, size.height), line);
    }

    final border = Paint()
      ..color = const Color(0xFFD9A94E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final inset = size.width * 0.14;
    canvas.drawRect(
      Rect.fromLTWH(
          inset, inset, size.width - inset * 2, size.height - inset * 2),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant _ModernBackPainter oldDelegate) => false;
}
