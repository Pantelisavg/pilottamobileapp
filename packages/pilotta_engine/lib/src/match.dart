import 'round.dart';
import 'seat.dart';

/// Tracks cumulative scores across hands until a team reaches the match's
/// target score.
class MatchScoreboard {
  final int targetScore;
  final List<HandResult> history = [];
  final Map<Team, int> totals = {Team.northSouth: 0, Team.eastWest: 0};

  MatchScoreboard({required this.targetScore});

  void addHand(HandResult result) {
    totals[Team.northSouth] =
        totals[Team.northSouth]! + result.rounded.northSouth;
    totals[Team.eastWest] = totals[Team.eastWest]! + result.rounded.eastWest;
    history.add(result);
  }

  bool get isMatchOver {
    final ns = totals[Team.northSouth]!;
    final ew = totals[Team.eastWest]!;
    return ns >= targetScore || ew >= targetScore;
  }

  /// The winning team once [isMatchOver] is true. If both teams cross the
  /// target on the same hand, the higher total wins; an exact tie means the
  /// match is not yet decided (another hand must be played).
  Team? get winner {
    final ns = totals[Team.northSouth]!;
    final ew = totals[Team.eastWest]!;
    if (ns < targetScore && ew < targetScore) return null;
    if (ns == ew) return null;
    return ns > ew ? Team.northSouth : Team.eastWest;
  }
}

/// Rotates the dealer seat anti-clockwise each hand.
Seat nextDealer(Seat currentDealer) => currentDealer.next;
