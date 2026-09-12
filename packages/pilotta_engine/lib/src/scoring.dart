import 'seat.dart';

/// Total trick-taking points in play for a normal (non-capot) hand:
/// 152 in the cards themselves + 10 bonus for taking the last trick.
const int kTotalTrickPoints = 162;

/// Flat score awarded when a team takes every trick of the hand ("capot"),
/// replacing the normal 162-point trick total.
const int kAllTricksCapotPoints = 250;

/// Final rounded score for one hand, in the /10 units the scoreboard is
/// kept in (e.g. a raw 287 becomes 29).
class RoundedScore {
  final int northSouth;
  final int eastWest;
  const RoundedScore(this.northSouth, this.eastWest);
}

/// Rounds each team's raw point total to the nearest multiple of 10 for the
/// scoreboard: a remainder of 1–5 rounds down, 6–9 rounds up — applied
/// independently to each team's own total.
///
/// Because the two teams' raw trick-taking points always sum to a fixed
/// total (162 normally, or 250/0 on a capot sweep), their remainders are
/// linked, and independent rounding is only ever ambiguous in one specific
/// case: both remainders land exactly on 6 (the *only* pair of remainders
/// that (a) sums to 12, the only other value ≡162 mod 10 alongside 2, and
/// (b) has both sides individually clear the round-up threshold — this is
/// "Ο Κανόνας του 6" ["the Rule of Six"]). Both teams would then round up
/// and overshoot the fixed total by one unit, so by convention the
/// bidding team keeps the round-up and the defence is dropped back down.
///
/// [biddingTeam] is only consulted in that one tied-at-6 case.
RoundedScore roundToTens({
  required int northSouthTotal,
  required int eastWestTotal,
  required Team biddingTeam,
}) {
  final nsRem = northSouthTotal % 10;
  final ewRem = eastWestTotal % 10;
  final nsWantsUp = nsRem >= 6;
  final ewWantsUp = ewRem >= 6;

  bool nsUp, ewUp;
  if (nsWantsUp && ewWantsUp) {
    nsUp = biddingTeam == Team.northSouth;
    ewUp = !nsUp;
  } else {
    nsUp = nsWantsUp;
    ewUp = ewWantsUp;
  }

  final ns = (northSouthTotal ~/ 10) + (nsUp ? 1 : 0);
  final ew = (eastWestTotal ~/ 10) + (ewUp ? 1 : 0);
  return RoundedScore(ns, ew);
}

/// Result of settling a single hand against its contract.
class HandSettlement {
  /// Raw (pre-rounding) points for each team, including trick points,
  /// declarations, belote, and — if the contract was made — the contract
  /// value bonus.
  final Map<Team, int> rawTotals;

  /// Whether the bidding team fulfilled its contract.
  final bool contractMade;

  const HandSettlement(this.rawTotals, this.contractMade);
}

/// Applies the "made contract / failed contract" rule:
///
/// - Plain (undoubled) contract, made: the bidding team keeps its own
///   trick points and declarations, plus the contract value. The defence
///   keeps whatever it earned normally.
/// - Plain (undoubled) contract, failed: the bidding team scores 0, and
///   the defence gets the *entire* hand's points (both teams' trick points
///   and declarations) *plus* the contract value itself — per the rules
///   spec: "bid + all 162 trick points + all declarations" go to the
///   defenders. This also produces the correct "reverse capot" result
///   automatically: when the defence sweeps all 8 tricks against a failed
///   attacking bid, [opponentPoints] already reflects the capot override
///   applied by the caller before settlement.
/// - Doubled/redoubled ("κλειστό"/"ξανακλειστό"), either outcome: closing
///   raises the stakes for both sides at once — the side proven right by
///   the outcome takes the *entire* point pool from the hand (both teams'
///   trick points and declarations combined) plus the contract value
///   multiplied by [multiplierFactor] (2 doubled, 4 redoubled), and the
///   other side scores nothing at all, even points it would otherwise
///   have kept in a plain contract. Confirmed against a worked example:
///   an 80 bid, doubled and made with 97 trick points against the
///   defence's 65 (162 total, no declarations), scores 80×2 + 162 = 322
///   for the bidding team and 0 for the defence.
HandSettlement settleContract({
  required Team biddingTeam,
  required int biddingTeamPoints,
  required int opponentPoints,
  required int contractValue,
  int multiplierFactor = 1,

  /// Overrides the ">= contractValue" success check — needed for a Capot
  /// contract, whose success criterion is literally sweeping all 8 tricks
  /// rather than reaching a point threshold.
  bool? madeOverride,
}) {
  final made = madeOverride ?? (biddingTeamPoints >= contractValue);
  final opponentTeam = biddingTeam.opponent;
  final pool = biddingTeamPoints + opponentPoints;
  final doubled = multiplierFactor > 1;

  if (made) {
    if (doubled) {
      return HandSettlement({
        biddingTeam: contractValue * multiplierFactor + pool,
        opponentTeam: 0,
      }, true);
    }
    return HandSettlement({
      biddingTeam: biddingTeamPoints + contractValue,
      opponentTeam: opponentPoints,
    }, true);
  }

  // Failed contract: the defence sweeps the whole pool plus the contract
  // value, whether or not it was doubled — doubling only scales that
  // contract value by [multiplierFactor].
  return HandSettlement({
    biddingTeam: 0,
    opponentTeam: contractValue * multiplierFactor + pool,
  }, false);
}
