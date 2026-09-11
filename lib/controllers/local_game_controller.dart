import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

enum GamePhase { dealing, bidding, playing, handSummary, matchOver }

/// Drives a full local match: one human seat plus three [SimpleBot] seats,
/// all on this device. Owns the auction, the current [PilottaHand], and the
/// running [MatchScoreboard], and exposes just enough state + actions for a
/// UI to render the table and let the human make bidding/play decisions.
class LocalGameController extends ChangeNotifier {
  final Seat humanSeat;
  final Random _random;
  final SimpleBot _bot;

  LocalGameController({
    required int targetScore,
    this.humanSeat = Seat.south,
    Random? random,
  })  : _random = random ?? Random(),
        _bot = SimpleBot(random ?? Random()),
        scoreboard = MatchScoreboard(targetScore: targetScore) {
    _dealer = Seat.values[_random.nextInt(4)];
    _startHand();
  }

  final MatchScoreboard scoreboard;
  late Seat _dealer;
  GamePhase phase = GamePhase.dealing;
  Timer? _pendingAction;
  bool _disposed = false;

  Auction? auction;
  Map<Seat, List<PlayingCard>>? _originalHands;
  PilottaHand? hand;
  HandResult? lastHandResult;

  /// A short-lived message for the UI to surface (declarations, belote,
  /// contract result) as a snackbar/banner.
  String? banner;

  Map<Seat, List<PlayingCard>> get hands => _originalHands ?? const {};

  @override
  void dispose() {
    _disposed = true;
    _pendingAction?.cancel();
    super.dispose();
  }

  void _schedule(Duration delay, VoidCallback action) {
    _pendingAction?.cancel();
    _pendingAction = Timer(delay, () {
      if (_disposed) return;
      action();
    });
  }

  List<PlayingCard> handOf(Seat seat) =>
      phase == GamePhase.playing ? hand!.handOf(seat) : (hands[seat] ?? const []);

  bool get isHumanTurnToBid =>
      phase == GamePhase.bidding && auction != null && auction!.seatToAct == humanSeat && !auction!.isComplete;

  bool get isHumanTurnToPlay =>
      phase == GamePhase.playing && hand != null && !hand!.isHandComplete && hand!.currentTrick.seatToPlay == humanSeat;

  List<PlayingCard> get humanLegalPlays => isHumanTurnToPlay ? hand!.legalPlays(humanSeat) : const [];

  void _startHand() {
    phase = GamePhase.dealing;
    _originalHands = dealHands(_random);
    hand = null;
    lastHandResult = null;
    auction = Auction(_dealer.next);
    phase = GamePhase.bidding;
    banner = null;
    notifyListeners();
    _maybeRunBotBidding();
  }

  void _maybeRunBotBidding() {
    final a = auction!;
    if (a.isComplete) {
      _settleAuction();
      return;
    }
    if (a.seatToAct == humanSeat) return; // wait for human input

    _schedule(const Duration(milliseconds: 500), () {
      if (auction != a || a.isComplete) return;
      final call = _bot.decideBid(a, a.seatToAct, _originalHands![a.seatToAct]!);
      a.apply(call);
      notifyListeners();
      _maybeRunBotBidding();
    });
  }

  /// Called by the UI when the human makes a bidding call.
  void submitBid(AuctionCall call) {
    if (!isHumanTurnToBid) return;
    auction!.apply(call);
    notifyListeners();
    _maybeRunBotBidding();
  }

  void _settleAuction() {
    final result = auction!.result();
    if (result.isRedeal) {
      banner = 'Όλοι πέρασαν — νέα μοιρασιά.';
      _dealer = _dealer.next;
      notifyListeners();
      _schedule(const Duration(milliseconds: 900), _startHand);
      return;
    }

    final contract = result.contract!;
    hand = PilottaHand(
      contract: contract,
      initialHands: _originalHands!,
      firstLeader: _dealer.next,
    );
    phase = GamePhase.playing;

    final decls = <String>[];
    for (final seat in Seat.values) {
      final d = bestDeclaration(seat, _originalHands![seat]!, contract.trumpSuit);
      if (d != null) {
        decls.add('${_seatLabel(seat)}: ${_declLabel(d)} (${d.pointValue()} π.)');
      }
    }
    banner = decls.isEmpty ? null : decls.join('  •  ');

    notifyListeners();
    _maybeRunBotPlay();
  }

  void _maybeRunBotPlay() {
    final h = hand!;
    if (h.isHandComplete) {
      _finishHand();
      return;
    }
    final toAct = h.currentTrick.seatToPlay;
    if (toAct == humanSeat) return;

    _schedule(const Duration(milliseconds: 600), () {
      if (hand != h || h.isHandComplete) return;
      final card = _bot.decidePlay(h.currentTrick, h.handOf(toAct), h.contract.trumpSuit);
      h.playCard(toAct, card);
      notifyListeners();
      _maybeRunBotPlay();
    });
  }

  /// Called by the UI when the human plays a card.
  void playCard(PlayingCard card) {
    if (!isHumanTurnToPlay) return;
    hand!.playCard(humanSeat, card);
    notifyListeners();
    _maybeRunBotPlay();
  }

  void _finishHand() {
    final result = hand!.finish(_originalHands!);
    lastHandResult = result;
    scoreboard.addHand(result);
    phase = GamePhase.handSummary;
    banner = null;
    notifyListeners();
  }

  /// Called by the UI after showing the hand summary, to deal the next hand
  /// (or end the match if the target score has been reached).
  void continueAfterHand() {
    if (scoreboard.isMatchOver) {
      phase = GamePhase.matchOver;
      notifyListeners();
      return;
    }
    _dealer = _dealer.next;
    _startHand();
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
