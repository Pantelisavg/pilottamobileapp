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
/// scoreboard: ordinary "round half up" applied independently to each
/// team's own total (remainder < 5 rounds down, >= 5 rounds up).
///
/// Because the two teams' raw trick-taking points always sum to a fixed
/// total (162 normally, or 250/0 on a capot sweep), their remainders are
/// linked — worked example from the rules: a bidding team total of 180
/// (remainder 0) against a defending total of 62 (remainder 2) rounds to
/// 18–6, i.e. the team with the *numerically larger* remainder (2) still
/// rounds down, because 2 is below the halfway point. Independent
/// "round half up" is only ever ambiguous in the one case both teams'
/// remainders are simultaneously >= 5 — only possible when they sum to 12
/// (e.g. 6 and 6, or 5 and 7) — since then both would round up and
/// overshoot the fixed total by one unit. That conflict is resolved by
/// raw trick-taking points: whoever actually won more of the 162 (or 250)
/// point pool keeps the round-up, and the other team is dropped back down.
///
/// [northSouthRawTrickPoints]/[eastWestRawTrickPoints] must be the raw
/// card-point totals from trick-taking alone (i.e. before adding
/// declarations/belote/contract bonuses), since those bonuses are always
/// multiples of 10 and only the trick points can produce a remainder.
RoundedScore roundToTens({
  required int northSouthTotal,
  required int eastWestTotal,
  required int northSouthRawTrickPoints,
  required int eastWestRawTrickPoints,
}) {
  final nsRem = northSouthTotal % 10;
  final ewRem = eastWestTotal % 10;
  final nsWantsUp = nsRem >= 5;
  final ewWantsUp = ewRem >= 5;

  bool nsUp, ewUp;
  if (nsWantsUp && ewWantsUp) {
    nsUp = northSouthRawTrickPoints >= eastWestRawTrickPoints;
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
/// - If the bidding team's own points (trick points they won, plus any
///   declarations/belote awarded to them) reach the contract value, they
///   keep those points AND additionally score the contract value itself.
///   The opposing team keeps whatever points they earned normally.
/// - If the bidding team fails to reach the contract value, ALL points
///   from the hand (both teams' trick points, declarations and belote)
///   go to the opposing team instead, and the bidding team scores 0.
///
/// A doubled/redoubled contract multiplies whichever side ends up winning
/// the hand's points (the bidding team if the contract is made, or the
/// defenders if it fails) by [multiplierFactor] (2 for doubled, 4 for
/// redoubled, 1 otherwise) — doubling is a bet on the contract's outcome,
/// so only the side proven right by that outcome benefits from it.
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

  if (made) {
    return HandSettlement({
      biddingTeam: (biddingTeamPoints + contractValue) * multiplierFactor,
      opponentTeam: opponentPoints,
    }, true);
  }

  return HandSettlement({
    biddingTeam: 0,
    opponentTeam: (biddingTeamPoints + opponentPoints) * multiplierFactor,
  }, false);
}
