import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import '../settings/card_deck_style.dart';
import 'hand_card.dart';

/// A player's hand, laid out as an overlapping fan that always fits the
/// available width — cards stay large and readable regardless of hand
/// size, overlapping just enough to fit instead of shrinking or forcing a
/// horizontal scroll.
class FannedHand extends StatelessWidget {
  final List<PlayingCard> cards;
  final Set<PlayingCard> legal;
  final bool isMyTurn;
  final String? Function(PlayingCard card)? reasonFor;
  final void Function(PlayingCard card) onTap;
  final double cardScale;
  final CardDeckStyle deckStyle;

  const FannedHand({
    super.key,
    required this.cards,
    required this.legal,
    required this.isMyTurn,
    this.reasonFor,
    required this.onTap,
    this.cardScale = 1.0,
    this.deckStyle = CardDeckStyle.classic,
  });

  static const double _baseWidth = 66;
  static const double _minOverlapFraction = 0.34;

  @override
  Widget build(BuildContext context) {
    final cardWidth = _baseWidth * cardScale;
    final cardHeight = cardWidth * 1.45;
    final n = cards.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        double spacing;
        if (n <= 1) {
          spacing = cardWidth;
        } else {
          // Prefer a comfortable small gap between cards; overlap only as
          // much as needed to fit, down to a legibility floor.
          final comfortable = cardWidth + 6;
          final fitsComfortably = comfortable * (n - 1) + cardWidth <= maxWidth;
          if (fitsComfortably) {
            spacing = comfortable;
          } else {
            spacing = (maxWidth - cardWidth) / (n - 1);
            spacing =
                spacing.clamp(cardWidth * _minOverlapFraction, comfortable);
          }
        }
        final totalWidth = n == 0 ? 0.0 : spacing * (n - 1) + cardWidth;
        final startX = (maxWidth - totalWidth) / 2;

        return SizedBox(
          height: cardHeight + 12,
          child: Stack(
            children: [
              for (var i = 0; i < n; i++)
                Positioned(
                  left: startX + spacing * i,
                  bottom: 0,
                  child: buildHandCard(
                    card: cards[i],
                    selectable: isMyTurn && legal.contains(cards[i]),
                    dimmed: isMyTurn && !legal.contains(cards[i]),
                    reason: isMyTurn && !legal.contains(cards[i])
                        ? reasonFor?.call(cards[i])
                        : null,
                    onTap: () => onTap(cards[i]),
                    width: cardWidth,
                    style: deckStyle,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
