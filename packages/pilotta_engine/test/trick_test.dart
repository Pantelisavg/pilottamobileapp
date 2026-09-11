import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Trick.legalPlays', () {
    test('must follow suit when possible', () {
      final trick = Trick(leader: Seat.south, trumpSuit: Suit.spades);
      trick.play(Seat.south, const PlayingCard(Suit.hearts, Rank.king));

      final hand = [
        const PlayingCard(Suit.hearts, Rank.seven),
        const PlayingCard(Suit.clubs, Rank.ace),
        const PlayingCard(Suit.spades, Rank.jack),
      ];
      final legal = trick.legalPlays(hand);
      expect(legal, [const PlayingCard(Suit.hearts, Rank.seven)]);
    });

    test('must trump when void of the led suit', () {
      final trick = Trick(leader: Seat.south, trumpSuit: Suit.spades);
      trick.play(Seat.south, const PlayingCard(Suit.hearts, Rank.king));

      final hand = [
        const PlayingCard(Suit.clubs, Rank.ace),
        const PlayingCard(Suit.spades, Rank.seven),
      ];
      final legal = trick.legalPlays(hand);
      expect(legal, [const PlayingCard(Suit.spades, Rank.seven)]);
    });

    test('free discard when void of led suit and out of trump', () {
      final trick = Trick(leader: Seat.south, trumpSuit: Suit.spades);
      trick.play(Seat.south, const PlayingCard(Suit.hearts, Rank.king));

      final hand = [
        const PlayingCard(Suit.clubs, Rank.ace),
        const PlayingCard(Suit.diamonds, Rank.seven),
      ];
      final legal = trick.legalPlays(hand);
      expect(legal.toSet(), hand.toSet());
    });

    test('must overtrump when following suit in trump and able to', () {
      // Trump order: J, 9, A, 10, K, Q, 8, 7 — King beats Queen but Queen
      // does not beat King.
      final trick = Trick(leader: Seat.south, trumpSuit: Suit.spades);
      trick.play(Seat.south, const PlayingCard(Suit.spades, Rank.king));

      final hand = [
        const PlayingCard(Suit.spades, Rank.queen), // does not beat king
        const PlayingCard(Suit.spades, Rank.ace), // beats king
      ];
      final legal = trick.legalPlays(hand);
      expect(legal, [const PlayingCard(Suit.spades, Rank.ace)]);
    });

    test('may play any trump if none can overtake the current trump', () {
      final trick = Trick(leader: Seat.south, trumpSuit: Suit.spades);
      trick.play(Seat.south, const PlayingCard(Suit.spades, Rank.jack));

      final hand = [
        const PlayingCard(Suit.spades, Rank.nine),
        const PlayingCard(Suit.spades, Rank.seven),
      ];
      final legal = trick.legalPlays(hand);
      expect(legal.toSet(), hand.toSet());
    });

    test('void of led suit but holding trump must overtake existing trump', () {
      final trick = Trick(leader: Seat.south, trumpSuit: Suit.spades);
      trick.play(Seat.south, const PlayingCard(Suit.hearts, Rank.ace));
      trick.play(Seat.west, const PlayingCard(Suit.spades, Rank.king));

      final hand = [
        const PlayingCard(Suit.spades, Rank.queen), // does not beat king
        const PlayingCard(Suit.spades, Rank.ace), // beats king
      ];
      final legal = trick.legalPlays(hand);
      expect(legal, [const PlayingCard(Suit.spades, Rank.ace)]);
    });

    test('leader may play anything', () {
      final trick = Trick(leader: Seat.south, trumpSuit: Suit.spades);
      final hand = [
        const PlayingCard(Suit.hearts, Rank.seven),
        const PlayingCard(Suit.clubs, Rank.ace),
      ];
      expect(trick.legalPlays(hand).toSet(), hand.toSet());
    });
  });

  group('Trick winner + points', () {
    test('highest trump wins regardless of led suit', () {
      final trick = Trick(leader: Seat.south, trumpSuit: Suit.spades)
        ..play(Seat.south, const PlayingCard(Suit.hearts, Rank.ace))
        ..play(Seat.west, const PlayingCard(Suit.spades, Rank.seven))
        ..play(Seat.north, const PlayingCard(Suit.hearts, Rank.ten))
        ..play(Seat.east, const PlayingCard(Suit.hearts, Rank.king));

      expect(trick.isComplete, isTrue);
      expect(trick.winner, Seat.west); // only trump played
      // 11 (hearts A) + 0 (spades 7 trump) + 10 (hearts 10) + 4 (hearts K)
      expect(trick.points, 11 + 0 + 10 + 4);
    });

    test('highest card of led suit wins when no trump played', () {
      final trick = Trick(leader: Seat.north, trumpSuit: Suit.spades)
        ..play(Seat.north, const PlayingCard(Suit.diamonds, Rank.king))
        ..play(Seat.east, const PlayingCard(Suit.diamonds, Rank.ace))
        ..play(Seat.south, const PlayingCard(Suit.clubs, Rank.seven))
        ..play(Seat.west, const PlayingCard(Suit.diamonds, Rank.seven));

      expect(trick.winner, Seat.east);
    });
  });
}
