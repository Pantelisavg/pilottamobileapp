import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:test/test.dart';

const trump = Suit.spades;

void main() {
  group('findDeclarations', () {
    test('finds a 3-card sequence', () {
      final hand = [
        const PlayingCard(Suit.hearts, Rank.jack),
        const PlayingCard(Suit.hearts, Rank.queen),
        const PlayingCard(Suit.hearts, Rank.king),
        const PlayingCard(Suit.clubs, Rank.seven),
      ];
      final decls = findDeclarations(Seat.south, hand);
      expect(decls, hasLength(1));
      expect(decls.first.kind, DeclarationKind.sequence);
      expect(decls.first.length, 3);
      expect(decls.first.pointValue(), 20);
    });

    test('finds a carre (four of a kind)', () {
      final hand = [
        const PlayingCard(Suit.hearts, Rank.jack),
        const PlayingCard(Suit.diamonds, Rank.jack),
        const PlayingCard(Suit.clubs, Rank.jack),
        const PlayingCard(Suit.spades, Rank.jack),
      ];
      final decls = findDeclarations(Seat.south, hand);
      expect(decls, hasLength(1));
      expect(decls.first.kind, DeclarationKind.carre);
      expect(decls.first.pointValue(), 200);
    });

    test('four nines score 150, other carres score 100', () {
      final nines = [
        const PlayingCard(Suit.hearts, Rank.nine),
        const PlayingCard(Suit.diamonds, Rank.nine),
        const PlayingCard(Suit.clubs, Rank.nine),
        const PlayingCard(Suit.spades, Rank.nine),
      ];
      expect(findDeclarations(Seat.south, nines).first.pointValue(), 150);

      final kings = [
        const PlayingCard(Suit.hearts, Rank.king),
        const PlayingCard(Suit.diamonds, Rank.king),
        const PlayingCard(Suit.clubs, Rank.king),
        const PlayingCard(Suit.spades, Rank.king),
      ];
      expect(findDeclarations(Seat.south, kings).first.pointValue(), 100);
    });

    test('sequence lengths score 20/50/100 for 3/4/5+', () {
      List<PlayingCard> runOf(int n) => List.generate(
          n, (i) => PlayingCard(Suit.hearts, declarationRankOrderHighToLow[i]));

      expect(findDeclarations(Seat.south, runOf(3)).first.pointValue(), 20);
      expect(findDeclarations(Seat.south, runOf(4)).first.pointValue(), 50);
      expect(findDeclarations(Seat.south, runOf(5)).first.pointValue(), 100);
    });

    test('non-consecutive same-suit cards do not form a sequence', () {
      final hand = [
        const PlayingCard(Suit.hearts, Rank.ace),
        const PlayingCard(Suit.hearts, Rank.queen),
        const PlayingCard(Suit.hearts, Rank.seven),
      ];
      expect(findDeclarations(Seat.south, hand), isEmpty);
    });

    test('four sevens or four eights are not a declarable carre — only '
        'Jack/9/Ace/10/King/Queen are, per the rules\' own list', () {
      final sevens = [
        const PlayingCard(Suit.hearts, Rank.seven),
        const PlayingCard(Suit.diamonds, Rank.seven),
        const PlayingCard(Suit.clubs, Rank.seven),
        const PlayingCard(Suit.spades, Rank.seven),
      ];
      expect(findDeclarations(Seat.south, sevens), isEmpty);

      final eights = [
        const PlayingCard(Suit.hearts, Rank.eight),
        const PlayingCard(Suit.diamonds, Rank.eight),
        const PlayingCard(Suit.clubs, Rank.eight),
        const PlayingCard(Suit.spades, Rank.eight),
      ];
      expect(findDeclarations(Seat.south, eights), isEmpty);
    });
  });

  group('Declaration.compareTo', () {
    test('a carre beats a lower-value sequence', () {
      final carre = Declaration.carre(Seat.south, [
        const PlayingCard(Suit.hearts, Rank.king),
        const PlayingCard(Suit.diamonds, Rank.king),
        const PlayingCard(Suit.clubs, Rank.king),
        const PlayingCard(Suit.spades, Rank.king),
      ]);
      final sequence = Declaration.sequence(Seat.west, [
        const PlayingCard(Suit.clubs, Rank.ace),
        const PlayingCard(Suit.clubs, Rank.king),
        const PlayingCard(Suit.clubs, Rank.queen),
      ]);
      expect(carre.compareTo(sequence, trump), greaterThan(0));
    });

    test('a carre and a sequence tied at the same point value (100) are a '
        'genuine tie, not an automatic carre win — the rules group a '
        '5+ sequence and an Ace/10/King/Queen carre under the same '
        '"Εκατοστάρι" (100) tier with no further ordering rule between them', () {
      final carre = Declaration.carre(Seat.south, [
        const PlayingCard(Suit.hearts, Rank.king),
        const PlayingCard(Suit.diamonds, Rank.king),
        const PlayingCard(Suit.clubs, Rank.king),
        const PlayingCard(Suit.spades, Rank.king),
      ]);
      final sequence = Declaration.sequence(Seat.west, [
        const PlayingCard(Suit.hearts, Rank.ace),
        const PlayingCard(Suit.hearts, Rank.king),
        const PlayingCard(Suit.hearts, Rank.queen),
        const PlayingCard(Suit.hearts, Rank.jack),
        const PlayingCard(Suit.hearts, Rank.ten),
      ]);
      expect(carre.compareTo(sequence, trump), 0);
      expect(sequence.compareTo(carre, trump), 0);
    });

    test('four jacks beats four nines beats other carre', () {
      Declaration carreOf(Rank rank) => Declaration.carre(Seat.south, [
            PlayingCard(Suit.hearts, rank),
            PlayingCard(Suit.diamonds, rank),
            PlayingCard(Suit.clubs, rank),
            PlayingCard(Suit.spades, rank),
          ]);

      final jacks = carreOf(Rank.jack);
      final nines = carreOf(Rank.nine);
      final kings = carreOf(Rank.king);
      expect(jacks.compareTo(nines, trump), greaterThan(0));
      expect(nines.compareTo(kings, trump), greaterThan(0));
    });

    test('longer sequence beats shorter regardless of rank', () {
      final long = Declaration.sequence(Seat.south, [
        const PlayingCard(Suit.hearts, Rank.ten),
        const PlayingCard(Suit.hearts, Rank.nine),
        const PlayingCard(Suit.hearts, Rank.eight),
        const PlayingCard(Suit.hearts, Rank.seven),
      ]);
      final short = Declaration.sequence(Seat.west, [
        const PlayingCard(Suit.clubs, Rank.ace),
        const PlayingCard(Suit.clubs, Rank.king),
        const PlayingCard(Suit.clubs, Rank.queen),
      ]);
      expect(long.length, 4);
      expect(long.compareTo(short, trump), greaterThan(0));
    });

    test('equal length: higher-ranked sequence wins', () {
      final higher = Declaration.sequence(Seat.south, [
        const PlayingCard(Suit.hearts, Rank.ace),
        const PlayingCard(Suit.hearts, Rank.king),
        const PlayingCard(Suit.hearts, Rank.queen),
      ]);
      final lower = Declaration.sequence(Seat.west, [
        const PlayingCard(Suit.clubs, Rank.nine),
        const PlayingCard(Suit.clubs, Rank.eight),
        const PlayingCard(Suit.clubs, Rank.seven),
      ]);
      expect(higher.compareTo(lower, trump), greaterThan(0));
    });

    test('equal length and rank: trump-suit sequence wins', () {
      final trumpSeq = Declaration.sequence(Seat.south, [
        const PlayingCard(Suit.spades, Rank.ace),
        const PlayingCard(Suit.spades, Rank.king),
        const PlayingCard(Suit.spades, Rank.queen),
      ]);
      final plainSeq = Declaration.sequence(Seat.west, [
        const PlayingCard(Suit.clubs, Rank.ace),
        const PlayingCard(Suit.clubs, Rank.king),
        const PlayingCard(Suit.clubs, Rank.queen),
      ]);
      expect(trumpSeq.compareTo(plainSeq, trump), greaterThan(0));
      expect(plainSeq.compareTo(trumpSeq, trump), lessThan(0));
    });
  });

  group('bestDeclaration', () {
    test('picks the single best combination in a hand with multiple', () {
      final hand = [
        const PlayingCard(Suit.hearts, Rank.ace),
        const PlayingCard(Suit.hearts, Rank.king),
        const PlayingCard(Suit.hearts, Rank.queen),
        const PlayingCard(Suit.hearts, Rank.jack), // hearts A-K-Q-J: seq of 4
        const PlayingCard(Suit.clubs, Rank.seven),
      ];
      final best = bestDeclaration(Seat.south, hand, trump);
      expect(best, isNotNull);
      expect(best!.length, 4);
      expect(best.pointValue(), 50);
    });

    test('returns null when hand has no declarations', () {
      final hand = [
        const PlayingCard(Suit.hearts, Rank.ace),
        const PlayingCard(Suit.clubs, Rank.seven),
        const PlayingCard(Suit.diamonds, Rank.nine),
      ];
      expect(bestDeclaration(Seat.south, hand, trump), isNull);
    });
  });
}
