import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

import '../persistence/local_game_save.dart';

/// Drives a full local match: one human seat plus three bot seats, all on
/// this device. This is a thin [ChangeNotifier] adapter around a
/// [PilottaRoom] — the exact same room/game-flow logic that powers the
/// online server and the Bluetooth host, so local hotseat play can never
/// drift out of sync with how a networked match behaves. No serialization
/// is involved: the UI reads the room's live engine objects directly.
class LocalGameController extends ChangeNotifier {
  final PilottaRoom _room;
  final Seat humanSeat;

  /// Whether every change auto-saves a "continue later" slot (see
  /// [LocalGameSave]), cleared once the match ends. On by default; tests
  /// that don't want to touch real platform storage pass false.
  final bool _persistProgress;

  LocalGameController({
    required int targetScore,
    String playerName = 'Εσύ',
    Random? random,
    bool mustOvertrumpAllSuits = false,
    Duration trickCollectDelay = const Duration(milliseconds: 1200),
    bool persistProgress = true,
  })  : _room = PilottaRoom(
          roomCode: 'LOCAL',
          targetScore: targetScore,
          random: random,
          mustOvertrumpAllSuits: mustOvertrumpAllSuits,
          trickCollectDelay: trickCollectDelay,
        ),
        humanSeat = Seat.south,
        _persistProgress = persistProgress {
    _room.addListener(_onRoomChanged);
    _room.join(playerName);
    _room.start();
  }

  /// Rebuilds a controller from a previously-saved room (see
  /// [LocalGameSave.load]) — picks up exactly where the match left off.
  LocalGameController.resumed(Map<String, dynamic> savedJson,
      {bool persistProgress = true})
      : _room = PilottaRoom.restore(savedJson),
        humanSeat = Seat.south,
        _persistProgress = persistProgress {
    _room.addListener(_onRoomChanged);
  }

  void _onRoomChanged() {
    notifyListeners();
    if (!_persistProgress) return;
    if (_room.phase == RoomPhase.matchOver) {
      LocalGameSave.clear();
    } else {
      LocalGameSave.save(_room);
    }
  }

  RoomPhase get phase => _room.phase;
  Auction? get auction => _room.auction;
  PilottaHand? get hand => _room.hand;
  HandResult? get lastHandResult => _room.lastHandResult;
  MatchScoreboard get scoreboard => _room.scoreboard;
  String? get banner => _room.banner;

  @override
  void dispose() {
    _room.removeListener(_onRoomChanged);
    _room.dispose();
    super.dispose();
  }

  List<PlayingCard> handOf(Seat seat) => _room.handOf(seat);

  bool isBotControlled(Seat seat) => _room.isBotControlled(seat);

  bool get isHumanTurnToBid =>
      phase == RoomPhase.bidding &&
      auction != null &&
      auction!.seatToAct == humanSeat &&
      !auction!.isComplete;

  bool get isHumanTurnToPlay =>
      phase == RoomPhase.playing &&
      hand != null &&
      !hand!.isHandComplete &&
      !hand!.currentTrick.isComplete &&
      hand!.currentTrick.seatToPlay == humanSeat;

  List<PlayingCard> get humanLegalPlays =>
      isHumanTurnToPlay ? hand!.legalPlays(humanSeat) : const [];

  /// Called by the UI when the human makes a bidding call.
  void submitBid(AuctionCall call) => _room.handleBid(humanSeat, call);

  /// Called by the UI when the human plays a card.
  void playCard(PlayingCard card) => _room.handlePlayCard(humanSeat, card);

  /// The human's own best declaration this hand, if any — safe to show
  /// them immediately regardless of whether they've announced it yet.
  Declaration? get myBestDeclaration => hand?.bestDeclarationOf(humanSeat);

  bool get canAnnounceDeclaration =>
      hand?.canAnnounceDeclaration(humanSeat) ?? false;
  bool get canRevealDeclaration =>
      hand?.canRevealDeclaration(humanSeat) ?? false;

  /// Called by the UI when the human announces their declaration (only
  /// valid during trick 1 — see [canAnnounceDeclaration]).
  void announceDeclaration() => _room.handleAnnounceDeclaration(humanSeat);

  /// Called by the UI when the human reveals a previously-announced
  /// declaration (must happen before their trick-2 card — see
  /// [canRevealDeclaration]).
  void revealDeclaration() => _room.handleRevealDeclaration(humanSeat);

  /// The room's shared chat/event log — see [PilottaRoom.chatLog]. In local
  /// hotseat play this is mostly declaration/Pilotta announcements, since
  /// there's nobody else at the table to actually type to.
  List<ChatEntry> get chatLog => _room.chatLog;

  /// Posts a free-text chat message as the human seat.
  void sendChat(String text) => _room.sendChat(humanSeat, text);

  /// Called by the UI after showing the hand summary, to deal the next hand
  /// (or end the match if the target score has been reached).
  void continueAfterHand() => _room.markReadyForNextHand(humanSeat);
}
