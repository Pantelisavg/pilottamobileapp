import 'dart:math';

import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:test/test.dart';

/// Plays out every remaining trick by always choosing the first legally
/// available card for whichever seat's turn it is. Good enough for
/// integration tests that only care about invariants (point totals sum
/// correctly) or about a scenario engineered to force a specific outcome.
///
/// Also announces and immediately reveals every seat's declaration up
/// front (mirroring how [SimpleBot] always announces) so tests written
/// before the announce/reveal timing mechanic existed keep exercising the
/// same "declarations always count" scenarios unless they opt out by
/// managing announce/reveal themselves.
void autoPlayToCompletion(PilottaHand hand, {bool autoDeclare = true}) {
  if (autoDeclare) {
    for (final seat in Seat.values) {
      if (hand.canAnnounceDeclaration(seat)) {
        hand.announceDeclaration(seat);
        hand.revealDeclaration(seat);
      }
    }
  }
  while (!hand.isHandComplete) {
    if (hand.currentTrick.isComplete) {
      hand.startNextTrick();
      continue;
    }
    final seat = hand.currentTrick.seatToPlay;
    final card = hand.legalPlays(seat).first;
    hand.playCard(seat, card);
  }
}

void main() {
  group('PilottaHand invariants', () {
    test('trick points always total 162 (or 250/0 on a capot sweep)', () {
      for (var seed = 0; seed < 20; seed++) {
        final hands = dealHands(_seededRandom(seed));
        final contract = Contract(
          biddingSeat: Seat.south,
          trumpSuit: Suit.spades,
          value: 80,
          isCapot: false,
        );
        final hand = PilottaHand(
          contract: contract,
          initialHands: hands,
          firstLeader: Seat.south,
        );
        autoPlayToCompletion(hand);
        final result = hand.finish();

        final ns = result.trickPoints[Team.northSouth]!;
        final ew = result.trickPoints[Team.eastWest]!;
        if (result.allTricksTeam != null) {
          expect(ns + ew, 250, reason: 'seed=$seed');
        } else {
          expect(ns + ew, 162, reason: 'seed=$seed');
        }
      }
    });
  });

  group('PilottaHand capot scenario', () {
    // South holds every trump card; west/north/east hold one full plain
    // suit each. South is therefore always void in every plain suit and
    // must trump every trick it does not lead, so it wins all 8 tricks
    // regardless of how the others discard.
    Map<Seat, List<PlayingCard>> capotDeal() => {
          Seat.south: [for (final r in Rank.values) PlayingCard(Suit.spades, r)],
          Seat.west: [for (final r in Rank.values) PlayingCard(Suit.hearts, r)],
          Seat.north: [for (final r in Rank.values) PlayingCard(Suit.diamonds, r)],
          Seat.east: [for (final r in Rank.values) PlayingCard(Suit.clubs, r)],
        };

    // Note: holding an entire suit is inherently an 8-card sequence (worth
    // the capped 100 points), and south's full spade holding also means it
    // holds trump K+Q (belote, +20). North's own full diamond suit is a
    // second (non-trump) 8-run. Since south's run is length-8 and trump, it
    // beats west/north/east's equally-long plain-suit runs, so northSouth
    // wins the declaration comparison and scores BOTH its players' runs:
    // south's 100 + north's 100 = 200, plus the 20 belote = 220 on top of
    // trick points.
    const declarationsAndBelote = 200 + 20;

    test('sweeping all 8 tricks scores a flat 250 for that team', () {
      final hands = capotDeal();
      final contract = Contract(
        biddingSeat: Seat.south,
        trumpSuit: Suit.spades,
        value: 160,
        isCapot: false,
      );
      final hand = PilottaHand(
        contract: contract,
        initialHands: hands,
        firstLeader: Seat.south,
      );
      autoPlayToCompletion(hand);
      final result = hand.finish();

      expect(result.allTricksTeam, Team.northSouth);
      expect(result.trickPoints[Team.northSouth], 250);
      expect(result.trickPoints[Team.eastWest], 0);
      expect(result.declarations.winningTeam, Team.northSouth);
      expect(result.declarations.winningTeamPoints, 200);
      expect(result.declarations.beloteSeat, Seat.south);
      expect(result.contractMade, isTrue);
      expect(result.rawTotals[Team.northSouth],
          (250 + declarationsAndBelote) + 160);
    });

    test('an explicit Capot contract is only made by literally sweeping all tricks', () {
      final hands = capotDeal();
      final contract = Contract(
        biddingSeat: Seat.south,
        trumpSuit: Suit.spades,
        value: kCapotValue,
        isCapot: true,
      );
      final hand = PilottaHand(
        contract: contract,
        initialHands: hands,
        firstLeader: Seat.south,
      );
      autoPlayToCompletion(hand);
      final result = hand.finish();

      expect(result.contractMade, isTrue);
      expect(result.rawTotals[Team.northSouth],
          (250 + declarationsAndBelote) + kCapotValue);
    });

    test('failing to sweep on a Capot contract awards everything to the defenders', () {
      // Same deal, but this time east/west/north are the bidding side's
      // opponents and it is *their* Capot contract that will fail because
      // south (not on their team) actually takes every trick.
      final hands = capotDeal();
      final contract = Contract(
        biddingSeat: Seat.west,
        trumpSuit: Suit.spades,
        value: kCapotValue,
        isCapot: true,
      );
      final hand = PilottaHand(
        contract: contract,
        initialHands: hands,
        firstLeader: Seat.south,
      );
      autoPlayToCompletion(hand);
      final result = hand.finish();

      expect(result.contractMade, isFalse);
      expect(result.rawTotals[Team.eastWest], 0);
      // Failed contract: the defence gets the bid (kCapotValue) plus the
      // whole pool (trick points + declarations), per the rules spec.
      expect(result.rawTotals[Team.northSouth],
          kCapotValue + 250 + declarationsAndBelote);
    });
  });

  group('PilottaHand declarations + belote', () {
    test('the higher declaration wins the right to score for its team', () {
      // South: hearts A-K-Q-J (sequence of 4, 50 pts) — the table's only
      // other declaration is East's clubs A-K-Q (sequence of 3, 20 pts),
      // so south's team (northSouth) wins the comparison and scores 50.
      final hands = {
        Seat.south: [
          const PlayingCard(Suit.hearts, Rank.ace),
          const PlayingCard(Suit.hearts, Rank.king),
          const PlayingCard(Suit.hearts, Rank.queen),
          const PlayingCard(Suit.hearts, Rank.jack),
          const PlayingCard(Suit.clubs, Rank.jack),
          const PlayingCard(Suit.diamonds, Rank.eight),
          const PlayingCard(Suit.spades, Rank.seven),
          const PlayingCard(Suit.spades, Rank.nine),
        ],
        Seat.west: [
          const PlayingCard(Suit.clubs, Rank.ten),
          const PlayingCard(Suit.clubs, Rank.eight),
          const PlayingCard(Suit.diamonds, Rank.ace),
          const PlayingCard(Suit.diamonds, Rank.seven),
          const PlayingCard(Suit.hearts, Rank.nine),
          const PlayingCard(Suit.spades, Rank.eight),
          const PlayingCard(Suit.spades, Rank.ten),
          const PlayingCard(Suit.spades, Rank.queen),
        ],
        Seat.north: [
          const PlayingCard(Suit.clubs, Rank.nine),
          const PlayingCard(Suit.clubs, Rank.seven),
          const PlayingCard(Suit.diamonds, Rank.king),
          const PlayingCard(Suit.diamonds, Rank.jack),
          const PlayingCard(Suit.hearts, Rank.ten),
          const PlayingCard(Suit.hearts, Rank.eight),
          const PlayingCard(Suit.spades, Rank.jack),
          const PlayingCard(Suit.spades, Rank.king),
        ],
        Seat.east: [
          const PlayingCard(Suit.clubs, Rank.ace),
          const PlayingCard(Suit.clubs, Rank.king),
          const PlayingCard(Suit.clubs, Rank.queen),
          const PlayingCard(Suit.diamonds, Rank.queen),
          const PlayingCard(Suit.diamonds, Rank.ten),
          const PlayingCard(Suit.diamonds, Rank.nine),
          const PlayingCard(Suit.hearts, Rank.seven),
          const PlayingCard(Suit.spades, Rank.ace),
        ],
      };

      final contract = Contract(
        biddingSeat: Seat.south,
        trumpSuit: Suit.spades,
        value: 80,
        isCapot: false,
      );
      final hand = PilottaHand(contract: contract, initialHands: hands, firstLeader: Seat.south);
      autoPlayToCompletion(hand);
      final result = hand.finish();

      expect(result.declarations.winningTeam, Team.northSouth);
      expect(result.declarations.winningTeamPoints, 50);
      expect(result.declarations.beloteSeat, isNull);
    });

    test('belote (trump K+Q in one hand) awards 20 points to that team', () {
      final hands = {
        Seat.south: [
          const PlayingCard(Suit.spades, Rank.king),
          const PlayingCard(Suit.spades, Rank.queen),
          const PlayingCard(Suit.spades, Rank.seven),
          const PlayingCard(Suit.spades, Rank.eight),
          const PlayingCard(Suit.hearts, Rank.seven),
          const PlayingCard(Suit.hearts, Rank.eight),
          const PlayingCard(Suit.diamonds, Rank.seven),
          const PlayingCard(Suit.diamonds, Rank.eight),
        ],
        Seat.west: [
          const PlayingCard(Suit.spades, Rank.nine),
          const PlayingCard(Suit.spades, Rank.ten),
          const PlayingCard(Suit.hearts, Rank.nine),
          const PlayingCard(Suit.hearts, Rank.ten),
          const PlayingCard(Suit.clubs, Rank.seven),
          const PlayingCard(Suit.clubs, Rank.eight),
          const PlayingCard(Suit.clubs, Rank.nine),
          const PlayingCard(Suit.clubs, Rank.ten),
        ],
        Seat.north: [
          const PlayingCard(Suit.spades, Rank.jack),
          const PlayingCard(Suit.spades, Rank.ace),
          const PlayingCard(Suit.hearts, Rank.jack),
          const PlayingCard(Suit.hearts, Rank.queen),
          const PlayingCard(Suit.diamonds, Rank.jack),
          const PlayingCard(Suit.diamonds, Rank.queen),
          const PlayingCard(Suit.clubs, Rank.jack),
          const PlayingCard(Suit.clubs, Rank.queen),
        ],
        Seat.east: [
          const PlayingCard(Suit.hearts, Rank.ace),
          const PlayingCard(Suit.hearts, Rank.king),
          const PlayingCard(Suit.diamonds, Rank.ace),
          const PlayingCard(Suit.diamonds, Rank.king),
          const PlayingCard(Suit.clubs, Rank.ace),
          const PlayingCard(Suit.clubs, Rank.king),
          const PlayingCard(Suit.diamonds, Rank.nine),
          const PlayingCard(Suit.diamonds, Rank.ten),
        ],
      };

      final contract = Contract(
        biddingSeat: Seat.south,
        trumpSuit: Suit.spades,
        value: 80,
        isCapot: false,
      );
      final hand = PilottaHand(contract: contract, initialHands: hands, firstLeader: Seat.south);
      autoPlayToCompletion(hand);
      final result = hand.finish();

      expect(result.declarations.beloteSeat, Seat.south);
    });

    test('belote is exempt from the announce/reveal timing — it counts even '
        'with no announce/reveal calls made at all', () {
      final hands = {
        Seat.south: [
          const PlayingCard(Suit.spades, Rank.king),
          const PlayingCard(Suit.spades, Rank.queen),
          const PlayingCard(Suit.spades, Rank.seven),
          const PlayingCard(Suit.spades, Rank.eight),
          const PlayingCard(Suit.hearts, Rank.seven),
          const PlayingCard(Suit.hearts, Rank.eight),
          const PlayingCard(Suit.diamonds, Rank.seven),
          const PlayingCard(Suit.diamonds, Rank.eight),
        ],
        Seat.west: [
          const PlayingCard(Suit.spades, Rank.nine),
          const PlayingCard(Suit.spades, Rank.ten),
          const PlayingCard(Suit.hearts, Rank.nine),
          const PlayingCard(Suit.hearts, Rank.ten),
          const PlayingCard(Suit.clubs, Rank.seven),
          const PlayingCard(Suit.clubs, Rank.eight),
          const PlayingCard(Suit.clubs, Rank.nine),
          const PlayingCard(Suit.clubs, Rank.ten),
        ],
        Seat.north: [
          const PlayingCard(Suit.spades, Rank.jack),
          const PlayingCard(Suit.spades, Rank.ace),
          const PlayingCard(Suit.hearts, Rank.jack),
          const PlayingCard(Suit.hearts, Rank.queen),
          const PlayingCard(Suit.diamonds, Rank.jack),
          const PlayingCard(Suit.diamonds, Rank.queen),
          const PlayingCard(Suit.clubs, Rank.jack),
          const PlayingCard(Suit.clubs, Rank.queen),
        ],
        Seat.east: [
          const PlayingCard(Suit.hearts, Rank.ace),
          const PlayingCard(Suit.hearts, Rank.king),
          const PlayingCard(Suit.diamonds, Rank.ace),
          const PlayingCard(Suit.diamonds, Rank.king),
          const PlayingCard(Suit.clubs, Rank.ace),
          const PlayingCard(Suit.clubs, Rank.king),
          const PlayingCard(Suit.diamonds, Rank.nine),
          const PlayingCard(Suit.diamonds, Rank.ten),
        ],
      };

      final contract = Contract(
        biddingSeat: Seat.south,
        trumpSuit: Suit.spades,
        value: 80,
        isCapot: false,
      );
      final hand = PilottaHand(contract: contract, initialHands: hands, firstLeader: Seat.south);
      // Nobody announces or reveals anything at all.
      autoPlayToCompletion(hand, autoDeclare: false);
      final result = hand.finish();

      expect(result.declarations.beloteSeat, Seat.south);
    });
  });

  group('Declaration announce/reveal timing', () {
    // South holds hearts A-K-Q-J (a 4-card sequence, 50 pts); nobody else
    // at the table has a competing declaration in these hands, so whether
    // it counts depends purely on whether south announces/reveals in time.
    Map<Seat, List<PlayingCard>> declarableHands() => {
          Seat.south: [
            const PlayingCard(Suit.hearts, Rank.ace),
            const PlayingCard(Suit.hearts, Rank.king),
            const PlayingCard(Suit.hearts, Rank.queen),
            const PlayingCard(Suit.hearts, Rank.jack),
            const PlayingCard(Suit.clubs, Rank.jack),
            const PlayingCard(Suit.diamonds, Rank.eight),
            const PlayingCard(Suit.spades, Rank.seven),
            const PlayingCard(Suit.spades, Rank.nine),
          ],
          Seat.west: [
            const PlayingCard(Suit.clubs, Rank.ten),
            const PlayingCard(Suit.clubs, Rank.eight),
            const PlayingCard(Suit.diamonds, Rank.ace),
            const PlayingCard(Suit.diamonds, Rank.seven),
            const PlayingCard(Suit.hearts, Rank.nine),
            const PlayingCard(Suit.spades, Rank.eight),
            const PlayingCard(Suit.spades, Rank.ten),
            const PlayingCard(Suit.spades, Rank.queen),
          ],
          Seat.north: [
            const PlayingCard(Suit.clubs, Rank.nine),
            const PlayingCard(Suit.clubs, Rank.seven),
            const PlayingCard(Suit.diamonds, Rank.king),
            const PlayingCard(Suit.diamonds, Rank.jack),
            const PlayingCard(Suit.hearts, Rank.ten),
            const PlayingCard(Suit.hearts, Rank.eight),
            const PlayingCard(Suit.spades, Rank.jack),
            const PlayingCard(Suit.spades, Rank.king),
          ],
          Seat.east: [
            const PlayingCard(Suit.clubs, Rank.ace),
            const PlayingCard(Suit.clubs, Rank.king),
            const PlayingCard(Suit.clubs, Rank.queen),
            const PlayingCard(Suit.diamonds, Rank.queen),
            const PlayingCard(Suit.diamonds, Rank.ten),
            const PlayingCard(Suit.diamonds, Rank.nine),
            const PlayingCard(Suit.hearts, Rank.seven),
            const PlayingCard(Suit.spades, Rank.ace),
          ],
        };

    PilottaHand makeHand() => PilottaHand(
          contract: Contract(
            biddingSeat: Seat.south,
            trumpSuit: Suit.spades,
            value: 80,
            isCapot: false,
          ),
          initialHands: declarableHands(),
          firstLeader: Seat.south,
        );

    /// Plays exactly one more trick (4 cards) with the first legal card for
    /// whoever's turn it is, with no announcing/revealing.
    void playOneTrick(PilottaHand hand) {
      final startCount = hand.completedTricks.length;
      while (hand.completedTricks.length == startCount) {
        final seat = hand.currentTrick.seatToPlay;
        hand.playCard(seat, hand.legalPlays(seat).first);
      }
      // Immediately clear the table for the test's sake — the few-second
      // on-table pause is a room/UI-layer concern (PilottaRoom.trickCollectDelay),
      // not something the bare engine enforces.
      if (!hand.isHandComplete) hand.startNextTrick();
    }

    test('can only be announced during trick 1, and only once', () {
      final hand = makeHand();
      expect(hand.canAnnounceDeclaration(Seat.south), isTrue);

      hand.announceDeclaration(Seat.south);
      expect(hand.declarationStateOf(Seat.south), DeclarationAnnounceState.announced);
      // Already announced — can't announce again.
      expect(hand.canAnnounceDeclaration(Seat.south), isFalse);
      expect(() => hand.announceDeclaration(Seat.south), throwsStateError);

      playOneTrick(hand); // trick 1 over
      final freshHand = makeHand();
      playOneTrick(freshHand); // trick 1 over, nobody announced
      expect(freshHand.canAnnounceDeclaration(Seat.south), isFalse);
      expect(() => freshHand.announceDeclaration(Seat.south), throwsStateError);
    });

    test('revealing before playing your trick-2 card makes it count', () {
      final hand = makeHand();
      hand.announceDeclaration(Seat.south);
      playOneTrick(hand); // now in trick 2

      while (hand.currentTrick.seatToPlay != Seat.south) {
        final seat = hand.currentTrick.seatToPlay;
        hand.playCard(seat, hand.legalPlays(seat).first);
      }
      expect(hand.canRevealDeclaration(Seat.south), isTrue);
      hand.revealDeclaration(Seat.south);
      hand.playCard(Seat.south, hand.legalPlays(Seat.south).first);

      while (!hand.isHandComplete) {
        if (hand.currentTrick.isComplete) {
          hand.startNextTrick();
          continue;
        }
        final seat = hand.currentTrick.seatToPlay;
        hand.playCard(seat, hand.legalPlays(seat).first);
      }

      expect(hand.declarationStateOf(Seat.south), DeclarationAnnounceState.revealed);
      final result = hand.finish();
      expect(result.declarations.bestPerSeat[Seat.south]?.pointValue(), 50);
      expect(result.declarations.winningTeam, Team.northSouth);
      expect(result.declarations.winningTeamPoints, 50);
      expect(result.declarations.forfeitedPerSeat, isEmpty);
    });

    test('forgetting to reveal before your trick-2 card forfeits it — it '
        'does not count towards scoring', () {
      final hand = makeHand();
      hand.announceDeclaration(Seat.south);
      playOneTrick(hand); // now in trick 2

      while (hand.currentTrick.seatToPlay != Seat.south) {
        final seat = hand.currentTrick.seatToPlay;
        hand.playCard(seat, hand.legalPlays(seat).first);
      }
      // South plays their trick-2 card WITHOUT revealing first.
      expect(hand.declarationStateOf(Seat.south), DeclarationAnnounceState.announced);
      hand.playCard(Seat.south, hand.legalPlays(Seat.south).first);
      expect(hand.declarationStateOf(Seat.south), DeclarationAnnounceState.forfeited);
      expect(hand.canRevealDeclaration(Seat.south), isFalse);

      while (!hand.isHandComplete) {
        if (hand.currentTrick.isComplete) {
          hand.startNextTrick();
          continue;
        }
        final seat = hand.currentTrick.seatToPlay;
        hand.playCard(seat, hand.legalPlays(seat).first);
      }

      final result = hand.finish();
      expect(result.declarations.bestPerSeat[Seat.south], isNull);
      expect(result.declarations.winningTeam, isNull);
      expect(result.declarations.forfeitedPerSeat[Seat.south]?.pointValue(), 50);
    });

    test('never announcing at all means it never counts, silently', () {
      final hand = makeHand();
      autoPlayToCompletion(hand, autoDeclare: false);
      final result = hand.finish();

      expect(result.declarations.bestPerSeat[Seat.south], isNull);
      expect(result.declarations.winningTeam, isNull);
      expect(result.declarations.forfeitedPerSeat, isEmpty);
    });
  });
}

Random _seededRandom(int seed) => Random(seed);
