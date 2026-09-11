import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

Color suitColor(Suit suit) => suit.isRed ? const Color(0xFFC62828) : const Color(0xFF1B1B1B);

String suitSymbol(Suit suit) {
  switch (suit) {
    case Suit.hearts:
      return '♥';
    case Suit.diamonds:
      return '♦';
    case Suit.clubs:
      return '♣';
    case Suit.spades:
      return '♠';
  }
}

/// Renders one playing card, either face up or as a card back.
class PlayingCardWidget extends StatelessWidget {
  final PlayingCard? card;
  final bool faceUp;
  final bool selectable;
  final bool dimmed;
  final VoidCallback? onTap;
  final double width;

  const PlayingCardWidget({
    super.key,
    this.card,
    this.faceUp = true,
    this.selectable = false,
    this.dimmed = false,
    this.onTap,
    this.width = 56,
  });

  @override
  Widget build(BuildContext context) {
    final height = width * 1.45;
    final child = faceUp && card != null ? _face(card!) : _back();

    return GestureDetector(
      onTap: selectable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        margin: EdgeInsets.only(bottom: selectable ? 0 : 0),
        transform: selectable ? (Matrix4.identity()..translateByDouble(0, -6, 0, 1)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(width * 0.12),
          border: Border.all(
            color: selectable ? const Color(0xFFFFC107) : Colors.black26,
            width: selectable ? 2.5 : 1,
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
    final symbol = suitSymbol(c.suit);
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
                            color: color, fontWeight: FontWeight.bold, fontSize: fontSize * 0.62, height: 1)),
                    Text(symbol, style: TextStyle(color: color, fontSize: fontSize * 0.5, height: 1)),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(symbol, style: TextStyle(color: color, fontSize: fontSize)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _back() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4D3E), Color(0xFF0E2E24)],
        ),
      ),
      child: Center(
        child: Container(
          width: width * 0.55,
          height: width * 0.55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 2),
          ),
        ),
      ),
    );
  }
}
