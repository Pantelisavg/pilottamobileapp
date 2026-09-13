import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/widgets/hand_sort.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

void main() {
  test('groups by suit, high rank first, suit groups alternating red/black', () {
    final hand = [
      const PlayingCard(Suit.spades, Rank.seven),
      const PlayingCard(Suit.diamonds, Rank.king),
      const PlayingCard(Suit.clubs, Rank.ace),
      const PlayingCard(Suit.hearts, Rank.queen),
      const PlayingCard(Suit.hearts, Rank.ace),
      const PlayingCard(Suit.diamonds, Rank.seven),
      const PlayingCard(Suit.clubs, Rank.seven),
      const PlayingCard(Suit.spades, Rank.ace),
    ];

    final sorted = sortedForHand(hand);

    // Suit groups appear in hearts(R), clubs(B), diamonds(R), spades(B)
    // order — adjacent groups always different colors.
    final suitSequence = sorted.map((c) => c.suit).toSet().toList();
    expect(suitSequence, [Suit.hearts, Suit.clubs, Suit.diamonds, Suit.spades]);
    for (var i = 0; i < suitSequence.length - 1; i++) {
      expect(suitSequence[i].isRed, isNot(suitSequence[i + 1].isRed));
    }

    // Within each suit group, highest rank comes first.
    expect(sorted[0].suit, Suit.hearts);
    expect(sorted[0].rank, Rank.ace);
    expect(sorted[1].suit, Suit.hearts);
    expect(sorted[1].rank, Rank.queen);
  });
}
