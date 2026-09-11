import 'dart:async';
import 'dart:math';

import 'package:pilotta_engine/pilotta_engine.dart';

import 'codec.dart';
import 'messages.dart';

/// The single, transport-agnostic authority for one 4-seat Pilotta match.
///
/// This is the one place the actual game flow (dealing, bidding, playing,
/// scoring, advancing to the next hand) is implemented for anything beyond
/// a single Dart process talking directly to pilotta_engine. It is used by:
/// - the online WebSocket server (one [PilottaRoom] per room, snapshots
///   serialized to JSON and sent to each socket),
/// - the Bluetooth/local-network host device (same class, snapshots sent as
///   bytes over Nearby Connections instead of a socket),
/// - `LocalGameController` in the app, wrapping a [PilottaRoom] with exactly
///   one human seat and reading its state directly with no serialization at
///   all, so local hotseat play exercises the identical game-flow code as
///   every networked mode.
///
/// A seat is "bot controlled" whenever nobody has claimed it, or whoever
/// claimed it is currently disconnected — so a human dropping mid-match
/// doesn't stall the table, and reconnecting hands control straight back.
class PilottaRoom {
  final String roomCode;
  final int targetScore;
  final Duration botBidDelay;
  final Duration botPlayDelay;

  final Random _random;
  late final SimpleBot _bot;
  late final MatchScoreboard scoreboard;
  late Seat _dealer;

  RoomPhase phase = RoomPhase.lobby;
  final Map<Seat, SeatInfo> seats = {
    for (final s in Seat.values) s: const SeatInfo(isBot: false, connected: false),
  };

  Auction? auction;
  Map<Seat, List<PlayingCard>>? _originalHands;
  PilottaHand? hand;
  HandResult? lastHandResult;
  String? banner;
  final Set<Seat> readyForNextHand = {};

  Timer? _pendingBotMove;
  final List<void Function()> _listeners = [];
  bool _disposed = false;

  PilottaRoom({
    required this.roomCode,
    required this.targetScore,
    Random? random,
    this.botBidDelay = const Duration(milliseconds: 500),
    this.botPlayDelay = const Duration(milliseconds: 600),
  }) : _random = random ?? Random() {
    _bot = SimpleBot(_random);
    scoreboard = MatchScoreboard(targetScore: targetScore);
    _dealer = Seat.values[_random.nextInt(4)];
  }

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  void _notify() {
    if (_disposed) return;
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  void dispose() {
    _disposed = true;
    _pendingBotMove?.cancel();
    _listeners.clear();
  }

  // ---------------------------------------------------------------- lobby

  /// Claims a seat for a human player: [playerName] reclaims their own
  /// still-reserved seat if they previously disconnected from this exact
  /// room (a simple reconnect mechanism — rejoin with the same name to get
  /// your cards back), otherwise the next open seat is assigned. Returns
  /// null if every seat is already claimed by someone else.
  Seat? join(String playerName) {
    for (final seat in Seat.values) {
      final info = seats[seat]!;
      if (!info.isBot && info.playerName == playerName && !info.connected) {
        setConnected(seat, true);
        return seat;
      }
    }
    for (final seat in Seat.values) {
      final info = seats[seat]!;
      if (!info.isBot && info.playerName == null) {
        seats[seat] = SeatInfo(playerName: playerName, isBot: false, connected: true);
        _notify();
        return seat;
      }
    }
    return null;
  }

  void setConnected(Seat seat, bool connected) {
    final info = seats[seat]!;
    if (info.playerName == null) return;
    seats[seat] = SeatInfo(playerName: info.playerName, isBot: false, connected: connected);
    // Disconnecting hands control to the bot immediately if it was this
    // seat's turn; reconnecting is a no-op here (isBotControlled is now
    // false again, so these simply won't schedule anything).
    _maybeRunBotBidding();
    _maybeRunBotPlay();
    _notify();
  }

  /// A human giving up their seat for good (as opposed to a transient
  /// disconnect). Only meaningful in the lobby — mid-match this just
  /// disconnects them, since the seat must keep existing for scoring.
  void leave(Seat seat) {
    if (phase == RoomPhase.lobby) {
      seats[seat] = const SeatInfo(isBot: false, connected: false);
    } else {
      setConnected(seat, false);
    }
    _notify();
  }

  bool isBotControlled(Seat seat) {
    final info = seats[seat]!;
    return info.isBot || !info.connected;
  }

  bool get canStart =>
      phase == RoomPhase.lobby && seats.values.any((s) => s.playerName != null);

  /// Fills every unclaimed seat with a bot and deals the first hand.
  void start() {
    if (!canStart) return;
    for (final seat in Seat.values) {
      if (seats[seat]!.playerName == null) {
        seats[seat] = const SeatInfo(isBot: true, connected: true);
      }
    }
    _startHand();
  }

  // --------------------------------------------------------------- dealing

  void _startHand() {
    phase = RoomPhase.bidding;
    _originalHands = dealHands(_random);
    hand = null;
    lastHandResult = null;
    readyForNextHand.clear();
    banner = null;
    auction = Auction(_dealer.next);
    _notify();
    _maybeRunBotBidding();
  }

  // --------------------------------------------------------------- bidding

  void _maybeRunBotBidding() {
    final a = auction;
    if (a == null || phase != RoomPhase.bidding) return;
    if (a.isComplete) {
      _settleAuction();
      return;
    }
    if (!isBotControlled(a.seatToAct)) return;

    _pendingBotMove?.cancel();
    _pendingBotMove = Timer(botBidDelay, () {
      if (_disposed || auction != a || a.isComplete) return;
      final call = _bot.decideBid(a, a.seatToAct, _originalHands![a.seatToAct]!);
      a.apply(call);
      _notify();
      _maybeRunBotBidding();
    });
  }

  /// Returns an error message if [call] is rejected, or null on success.
  String? handleBid(Seat seat, AuctionCall call) {
    if (phase != RoomPhase.bidding || auction == null) return 'Δεν τρέχει δημοπρασία.';
    if (isBotControlled(seat)) return 'Η θέση ελέγχεται από bot.';
    if (auction!.seatToAct != seat) return 'Δεν είναι η σειρά σου.';
    if (call.seat != seat) return 'Μη έγκυρη δήλωση.';
    try {
      auction!.apply(call);
    } on IllegalCallException catch (e) {
      return e.message;
    }
    _notify();
    _maybeRunBotBidding();
    return null;
  }

  void _settleAuction() {
    final result = auction!.result();
    if (result.isRedeal) {
      banner = 'Όλοι πέρασαν — νέα μοιρασιά.';
      _dealer = _dealer.next;
      _notify();
      _pendingBotMove?.cancel();
      _pendingBotMove = Timer(const Duration(milliseconds: 900), _startHand);
      return;
    }

    final contract = result.contract!;
    hand = PilottaHand(
      contract: contract,
      initialHands: _originalHands!,
      firstLeader: _dealer.next,
    );
    phase = RoomPhase.playing;

    final decls = <String>[];
    for (final seat in Seat.values) {
      final d = bestDeclaration(seat, _originalHands![seat]!, contract.trumpSuit);
      if (d != null) {
        decls.add('${_seatLabel(seat)}: ${_declLabel(d)} (${d.pointValue()} π.)');
      }
    }
    banner = decls.isEmpty ? null : decls.join('  •  ');

    _notify();
    _maybeRunBotPlay();
  }

  // ---------------------------------------------------------------- playing

  void _maybeRunBotPlay() {
    final h = hand;
    if (h == null || phase != RoomPhase.playing) return;
    if (h.isHandComplete) {
      _finishHand();
      return;
    }
    final toAct = h.currentTrick.seatToPlay;
    if (!isBotControlled(toAct)) return;

    _pendingBotMove?.cancel();
    _pendingBotMove = Timer(botPlayDelay, () {
      if (_disposed || hand != h || h.isHandComplete) return;
      final card = _bot.decidePlay(h.currentTrick, h.handOf(toAct), h.contract.trumpSuit);
      h.playCard(toAct, card);
      _notify();
      _maybeRunBotPlay();
    });
  }

  /// Returns an error message if the play is rejected, or null on success.
  String? handlePlayCard(Seat seat, PlayingCard card) {
    if (phase != RoomPhase.playing || hand == null) return 'Δεν παίζεται φύλλο τώρα.';
    if (isBotControlled(seat)) return 'Η θέση ελέγχεται από bot.';
    if (hand!.currentTrick.seatToPlay != seat) return 'Δεν είναι η σειρά σου.';
    if (!hand!.legalPlays(seat).contains(card)) return 'Μη έγκυρο φύλλο.';
    hand!.playCard(seat, card);
    _notify();
    _maybeRunBotPlay();
    return null;
  }

  void _finishHand() {
    final result = hand!.finish(_originalHands!);
    lastHandResult = result;
    scoreboard.addHand(result);
    phase = RoomPhase.handSummary;
    banner = null;
    readyForNextHand.clear();
    for (final seat in Seat.values) {
      if (isBotControlled(seat)) readyForNextHand.add(seat);
    }
    _notify();
    _maybeAdvanceAfterHandSummary();
  }

  /// A human acknowledging the hand summary. Once every seat is ready
  /// (bot-controlled seats are auto-ready), the next hand deals — or, if
  /// nobody is left to ready up because every seat is bot-controlled, this
  /// already happened automatically when the hand finished.
  void markReadyForNextHand(Seat seat) {
    if (phase != RoomPhase.handSummary) return;
    readyForNextHand.add(seat);
    _notify();
    _maybeAdvanceAfterHandSummary();
  }

  void _maybeAdvanceAfterHandSummary() {
    if (phase != RoomPhase.handSummary) return;
    final allReady = Seat.values.every(readyForNextHand.contains);
    if (!allReady) return;

    if (scoreboard.isMatchOver) {
      phase = RoomPhase.matchOver;
      _notify();
      return;
    }
    _dealer = _dealer.next;
    _startHand();
  }

  /// The cards [seat] currently holds: their post-auction hand-in-progress
  /// while a hand is being played (or just finished), or their freshly
  /// dealt 8 cards during the auction. Safe to call for local, same-process
  /// UIs that want to render a seat's hand directly without going through
  /// JSON — used internally by [buildSnapshotFor] too.
  List<PlayingCard> handOf(Seat seat) {
    final h = hand;
    if (phase == RoomPhase.playing || phase == RoomPhase.handSummary) {
      return h?.handOf(seat) ?? const <PlayingCard>[];
    }
    return _originalHands?[seat] ?? const <PlayingCard>[];
  }

  // -------------------------------------------------------------- snapshot

  RoomSnapshotMessage buildSnapshotFor(Seat viewer) {
    final h = hand;
    final handSizes = <Seat, int>{
      for (final seat in Seat.values) seat: handOf(seat).length,
    };

    return RoomSnapshotMessage(
      roomCode: roomCode,
      yourSeat: viewer,
      phase: phase,
      seats: Map.of(seats),
      targetScore: targetScore,
      totals: {
        'northSouth': scoreboard.totals[Team.northSouth]!,
        'eastWest': scoreboard.totals[Team.eastWest]!,
      },
      dealer: phase == RoomPhase.lobby ? null : _dealer,
      auctionCalls: auction?.calls.map(auctionCallToJson).toList(),
      seatToAct: switch (phase) {
        RoomPhase.bidding => auction?.seatToAct,
        RoomPhase.playing => h?.currentTrick.seatToPlay,
        _ => null,
      },
      contract: h != null ? contractToJson(h.contract) : null,
      yourHand: handOf(viewer),
      handSizes: handSizes,
      currentTrick: h?.currentTrick.played
          .map((e) => {'seat': e.seat.name, 'card': cardToJson(e.card)})
          .toList(),
      trickLeader: h?.currentTrick.leader,
      banner: banner,
      lastHandResult: lastHandResult != null ? handResultToJson(lastHandResult!) : null,
      readyForNextHand: Set.of(readyForNextHand),
      winnerTeam: scoreboard.winner?.name,
    );
  }

  static String _seatLabel(Seat seat) {
    switch (seat) {
      case Seat.south:
        return 'Νότος';
      case Seat.west:
        return 'Δύση';
      case Seat.north:
        return 'Βορράς';
      case Seat.east:
        return 'Ανατολή';
    }
  }

  static String _declLabel(Declaration d) {
    if (d.kind == DeclarationKind.carre) {
      return 'Καρέ ${d.carreRank.short}';
    }
    return 'Σκάλα ${d.length}';
  }
}
