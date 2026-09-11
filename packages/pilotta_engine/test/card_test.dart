import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Deck', () {
    test('has exactly 32 unique cards', () {
      final deck = Deck.full();
      expect(deck.length, 32);
      expect(deck.toSet().length, 32);
    });
  });

  group('PlayingCard point values', () {
    test('trump ranks score per the trump table', () {
      const trump = Suit.spades;
      expect(const PlayingCard(Suit.spades, Rank.jack).pointValue(trump), 20);
      expect(const PlayingCard(Suit.spades, Rank.nine).pointValue(trump), 14);
      expect(const PlayingCard(Suit.spades, Rank.ace).pointValue(trump), 11);
      expect(const PlayingCard(Suit.spades, Rank.ten).pointValue(trump), 10);
      expect(const PlayingCard(Suit.spades, Rank.king).pointValue(trump), 4);
      expect(const PlayingCard(Suit.spades, Rank.queen).pointValue(trump), 3);
      expect(const PlayingCard(Suit.spades, Rank.eight).pointValue(trump), 0);
      expect(const PlayingCard(Suit.spades, Rank.seven).pointValue(trump), 0);
    });

    test('plain-suit ranks score per the plain table', () {
      const trump = Suit.spades;
      expect(const PlayingCard(Suit.hearts, Rank.ace).pointValue(trump), 11);
      expect(const PlayingCard(Suit.hearts, Rank.ten).pointValue(trump), 10);
      expect(const PlayingCard(Suit.hearts, Rank.king).pointValue(trump), 4);
      expect(const PlayingCard(Suit.hearts, Rank.queen).pointValue(trump), 3);
      expect(const PlayingCard(Suit.hearts, Rank.jack).pointValue(trump), 2);
      expect(const PlayingCard(Suit.hearts, Rank.nine).pointValue(trump), 0);
      expect(const PlayingCard(Suit.hearts, Rank.eight).pointValue(trump), 0);
      expect(const PlayingCard(Suit.hearts, Rank.seven).pointValue(trump), 0);
    });

    test('all 32 card points sum to 152 for any chosen trump suit', () {
      for (final trump in Suit.values) {
        final total =
            Deck.full().fold(0, (sum, c) => sum + c.pointValue(trump));
        expect(total, 152, reason: 'trump=$trump');
      }
    });
  });

  group('PlayingCard.outranks', () {
    test('trump ordering: J > 9 > A > 10 > K > Q > 8 > 7', () {
      const trump = Suit.clubs;
      const j = PlayingCard(Suit.clubs, Rank.jack);
      const nine = PlayingCard(Suit.clubs, Rank.nine);
      const ace = PlayingCard(Suit.clubs, Rank.ace);
      const ten = PlayingCard(Suit.clubs, Rank.ten);
      const king = PlayingCard(Suit.clubs, Rank.king);
      const queen = PlayingCard(Suit.clubs, Rank.queen);
      const eight = PlayingCard(Suit.clubs, Rank.eight);
      const seven = PlayingCard(Suit.clubs, Rank.seven);

      expect(j.outranks(nine, trump), isTrue);
      expect(nine.outranks(ace, trump), isTrue);
      expect(ace.outranks(ten, trump), isTrue);
      expect(ten.outranks(king, trump), isTrue);
      expect(king.outranks(queen, trump), isTrue);
      expect(queen.outranks(eight, trump), isTrue);
      expect(eight.outranks(seven, trump), isTrue);
      expect(seven.outranks(j, trump), isFalse);
    });

    test('plain ordering: A > 10 > K > Q > J > 9 > 8 > 7', () {
      const trump = Suit.clubs; // hearts is NOT trump here
      const ace = PlayingCard(Suit.hearts, Rank.ace);
      const ten = PlayingCard(Suit.hearts, Rank.ten);
      const king = PlayingCard(Suit.hearts, Rank.king);
      const queen = PlayingCard(Suit.hearts, Rank.queen);
      const jack = PlayingCard(Suit.hearts, Rank.jack);
      const nine = PlayingCard(Suit.hearts, Rank.nine);

      expect(ace.outranks(ten, trump), isTrue);
      expect(ten.outranks(king, trump), isTrue);
      expect(king.outranks(queen, trump), isTrue);
      expect(queen.outranks(jack, trump), isTrue);
      expect(jack.outranks(nine, trump), isTrue);
    });
  });
}
