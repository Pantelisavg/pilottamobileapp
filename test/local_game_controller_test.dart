import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/controllers/local_game_controller.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

void main() {
  test(
      'satisfies GameTableData right after dealing — used by the shared '
      'table widget to render bidding, hand, and match state', () {
    fakeAsync((async) {
      final controller = LocalGameController(
        targetScore: 101,
        random: Random(7),
        trickCollectDelay: const Duration(milliseconds: 5),
        persistProgress: false,
      );

      expect(controller.viewerSeat, controller.humanSeat);
      expect(controller.phase, RoomPhase.bidding);
      expect(controller.contract, isNull);
      expect(controller.currentTrick, isNull);
      expect(controller.myHand, hasLength(8));
      expect(controller.handSizeOf(controller.humanSeat), 8);
      expect(controller.handSizeOf(controller.humanSeat.partner), 8);
      expect(controller.isViewerTurnToBid, controller.isHumanTurnToBid);
      expect(controller.isViewerTurnToPlay, isFalse);
      expect(controller.targetScore, 101);
      expect(controller.totals[Team.northSouth], 0);
      expect(controller.totals[Team.eastWest], 0);
      expect(controller.matchWinner, isNull);
      expect(controller.matchHistory, isEmpty);
      expect(controller.lastCompletedTrickPlayed, isNull);
      expect(controller.declarationStateOf(controller.humanSeat),
          DeclarationAnnounceState.none);
      expect(
          controller.revealedDeclarationsLabelOf(controller.humanSeat), isNull);

      controller.dispose();
      async.elapse(const Duration(seconds: 1));
    });
  });

  test(
      'a full match can be played to completion with the human always passing '
      'and playing its first legal card', () {
    fakeAsync((async) {
      final controller = LocalGameController(
        targetScore: 101,
        random: Random(7),
        trickCollectDelay: const Duration(milliseconds: 5),
        persistProgress: false,
      );

      var guard = 0;
      while (controller.phase != RoomPhase.matchOver && guard++ < 5000) {
        if (controller.isHumanTurnToBid) {
          controller.submitBid(PassCall(controller.humanSeat));
        } else if (controller.isHumanTurnToPlay) {
          controller.playCard(controller.humanLegalPlays.first);
        } else if (controller.phase == RoomPhase.handSummary) {
          controller.continueAfterHand();
        } else {
          async.elapse(const Duration(milliseconds: 100));
        }
      }

      expect(controller.phase, RoomPhase.matchOver);
      expect(controller.scoreboard.winner, isNotNull);
      expect(controller.scoreboard.history, isNotEmpty);

      final totals = controller.scoreboard.totals;
      expect(
        totals[Team.northSouth]! >= 101 || totals[Team.eastWest]! >= 101,
        isTrue,
      );

      controller.dispose();
      async.elapse(const Duration(seconds: 1));
    });
  });

  test('every hand in a completed match scores a legal trick-point split', () {
    fakeAsync((async) {
      final controller = LocalGameController(
        targetScore: 101,
        random: Random(3),
        trickCollectDelay: const Duration(milliseconds: 5),
        persistProgress: false,
      );

      var guard = 0;
      while (controller.phase != RoomPhase.matchOver && guard++ < 5000) {
        if (controller.isHumanTurnToBid) {
          controller.submitBid(PassCall(controller.humanSeat));
        } else if (controller.isHumanTurnToPlay) {
          controller.playCard(controller.humanLegalPlays.first);
        } else if (controller.phase == RoomPhase.handSummary) {
          controller.continueAfterHand();
        } else {
          async.elapse(const Duration(milliseconds: 100));
        }
      }

      for (final result in controller.scoreboard.history) {
        final total = result.trickPoints[Team.northSouth]! +
            result.trickPoints[Team.eastWest]!;
        expect(total, result.allTricksTeam == null ? 162 : 250);
      }

      controller.dispose();
      async.elapse(const Duration(seconds: 1));
    });
  });
}
