import 'dart:async';

import 'package:pilotta_protocol/pilotta_protocol.dart';

import 'game_table_data.dart';

/// Auto-plays the viewer's forced cards one trick after another, for the
/// common endgame case where every remaining card is the only legal play
/// anyway — no decision is actually being skipped, just the tapping.
///
/// Stops as soon as either the hand ends (phase leaves [RoomPhase.playing])
/// or the viewer once again has more than one legal card, handing control
/// back for a real decision.
Future<void> throwAll(GameTableData controller) async {
  while (controller.phase == RoomPhase.playing &&
      controller.isViewerTurnToPlay &&
      controller.viewerLegalPlays.length == 1) {
    controller.playCard(controller.viewerLegalPlays.first);

    // Bot plays and trick-collection each fire their own notifyListeners
    // in between one forced play and the next — wait through however many
    // of those it takes until either it's the viewer's turn again or the
    // hand has moved on, rather than reacting to just the first one.
    while (controller.phase == RoomPhase.playing &&
        !controller.isViewerTurnToPlay) {
      await _nextChange(controller);
    }
  }
}

Future<void> _nextChange(GameTableData controller) {
  final completer = Completer<void>();
  void listener() {
    controller.removeListener(listener);
    if (!completer.isCompleted) completer.complete();
  }

  controller.addListener(listener);
  return completer.future;
}
