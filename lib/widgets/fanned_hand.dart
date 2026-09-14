import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import '../settings/card_deck_style.dart';
import 'hand_card.dart';

/// A player's hand, laid out as an overlapping fan that always fits the
/// available width — cards stay large and readable regardless of hand
/// size, overlapping just enough to fit instead of shrinking or forcing a
/// horizontal scroll.
class FannedHand extends StatefulWidget {
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

  @override
  State<FannedHand> createState() => _FannedHandState();
}

class _FannedHandState extends State<FannedHand>
    with SingleTickerProviderStateMixin {
  static const double _baseWidth = 66;
  static const double _minOverlapFraction = 0.34;

  late final AnimationController _dealController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  List<PlayingCard> _previousCards = const [];

  @override
  void initState() {
    super.initState();
    _maybeAnimateDeal(widget.cards);
  }

  @override
  void didUpdateWidget(covariant FannedHand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cards != oldWidget.cards) _maybeAnimateDeal(widget.cards);
  }

  /// A "fresh deal" is a new hand's cards sharing nothing with whatever was
  /// showing before — a played card simply shrinking the same hand doesn't
  /// count, only a brand new 8 (or a resumed/replaced hand) does.
  void _maybeAnimateDeal(List<PlayingCard> newCards) {
    final isFreshDeal = newCards.isNotEmpty &&
        newCards.every((c) => !_previousCards.contains(c));
    _previousCards = newCards;
    if (isFreshDeal) {
      _dealController
        ..value = 0
        ..forward();
    } else {
      _dealController.value = 1;
    }
  }

  @override
  void dispose() {
    _dealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    final cardWidth = _baseWidth * widget.cardScale;
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
        // A small per-card rotation around each card's bottom-center pivot,
        // increasing toward the ends of the hand — real cards fanned in a
        // hand arc slightly rather than stacking perfectly upright.
        final midIndex = (n - 1) / 2;
        const anglePerCard = 0.028;
        const maxAngle = 0.16;

        return SizedBox(
          height: cardHeight + 16,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < n; i++)
                Positioned(
                  key: ValueKey(cards[i]),
                  left: startX + spacing * i,
                  bottom: 0,
                  child: Transform.rotate(
                    angle: n <= 1
                        ? 0
                        : ((i - midIndex) * anglePerCard)
                            .clamp(-maxAngle, maxAngle),
                    alignment: Alignment.bottomCenter,
                    child: AnimatedBuilder(
                      animation: _dealController,
                      builder: (context, child) {
                        // Staggered per-card interval over the shared
                        // controller — card i starts a little after card
                        // i - 1, so the hand fans in rather than popping in
                        // as one block.
                        final interval = Interval(
                          (i / n) * 0.6,
                          (i / n) * 0.6 + 0.4,
                          curve: Curves.easeOutBack,
                        );
                        final t = interval.transform(_dealController.value);
                        return Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 28),
                            child: child,
                          ),
                        );
                      },
                      child: buildHandCard(
                        card: cards[i],
                        selectable:
                            widget.isMyTurn && widget.legal.contains(cards[i]),
                        dimmed:
                            widget.isMyTurn && !widget.legal.contains(cards[i]),
                        reason:
                            widget.isMyTurn && !widget.legal.contains(cards[i])
                                ? widget.reasonFor?.call(cards[i])
                                : null,
                        onTap: () => widget.onTap(cards[i]),
                        width: cardWidth,
                        style: widget.deckStyle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
