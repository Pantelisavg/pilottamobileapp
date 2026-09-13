import 'auction.dart';
import 'card.dart';
import 'declaration.dart';
import 'scoring.dart';
import 'seat.dart';
import 'trick.dart';

const int kBelotePoints = 20;

/// A live "Pilotta"/"Repilotta" call, said the instant the holder of the
/// King+Queen of trump actually plays the first (Pilotta) or second
/// (Repilotta) of the two — see [PilottaHand.lastBeloteAnnouncement].
enum BeloteAnnouncement { none, pilotta, repilotta }

/// Tracks whether a player has announced and/or revealed a non-Pilotta
/// declaration in time. Belote/Pilotta (King+Queen of trump) is exempt from
/// this timing entirely — it's declared live as those two cards are played,
/// always counts, and is never tracked through this state machine.
enum DeclarationAnnounceState {
  /// Not yet announced (or nothing to announce).
  none,

  /// Announced during trick 1, not yet revealed.
  announced,

  /// Revealed before playing a card in trick 2 — counts towards scoring.
  revealed,

  /// Announced but never revealed before playing a card in trick 2 —
  /// forfeited, and does not count towards scoring.
  forfeited,
}

/// Everything about how declarations and belote were resolved for a hand,
/// exposed mainly so a UI can explain the score breakdown.
class DeclarationOutcome {
  /// Each seat's best declaration, but only for seats who successfully
  /// announced *and* revealed it in time — null for every other seat
  /// (including seats who never had a declaration, never announced one, or
  /// forfeited one by not revealing in time).
  final Map<Seat, Declaration?> bestPerSeat;

  /// Every declaration each successfully-revealed seat actually holds
  /// (empty for every other seat) — a seat can hold more than one, and all
  /// of them count once revealed; see [PilottaHand.allDeclarationsOf]. This
  /// is what [winningTeamPoints] is actually the sum of.
  final Map<Seat, List<Declaration>> allPerSeat;

  /// Declarations that were announced but never revealed in time — kept
  /// purely for UI/explanatory purposes (e.g. "North forgot to reveal a
  /// sequence"); these never counted towards scoring.
  final Map<Seat, Declaration> forfeitedPerSeat;

  final Team? winningTeam;
  final int winningTeamPoints;
  final Seat? beloteSeat;

  const DeclarationOutcome({
    required this.bestPerSeat,
    required this.allPerSeat,
    required this.forfeitedPerSeat,
    required this.winningTeam,
    required this.winningTeamPoints,
    required this.beloteSeat,
  });
}

/// Full breakdown of how a hand's final score was reached.
class HandResult {
  final Contract contract;
  final Map<Team, int> trickPoints;
  final Team? allTricksTeam;
  final DeclarationOutcome declarations;
  final bool contractMade;
  final Map<Team, int> rawTotals;
  final RoundedScore rounded;

  /// The auction that led to [contract] — kept purely so a UI can show how
  /// the bidding for this specific hand went after the fact; empty if not
  /// supplied (e.g. hands constructed directly in tests).
  final List<AuctionCall> auctionCalls;

  /// Each seat's original 8-card deal, and every trick played, in order —
  /// kept so a UI can replay the whole hand card by card after it's over.
  final Map<Seat, List<PlayingCard>> originalHands;
  final List<Trick> tricks;

  const HandResult({
    required this.contract,
    required this.trickPoints,
    required this.allTricksTeam,
    required this.declarations,
    required this.contractMade,
    required this.rawTotals,
    required this.rounded,
    this.auctionCalls = const [],
    this.originalHands = const {},
    this.tricks = const [],
  });
}

/// Orchestrates a single dealt hand: the initial hands are fixed (post
/// auction, pre-play) and cards are then played trick by trick until all 32
/// are gone, at which point [finish] computes the score.
class PilottaHand {
  final Contract contract;
  final Map<Seat, List<PlayingCard>> _originalHands;
  final Map<Seat, List<PlayingCard>> _hands;
  final Map<Team, int> _trickPointsWon = {Team.northSouth: 0, Team.eastWest: 0};
  final Map<Team, int> _tricksWon = {Team.northSouth: 0, Team.eastWest: 0};

  /// House-rule variant threaded down to every [Trick] this hand plays —
  /// see [Trick.mustOvertrumpAllSuits].
  final bool mustOvertrumpAllSuits;

  final Map<Seat, DeclarationAnnounceState> _declarationState = {
    for (final seat in Seat.values) seat: DeclarationAnnounceState.none,
  };

  Team? _lastTrickTeam;
  Trick? _currentTrick;
  Seat _nextLeader;
  final List<Trick> completedTricks = [];
  final Map<Seat, int> _beloteCardsPlayed = {};

  /// Set by every [playCard] call: whether that exact card completed a
  /// live Belote/Pilotta call. [none] most of the time.
  BeloteAnnouncement lastBeloteAnnouncement = BeloteAnnouncement.none;

  /// The auction that led to [contract] — kept only to pass through to
  /// [HandResult.auctionCalls] for post-hand review; irrelevant to scoring.
  final List<AuctionCall> auctionCalls;

  PilottaHand({
    required this.contract,
    required Map<Seat, List<PlayingCard>> initialHands,
    required Seat firstLeader,
    this.mustOvertrumpAllSuits = false,
    this.auctionCalls = const [],
  })  : _originalHands = {
          for (final e in initialHands.entries)
            e.key: List.unmodifiable(List.of(e.value)),
        },
        _hands = {
          for (final e in initialHands.entries) e.key: List.of(e.value)
        },
        _nextLeader = firstLeader {
    for (final hand in _hands.values) {
      if (hand.length != 8) {
        throw ArgumentError('Each hand must have exactly 8 cards.');
      }
    }
    _currentTrick = Trick(
      leader: _nextLeader,
      trumpSuit: contract.trumpSuit,
      mustOvertrumpAllSuits: mustOvertrumpAllSuits,
    );
  }

  /// Cards a seat still holds.
  List<PlayingCard> handOf(Seat seat) => List.unmodifiable(_hands[seat]!);

  /// The 8 cards [seat] was originally dealt, unaffected by play since —
  /// used to evaluate declarations at any point during the hand.
  List<PlayingCard> originalHandOf(Seat seat) => _originalHands[seat]!;

  /// The best declaration [seat] could announce, based on their original
  /// hand — independent of whether they've actually announced/revealed it.
  /// This is the one value spoken out loud during the announce step, and
  /// the one compared across the table to decide who wins the right to
  /// score — but a hand can hold more than one non-overlapping declaration
  /// (e.g. a 4-run in one suit and a separate 3-run in another), and *all*
  /// of them are shown and score once revealed — see [allDeclarationsOf].
  Declaration? bestDeclarationOf(Seat seat) =>
      bestDeclaration(seat, _originalHands[seat]!, contract.trumpSuit);

  /// Every declaration [seat]'s original hand holds — what actually gets
  /// shown (and scores) once they reveal, as opposed to [bestDeclarationOf]
  /// which is only the single headline value they announce.
  List<Declaration> allDeclarationsOf(Seat seat) =>
      findDeclarations(seat, _originalHands[seat]!);

  /// Where [seat] currently stands in the announce/reveal flow for their
  /// (non-Pilotta) declaration, if any.
  DeclarationAnnounceState declarationStateOf(Seat seat) =>
      _declarationState[seat]!;

  Trick get currentTrick => _currentTrick!;

  /// Whether [seat] was originally dealt both the King and Queen of trump —
  /// the Belote combination, live-announced via [lastBeloteAnnouncement] as
  /// each of the two is actually played, independent of (and exempt from)
  /// the announce/reveal timing that applies to every other declaration.
  bool holdsBelote(Seat seat) {
    final trump = contract.trumpSuit;
    final hand = _originalHands[seat]!;
    return hand.any((c) => c.suit == trump && c.rank == Rank.king) &&
        hand.any((c) => c.suit == trump && c.rank == Rank.queen);
  }

  bool get isHandComplete => completedTricks.length == 8;

  List<PlayingCard> legalPlays(Seat seat) {
    // A just-finished trick sits on the table (see [isAwaitingNextTrick])
    // until [startNextTrick] is called — nobody may play into it meanwhile.
    if (currentTrick.isComplete) return const [];
    if (seat != currentTrick.seatToPlay) return const [];
    return currentTrick.legalPlays(_hands[seat]!);
  }

  /// Directly sets every seat's announce/reveal state, bypassing the usual
  /// timing checks — used only to reconstruct a hand from previously-saved
  /// state (a "continue game later" resume), where these states are
  /// already-valid history, not a new live call.
  void restoreDeclarationStates(Map<Seat, DeclarationAnnounceState> states) {
    _declarationState.addAll(states);
  }

  /// Whether [seat] may announce a (non-Pilotta) declaration right now:
  /// only during trick 1, only once, and only if they actually hold one.
  bool canAnnounceDeclaration(Seat seat) {
    if (completedTricks.isNotEmpty) return false;
    if (_declarationState[seat] != DeclarationAnnounceState.none) return false;
    return bestDeclarationOf(seat) != null;
  }

  /// Announces [seat]'s best declaration. It must still be revealed before
  /// [seat] plays a card in trick 2, or [playCard] will forfeit it
  /// automatically.
  void announceDeclaration(Seat seat) {
    if (!canAnnounceDeclaration(seat)) {
      throw StateError('$seat cannot announce a declaration right now.');
    }
    _declarationState[seat] = DeclarationAnnounceState.announced;
  }

  /// Whether [seat] may reveal a previously-announced declaration right
  /// now — any time after announcing, up until they play their card in
  /// trick 2 (after which [playCard] auto-forfeits it).
  bool canRevealDeclaration(Seat seat) {
    return _declarationState[seat] == DeclarationAnnounceState.announced &&
        completedTricks.length <= 1;
  }

  /// Reveals [seat]'s previously-announced declaration, making it eligible
  /// to count towards scoring (subject to the cross-team comparison).
  void revealDeclaration(Seat seat) {
    if (!canRevealDeclaration(seat)) {
      throw StateError('$seat cannot reveal a declaration right now.');
    }
    _declarationState[seat] = DeclarationAnnounceState.revealed;
  }

  /// Plays [card] for [seat]. Throws if it's not their turn or the card is
  /// not a legal play. Automatically resolves the trick once 4 cards are
  /// in, feeding the winner in as the next leader.
  ///
  /// If [seat] announced a declaration but never revealed it, playing their
  /// card during trick 2 automatically forfeits it, per the "announce in
  /// trick 1, reveal before your trick-2 card, or it doesn't count" rule.
  void playCard(Seat seat, PlayingCard card) {
    if (isHandComplete) {
      throw StateError('Hand already complete.');
    }
    final hand = _hands[seat]!;
    if (!hand.contains(card)) {
      throw ArgumentError('$seat does not hold $card.');
    }
    if (!currentTrick.legalPlays(hand).contains(card)) {
      throw ArgumentError('$card is not a legal play for $seat right now.');
    }

    if (completedTricks.length == 1 &&
        _declarationState[seat] == DeclarationAnnounceState.announced) {
      _declarationState[seat] = DeclarationAnnounceState.forfeited;
    }

    currentTrick.play(seat, card);
    hand.remove(card);

    lastBeloteAnnouncement = BeloteAnnouncement.none;
    if (card.suit == contract.trumpSuit &&
        (card.rank == Rank.king || card.rank == Rank.queen) &&
        holdsBelote(seat)) {
      final count = (_beloteCardsPlayed[seat] ?? 0) + 1;
      _beloteCardsPlayed[seat] = count;
      lastBeloteAnnouncement = count == 1
          ? BeloteAnnouncement.pilotta
          : BeloteAnnouncement.repilotta;
    }

    if (currentTrick.isComplete) {
      final finishedTrick = currentTrick;
      final winner = finishedTrick.winner;
      final team = winner.team;
      _trickPointsWon[team] = _trickPointsWon[team]! + finishedTrick.points;
      _tricksWon[team] = _tricksWon[team]! + 1;
      _lastTrickTeam = team;
      completedTricks.add(finishedTrick);
      _nextLeader = winner;
      // The finished trick is left in place (all 4 cards still visible via
      // [currentTrick]) rather than immediately replaced — callers give
      // players a moment to actually see it before calling [startNextTrick].
    }
  }

  /// Whether the just-finished trick is still sitting on the table, waiting
  /// for [startNextTrick] to clear it and deal in the next one.
  bool get isAwaitingNextTrick => currentTrick.isComplete && !isHandComplete;

  /// Clears the completed trick off the table and starts the next one, led
  /// by whoever won the last trick. Only valid while [isAwaitingNextTrick].
  void startNextTrick() {
    if (!isAwaitingNextTrick) {
      throw StateError('No completed trick waiting to be cleared.');
    }
    _currentTrick = Trick(
      leader: _nextLeader,
      trumpSuit: contract.trumpSuit,
      mustOvertrumpAllSuits: mustOvertrumpAllSuits,
    );
  }

  DeclarationOutcome _resolveDeclarations() {
    final bestPerSeat = <Seat, Declaration?>{};
    final allPerSeat = <Seat, List<Declaration>>{};
    final forfeitedPerSeat = <Seat, Declaration>{};
    for (final seat in Seat.values) {
      final state = _declarationState[seat];
      if (state == DeclarationAnnounceState.revealed) {
        bestPerSeat[seat] = bestDeclarationOf(seat);
        allPerSeat[seat] = allDeclarationsOf(seat);
      } else {
        bestPerSeat[seat] = null;
        allPerSeat[seat] = const [];
        if (state == DeclarationAnnounceState.forfeited) {
          final forfeited = bestDeclarationOf(seat);
          if (forfeited != null) forfeitedPerSeat[seat] = forfeited;
        }
      }
    }

    Declaration? overallBest;
    for (final decl in bestPerSeat.values) {
      if (decl == null) continue;
      if (overallBest == null ||
          decl.compareTo(overallBest, contract.trumpSuit) > 0) {
        overallBest = decl;
      }
    }

    Team? winningTeam;
    var winningPoints = 0;
    if (overallBest != null) {
      // Check for an exact tie against another player on the OTHER team's
      // best declaration: per the rules, a true tie means no one scores.
      final tiedAcrossTeams = bestPerSeat.entries.any((e) =>
          e.value != null &&
          e.value != overallBest &&
          e.value!.seat.team != overallBest!.seat.team &&
          e.value!.compareTo(overallBest, contract.trumpSuit) == 0);

      if (!tiedAcrossTeams) {
        winningTeam = overallBest.seat.team;
        // Every declaration each winning-team seat holds counts, not just
        // each seat's single best (headline) one — see [allDeclarationsOf].
        winningPoints = allPerSeat.entries
            .where((e) => e.key.team == winningTeam)
            .fold(
                0,
                (sum, e) =>
                    sum + e.value.fold(0, (s, d) => s + d.pointValue()));
      }
    }

    Seat? beloteSeat;
    for (final seat in Seat.values) {
      final hand = _originalHands[seat]!;
      final holdsKing =
          hand.any((c) => c.suit == contract.trumpSuit && c.rank == Rank.king);
      final holdsQueen =
          hand.any((c) => c.suit == contract.trumpSuit && c.rank == Rank.queen);
      if (holdsKing && holdsQueen) {
        beloteSeat = seat;
        break;
      }
    }

    return DeclarationOutcome(
      bestPerSeat: bestPerSeat,
      allPerSeat: allPerSeat,
      forfeitedPerSeat: forfeitedPerSeat,
      winningTeam: winningTeam,
      winningTeamPoints: winningPoints,
      beloteSeat: beloteSeat,
    );
  }

  /// Computes the final score. Declarations are evaluated against each
  /// seat's original 8-card hand as dealt, restricted to seats who
  /// correctly announced (trick 1) and revealed (before their trick-2
  /// card) theirs — see [announceDeclaration]/[revealDeclaration]. Belote/
  /// Pilotta (King+Queen of trump) is exempt from that timing and from the
  /// cross-team comparison, and always counts for whichever team holds it.
  HandResult finish() {
    if (!isHandComplete) {
      throw StateError('Cannot score a hand before all 8 tricks are played.');
    }

    final allTricksTeam = _tricksWon[Team.northSouth] == 8
        ? Team.northSouth
        : _tricksWon[Team.eastWest] == 8
            ? Team.eastWest
            : null;

    final trickPoints = <Team, int>{
      for (final team in Team.values)
        team: team == allTricksTeam
            ? kAllTricksCapotPoints
            : allTricksTeam != null
                ? 0
                : _trickPointsWon[team]! + (_lastTrickTeam == team ? 10 : 0),
    };

    final declarations = _resolveDeclarations();

    int teamShare(Team team) {
      var points = trickPoints[team]!;
      if (declarations.winningTeam == team) {
        points += declarations.winningTeamPoints;
      }
      if (declarations.beloteSeat?.team == team) points += kBelotePoints;
      return points;
    }

    final biddingTeam = contract.biddingTeam;
    final opponentTeam = biddingTeam.opponent;
    final biddingTeamPoints = teamShare(biddingTeam);
    final opponentPoints = teamShare(opponentTeam);

    final settlement = settleContract(
      biddingTeam: biddingTeam,
      biddingTeamPoints: biddingTeamPoints,
      opponentPoints: opponentPoints,
      contractValue: contract.value,
      multiplierFactor: contract.multiplier.factor,
      madeOverride: contract.isCapot ? allTricksTeam == biddingTeam : null,
    );

    final rounded = roundToTens(
      northSouthTotal: settlement.rawTotals[Team.northSouth]!,
      eastWestTotal: settlement.rawTotals[Team.eastWest]!,
      biddingTeam: biddingTeam,
    );

    return HandResult(
      contract: contract,
      trickPoints: trickPoints,
      allTricksTeam: allTricksTeam,
      declarations: declarations,
      contractMade: settlement.contractMade,
      rawTotals: settlement.rawTotals,
      rounded: rounded,
      auctionCalls: auctionCalls,
      originalHands: {
        for (final seat in Seat.values) seat: originalHandOf(seat),
      },
      tricks: List.unmodifiable(completedTricks),
    );
  }
}
