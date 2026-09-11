import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

/// Drives a full local match: one human seat plus three bot seats, all on
/// this device. This is a thin [ChangeNotifier] adapter around a
/// [PilottaRoom] — the exact same room/game-flow logic that powers the
/// online server and the Bluetooth host, so local hotseat play can never
/// drift out of sync with how a networked match behaves. No serialization
/// is involved: the UI reads the room's live engine objects directly.
class LocalGameController extends ChangeNotifier {
  final PilottaRoom _room;
  final Seat humanSeat;

  LocalGameController({
    required int targetScore,
    String playerName = 'Εσύ',
    Random? random,
  })  : _room = PilottaRoom(roomCode: 'LOCAL', targetScore: targetScore, random: random),
        humanSeat = Seat.south {
    _room.addListener(notifyListeners);
    _room.join(playerName);
    _room.start();
  }

  RoomPhase get phase => _room.phase;
  Auction? get auction => _room.auction;
  PilottaHand? get hand => _room.hand;
  HandResult? get lastHandResult => _room.lastHandResult;
  MatchScoreboard get scoreboard => _room.scoreboard;
  String? get banner => _room.banner;

  @override
  void dispose() {
    _room.removeListener(notifyListeners);
    _room.dispose();
    super.dispose();
  }

  List<PlayingCard> handOf(Seat seat) => _room.handOf(seat);

  bool get isHumanTurnToBid =>
      phase == RoomPhase.bidding && auction != null && auction!.seatToAct == humanSeat && !auction!.isComplete;

  bool get isHumanTurnToPlay =>
      phase == RoomPhase.playing && hand != null && !hand!.isHandComplete && hand!.currentTrick.seatToPlay == humanSeat;

  List<PlayingCard> get humanLegalPlays =>
      isHumanTurnToPlay ? hand!.legalPlays(humanSeat) : const [];

  /// Called by the UI when the human makes a bidding call.
  void submitBid(AuctionCall call) => _room.handleBid(humanSeat, call);

  /// Called by the UI when the human plays a card.
  void playCard(PlayingCard card) => _room.handlePlayCard(humanSeat, card);

  /// Called by the UI after showing the hand summary, to deal the next hand
  /// (or end the match if the target score has been reached).
  void continueAfterHand() => _room.markReadyForNextHand(humanSeat);
}
