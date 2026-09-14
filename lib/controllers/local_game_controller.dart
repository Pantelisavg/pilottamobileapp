import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

import '../persistence/local_game_save.dart';
import '../widgets/declaration_label.dart';
import '../widgets/table/game_table_data.dart';

/// Drives a full local match: one human seat plus three bot seats, all on
/// this device. This is a thin [ChangeNotifier] adapter around a
/// [PilottaRoom] — the exact same room/game-flow logic that powers the
/// online server and the Bluetooth host, so local hotseat play can never
/// drift out of sync with how a networked match behaves. No serialization
/// is involved: the UI reads the room's live engine objects directly.
class LocalGameController extends ChangeNotifier implements GameTableData {
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

  @override
  RoomPhase get phase => _room.phase;
  @override
  Auction? get auction => _room.auction;
  PilottaHand? get hand => _room.hand;
  @override
  HandResult? get lastHandResult => _room.lastHandResult;
  MatchScoreboard get scoreboard => _room.scoreboard;
  @override
  String? get banner => _room.banner;

  @override
  void dispose() {
    _room.removeListener(_onRoomChanged);
    _room.dispose();
    super.dispose();
  }

  List<PlayingCard> handOf(Seat seat) => _room.handOf(seat);

  @override
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
  @override
  void submitBid(AuctionCall call) => _room.handleBid(humanSeat, call);

  /// Called by the UI when the human plays a card.
  @override
  void playCard(PlayingCard card) => _room.handlePlayCard(humanSeat, card);

  /// The human's own best declaration this hand, if any — safe to show
  /// them immediately regardless of whether they've announced it yet.
  Declaration? get myBestDeclaration => hand?.bestDeclarationOf(humanSeat);

  @override
  bool get canAnnounceDeclaration =>
      hand?.canAnnounceDeclaration(humanSeat) ?? false;
  @override
  bool get canRevealDeclaration =>
      hand?.canRevealDeclaration(humanSeat) ?? false;

  /// Called by the UI when the human announces their declaration (only
  /// valid during trick 1 — see [canAnnounceDeclaration]).
  @override
  void announceDeclaration() => _room.handleAnnounceDeclaration(humanSeat);

  /// Called by the UI when the human reveals a previously-announced
  /// declaration (must happen before their trick-2 card — see
  /// [canRevealDeclaration]).
  @override
  void revealDeclaration() => _room.handleRevealDeclaration(humanSeat);

  /// The room's shared chat/event log — see [PilottaRoom.chatLog]. In local
  /// hotseat play this is mostly declaration/Pilotta announcements, since
  /// there's nobody else at the table to actually type to.
  @override
  List<ChatEntry> get chatLog => _room.chatLog;

  /// Posts a free-text chat message as the human seat.
  @override
  void sendChat(String text) => _room.sendChat(humanSeat, text);

  /// Called by the UI after showing the hand summary, to deal the next hand
  /// (or end the match if the target score has been reached).
  @override
  void continueAfterHand() => _room.markReadyForNextHand(humanSeat);

  @override
  bool get viewerIsReadyForNextHand =>
      _room.readyForNextHand.contains(humanSeat);

  // ------------------------------------------------------- GameTableData
  // Additive adapter members satisfying the shared table-widget interface
  // (see game_table_data.dart) — every member above stays exactly as it
  // was for existing callers; these are new names for the same data.

  @override
  Seat get viewerSeat => humanSeat;

  @override
  Contract? get contract => hand?.contract;

  @override
  Trick? get currentTrick => hand?.currentTrick;

  @override
  List<PlayingCard> get myHand => handOf(humanSeat);

  @override
  int handSizeOf(Seat seat) => handOf(seat).length;

  @override
  bool get isViewerTurnToBid => isHumanTurnToBid;

  @override
  Seat? get seatToAct {
    if (phase == RoomPhase.bidding) return auction?.seatToAct;
    if (phase == RoomPhase.playing) {
      final trick = currentTrick;
      if (trick == null || trick.isComplete) return null;
      return trick.seatToPlay;
    }
    return null;
  }

  @override
  bool get isViewerTurnToPlay => isHumanTurnToPlay;

  @override
  List<PlayingCard> get viewerLegalPlays => humanLegalPlays;

  @override
  List<({Seat seat, PlayingCard card})>? get lastCompletedTrickPlayed {
    final tricks = hand?.completedTricks;
    if (tricks == null || tricks.isEmpty) return null;
    return tricks.last.played;
  }

  @override
  Seat? get lastCompletedTrickWinner {
    final tricks = hand?.completedTricks;
    if (tricks == null || tricks.isEmpty) return null;
    return tricks.last.winner;
  }

  @override
  String? get myBestDeclarationLabel {
    final d = myBestDeclaration;
    return d == null ? null : declarationPointsLabel(d);
  }

  @override
  DeclarationAnnounceState declarationStateOf(Seat seat) =>
      hand?.declarationStateOf(seat) ?? DeclarationAnnounceState.none;

  @override
  String? revealedDeclarationsLabelOf(Seat seat) {
    if (declarationStateOf(seat) != DeclarationAnnounceState.revealed) {
      return null;
    }
    return declarationsPointsLabel(hand!.allDeclarationsOf(seat));
  }

  @override
  List<HandResult> get matchHistory => scoreboard.history;

  @override
  int get targetScore => scoreboard.targetScore;

  @override
  Map<Team, int> get totals => scoreboard.totals;

  @override
  Team? get matchWinner => scoreboard.winner;
}
