import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/widgets/hand_sort.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

void main() {
  test('groups by suit, high rank first, suit groups alternating red/black',
      () {
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

  test(
      'sorts by plain face value (A, K, Q, J, 10, 9, 8, 7), not trick-taking '
      'strength (A, 10, K, Q, J, 9, 8, 7)', () {
    final hand = [
      const PlayingCard(Suit.hearts, Rank.ten),
      const PlayingCard(Suit.hearts, Rank.king),
      const PlayingCard(Suit.hearts, Rank.ace),
    ];

    final sorted = sortedForHand(hand);

    // King must come right after Ace here — under the trick-taking order
    // (A, 10, K, Q, ...) the Ten would sort ahead of the King instead.
    expect(sorted.map((c) => c.rank).toList(), [Rank.ace, Rank.king, Rank.ten]);
  });

  test('ascending: true reverses the rank order within each suit group', () {
    final hand = [
      const PlayingCard(Suit.hearts, Rank.ace),
      const PlayingCard(Suit.hearts, Rank.king),
      const PlayingCard(Suit.hearts, Rank.seven),
    ];

    final sorted = sortedForHand(hand, ascending: true);

    expect(
        sorted.map((c) => c.rank).toList(), [Rank.seven, Rank.king, Rank.ace]);
  });
}
