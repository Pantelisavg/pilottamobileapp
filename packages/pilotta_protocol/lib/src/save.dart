/// Full, private-state (de)serialization for resuming an in-progress local
/// match later — as opposed to [codec.dart]'s network-snapshot helpers,
/// which deliberately hide everything but the viewer's own hand. A local
/// save is for the same device/player, so nothing needs hiding.
library;

import 'package:pilotta_engine/pilotta_engine.dart';

import 'codec.dart';

/// Everything needed to reconstruct an in-progress [PilottaHand] exactly:
/// the original 8-card deal, every card played so far in chronological
/// order (derived from [PilottaHand.completedTricks] + the current trick,
/// so no separate play-log needs to be tracked while the hand is live),
/// and each seat's declaration state.
Map<String, dynamic> handToSaveJson(PilottaHand hand) {
  final plays = [
    for (final trick in hand.completedTricks) ...trick.played,
    // Once the hand is fully complete, currentTrick still points at the
    // very last completed trick (nothing ever replaces it — see
    // PilottaHand.isAwaitingNextTrick) rather than a fresh one, so
    // counting it here too would double up its 4 plays.
    if (!hand.isHandComplete) ...hand.currentTrick.played,
  ];
  return {
    'contract': contractToJson(hand.contract),
    'originalHands': {
      for (final seat in Seat.values)
        seat.name: cardsToJson(hand.originalHandOf(seat)),
    },
    'firstLeader': (hand.completedTricks.isNotEmpty
            ? hand.completedTricks.first.leader
            : hand.currentTrick.leader)
        .name,
    'plays': [
      for (final p in plays) {'seat': p.seat.name, 'card': cardToJson(p.card)},
    ],
    'declarationStates': {
      for (final seat in Seat.values)
        seat.name: hand.declarationStateOf(seat).name,
    },
  };
}

/// Rebuilds a [PilottaHand] from [handToSaveJson] by replaying every play
/// through the real [PilottaHand.playCard]/[PilottaHand.startNextTrick]
/// methods — this reconstructs completed tricks, points won, Belote
/// tracking etc. exactly as if the hand had actually been played this far,
/// rather than trying to duplicate that bookkeeping here.
PilottaHand handFromSaveJson(Map<String, dynamic> json,
    {required bool mustOvertrumpAllSuits}) {
  final contract = contractFromJson(json['contract'] as Map<String, dynamic>);
  final originalHands = {
    for (final e in (json['originalHands'] as Map<String, dynamic>).entries)
      Seat.values.byName(e.key): cardsFromJson(e.value as List<dynamic>),
  };
  final hand = PilottaHand(
    contract: contract,
    initialHands: originalHands,
    firstLeader: Seat.values.byName(json['firstLeader'] as String),
    mustOvertrumpAllSuits: mustOvertrumpAllSuits,
  );

  for (final playJson
      in (json['plays'] as List<dynamic>).cast<Map<String, dynamic>>()) {
    final seat = Seat.values.byName(playJson['seat'] as String);
    final card = cardFromJson(playJson['card'] as Map<String, dynamic>);
    hand.playCard(seat, card);
    if (hand.currentTrick.isComplete && !hand.isHandComplete) {
      hand.startNextTrick();
    }
  }

  hand.restoreDeclarationStates({
    for (final e in (json['declarationStates'] as Map<String, dynamic>).entries)
      Seat.values.byName(e.key):
          DeclarationAnnounceState.values.byName(e.value as String),
  });

  return hand;
}
