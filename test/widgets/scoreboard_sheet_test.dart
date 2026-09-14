import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/widgets/scoreboard_sheet.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

HandResult _playHandToCompletion({required Seat biddingSeat}) {
  final hands = dealHands(Random(4));
  final contract = Contract(
    biddingSeat: biddingSeat,
    trumpSuit: Suit.spades,
    value: 80,
    isCapot: false,
  );
  final hand = PilottaHand(
    contract: contract,
    initialHands: hands,
    firstLeader: biddingSeat,
  );
  while (!hand.isHandComplete) {
    if (hand.currentTrick.isComplete) {
      hand.startNextTrick();
      continue;
    }
    final seat = hand.currentTrick.seatToPlay;
    hand.playCard(seat, hand.legalPlays(seat).first);
  }
  return hand.finish();
}

void main() {
  group('buildScoreRows', () {
    test(
        'orients rounded/trick/declaration points to the viewer\'s own team, '
        'and both team\'s trick points always sum to the hand total', () {
      final history = [
        _playHandToCompletion(biddingSeat: Seat.south),
        _playHandToCompletion(biddingSeat: Seat.west),
      ];

      final rows = buildScoreRows(history, Seat.south);
      expect(rows, hasLength(2));

      for (var i = 0; i < history.length; i++) {
        final r = rows[i];
        final result = history[i];
        expect(r.index, i + 1);
        expect(r.trumpSuit, result.contract.trumpSuit);
        expect(r.contractMade, result.contractMade);

        final expectedMine = result.trickPoints[Team.northSouth]! ~/ 10;
        final expectedTheirs = result.trickPoints[Team.eastWest]! ~/ 10;
        expect(r.trickPointsMine, expectedMine);
        expect(r.trickPointsTheirs, expectedTheirs);

        expect(r.roundedMine, result.rounded.northSouth);
        expect(r.roundedTheirs, result.rounded.eastWest);
      }

      // Seat.west is on the opposing team from the viewer (south) — the
      // mine/theirs orientation must flip accordingly for that row.
      final viewerAsWest = buildScoreRows(history, Seat.west);
      expect(viewerAsWest[0].roundedMine, rows[0].roundedTheirs);
      expect(viewerAsWest[0].roundedTheirs, rows[0].roundedMine);
    });
  });
}
