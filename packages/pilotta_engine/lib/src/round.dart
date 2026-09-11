import 'auction.dart';
import 'card.dart';
import 'declaration.dart';
import 'scoring.dart';
import 'seat.dart';
import 'trick.dart';

const int kBelotePoints = 20;

/// Everything about how declarations and belote were resolved for a hand,
/// exposed mainly so a UI can explain the score breakdown.
class DeclarationOutcome {
  final Map<Seat, Declaration?> bestPerSeat;
  final Team? winningTeam;
  final int winningTeamPoints;
  final Seat? beloteSeat;

  const DeclarationOutcome({
    required this.bestPerSeat,
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

  const HandResult({
    required this.contract,
    required this.trickPoints,
    required this.allTricksTeam,
    required this.declarations,
    required this.contractMade,
    required this.rawTotals,
    required this.rounded,
  });
}

/// Orchestrates a single dealt hand: the initial hands are fixed (post
/// auction, pre-play) and cards are then played trick by trick until all 32
/// are gone, at which point [finish] computes the score.
class PilottaHand {
  final Contract contract;
  final Map<Seat, List<PlayingCard>> _hands;
  final Map<Team, int> _trickPointsWon = {Team.northSouth: 0, Team.eastWest: 0};
  final Map<Team, int> _tricksWon = {Team.northSouth: 0, Team.eastWest: 0};
  Team? _lastTrickTeam;
  Trick? _currentTrick;
  Seat _nextLeader;
  final List<Trick> completedTricks = [];

  PilottaHand({
    required this.contract,
    required Map<Seat, List<PlayingCard>> initialHands,
    required Seat firstLeader,
  })  : _hands = {for (final e in initialHands.entries) e.key: List.of(e.value)},
        _nextLeader = firstLeader {
    for (final hand in _hands.values) {
      if (hand.length != 8) {
        throw ArgumentError('Each hand must have exactly 8 cards.');
      }
    }
    _currentTrick = Trick(leader: _nextLeader, trumpSuit: contract.trumpSuit);
  }

  /// Cards a seat still holds.
  List<PlayingCard> handOf(Seat seat) => List.unmodifiable(_hands[seat]!);

  Trick get currentTrick => _currentTrick!;

  bool get isHandComplete => completedTricks.length == 8;

  List<PlayingCard> legalPlays(Seat seat) {
    if (seat != currentTrick.seatToPlay) return const [];
    return currentTrick.legalPlays(_hands[seat]!);
  }

  /// Plays [card] for [seat]. Throws if it's not their turn or the card is
  /// not a legal play. Automatically resolves the trick once 4 cards are
  /// in, feeding the winner in as the next leader.
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

    currentTrick.play(seat, card);
    hand.remove(card);

    if (currentTrick.isComplete) {
      final finishedTrick = currentTrick;
      final winner = finishedTrick.winner;
      final team = winner.team;
      _trickPointsWon[team] = _trickPointsWon[team]! + finishedTrick.points;
      _tricksWon[team] = _tricksWon[team]! + 1;
      _lastTrickTeam = team;
      completedTricks.add(finishedTrick);
      if (!isHandComplete) {
        _nextLeader = winner;
        _currentTrick = Trick(leader: _nextLeader, trumpSuit: contract.trumpSuit);
      }
    }
  }

  DeclarationOutcome _resolveDeclarations(Map<Seat, List<PlayingCard>> originalHands) {
    final bestPerSeat = <Seat, Declaration?>{
      for (final seat in Seat.values)
        seat: bestDeclaration(seat, originalHands[seat]!, contract.trumpSuit),
    };

    Declaration? overallBest;
    for (final decl in bestPerSeat.values) {
      if (decl == null) continue;
      if (overallBest == null || decl.compareTo(overallBest, contract.trumpSuit) > 0) {
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
        winningPoints = bestPerSeat.values
            .where((d) => d != null && d.seat.team == winningTeam)
            .fold(0, (sum, d) => sum + d!.pointValue());
      }
    }

    Seat? beloteSeat;
    for (final seat in Seat.values) {
      final hand = originalHands[seat]!;
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
      winningTeam: winningTeam,
      winningTeamPoints: winningPoints,
      beloteSeat: beloteSeat,
    );
  }

  /// Computes the final score. [originalHands] must be the 8-card hands as
  /// dealt before any cards were played (declarations are evaluated against
  /// them), which callers should retain themselves since [PilottaHand]
  /// mutates its internal copies as cards are played.
  HandResult finish(Map<Seat, List<PlayingCard>> originalHands) {
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
                : _trickPointsWon[team]! +
                    (_lastTrickTeam == team ? 10 : 0),
    };

    final declarations = _resolveDeclarations(originalHands);

    int teamShare(Team team) {
      var points = trickPoints[team]!;
      if (declarations.winningTeam == team) points += declarations.winningTeamPoints;
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
      northSouthRawTrickPoints: trickPoints[Team.northSouth]!,
      eastWestRawTrickPoints: trickPoints[Team.eastWest]!,
    );

    return HandResult(
      contract: contract,
      trickPoints: trickPoints,
      allTricksTeam: allTricksTeam,
      declarations: declarations,
      contractMade: settlement.contractMade,
      rawTotals: settlement.rawTotals,
      rounded: rounded,
    );
  }
}
