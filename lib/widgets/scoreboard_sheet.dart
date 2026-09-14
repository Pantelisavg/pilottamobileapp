import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import '../theme/pilotta_colors.dart';
import 'seat_layout.dart';
import 'suit_icon.dart';

/// One row of the ledger-style scoreboard: a single hand's contract and its
/// rounded score, already oriented from the viewer's own team perspective
/// ("mine" / "theirs") so the sheet never needs to know north/south vs.
/// east/west.
class ScoreRow {
  final int index;
  final Suit trumpSuit;
  final bool isCapot;
  final int biddingValue;
  final String biddingSeatLabel;
  final bool contractMade;
  final int roundedMine;
  final int roundedTheirs;

  /// Declaration (+ belote) points this team was credited for this hand,
  /// in the same /10 units as [roundedMine]/[roundedTheirs] — 0 if none.
  final int declarationPointsMine;
  final int declarationPointsTheirs;

  /// Raw trick-taking points this team won this hand (before the contract
  /// bonus/multiplier is applied), in the same /10 units as every other
  /// number on this row — 0 if the team took no tricks worth counting
  /// (e.g. a failed contract awards the whole pool to the defence).
  final int trickPointsMine;
  final int trickPointsTheirs;

  const ScoreRow({
    required this.index,
    required this.trumpSuit,
    required this.isCapot,
    required this.biddingValue,
    required this.biddingSeatLabel,
    required this.contractMade,
    required this.roundedMine,
    required this.roundedTheirs,
    this.declarationPointsMine = 0,
    this.declarationPointsTheirs = 0,
    this.trickPointsMine = 0,
    this.trickPointsTheirs = 0,
  });
}

/// Builds the scoreboard's rows from [history], oriented to [viewerSeat]'s
/// own team perspective — the one place this shaping happens, shared by
/// local and networked play alike now that [HandResult] means the same
/// thing in both (see `GameTableData.matchHistory`).
List<ScoreRow> buildScoreRows(List<HandResult> history, Seat viewerSeat) {
  final ourTeam = viewerSeat.team;
  int declarationPointsOf(HandResult r, Team team) {
    final d = r.declarations;
    var points = d.winningTeam == team ? d.winningTeamPoints : 0;
    if (d.beloteSeat?.team == team) points += kBelotePoints;
    return points ~/ 10;
  }

  return [
    for (var i = 0; i < history.length; i++)
      ScoreRow(
        index: i + 1,
        trumpSuit: history[i].contract.trumpSuit,
        isCapot: history[i].contract.isCapot,
        biddingValue: history[i].contract.value,
        biddingSeatLabel:
            seatLabelRelativeTo(history[i].contract.biddingSeat, viewerSeat),
        contractMade: history[i].contractMade,
        roundedMine: ourTeam == Team.northSouth
            ? history[i].rounded.northSouth
            : history[i].rounded.eastWest,
        roundedTheirs: ourTeam == Team.northSouth
            ? history[i].rounded.eastWest
            : history[i].rounded.northSouth,
        declarationPointsMine: declarationPointsOf(history[i], ourTeam),
        declarationPointsTheirs:
            declarationPointsOf(history[i], ourTeam.opponent),
        trickPointsMine: history[i].trickPoints[ourTeam]! ~/ 10,
        trickPointsTheirs: history[i].trickPoints[ourTeam.opponent]! ~/ 10,
      ),
  ];
}

/// A scrollable ledger of every hand played so far this match, laid out like
/// a traditional Pilotta score sheet: the bid for each hand down the middle
/// column, each team's running total in the outer columns (with that hand's
/// declaration points noted alongside it), oldest hand at the top.
void showScoreboardSheet(
  BuildContext context, {
  required List<ScoreRow> rows,
  required int totalMine,
  required int totalTheirs,
  required int targetScore,

  /// Called with a row's index into [rows] when it's tapped — lets the
  /// caller open a full trick-by-trick replay of that hand. Rows aren't
  /// tappable at all if this is left null.
  void Function(int index)? onRowTap,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: PilottaColors.felt800,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 4),
            child: SizedBox(
              width: 32,
              height: 4,
            ),
          ),
          _HeaderRow(targetScore: targetScore),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: rows.isEmpty
                ? const Center(
                    child: Text('Δεν έχει παιχτεί ακόμα καμία μοιρασιά.',
                        style: TextStyle(color: Colors.white54)),
                  )
                : _Ledger(
                    rows: rows,
                    scrollController: scrollController,
                    onRowTap: onRowTap,
                  ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Σύνολο',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text('$totalMine – $totalTheirs',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _HeaderRow extends StatelessWidget {
  final int targetScore;

  const _HeaderRow({required this.targetScore});

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Expanded(
              child: Text('Εμείς',
                  textAlign: TextAlign.center, style: labelStyle)),
          SizedBox(
            width: 56,
            child: Text('$targetScore',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ),
          const Expanded(
              child: Text('Αυτοί',
                  textAlign: TextAlign.center, style: labelStyle)),
        ],
      ),
    );
  }
}

/// Renders [rows] as a running ledger: each team's cumulative total is
/// folded forward while iterating top-to-bottom (oldest hand first, matching
/// how a paper score sheet is filled in), and a team's running-total cell is
/// only shown when it actually moved that hand — otherwise a dash, so the
/// column reads the way a real tally sheet does.
class _Ledger extends StatelessWidget {
  final List<ScoreRow> rows;
  final ScrollController scrollController;
  final void Function(int index)? onRowTap;

  const _Ledger({
    required this.rows,
    required this.scrollController,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    // Precomputed up front, not accumulated inside itemBuilder — a lazy
    // ListView doesn't guarantee items are built in index order, so mutating
    // a running total across calls could show a stale/wrong sum.
    final runningMine = <int>[];
    final runningTheirs = <int>[];
    var mine = 0;
    var theirs = 0;
    for (final r in rows) {
      mine += r.roundedMine;
      theirs += r.roundedTheirs;
      runningMine.add(mine);
      runningTheirs.add(theirs);
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) =>
          const Divider(color: Colors.white12, height: 1),
      itemBuilder: (context, i) {
        final r = rows[i];
        final row = Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: _TeamCell(
                  declarationPoints: r.declarationPointsMine,
                  trickPoints: r.trickPointsMine,
                  runningTotal: runningMine[i],
                  changedThisHand: r.roundedMine != 0,
                ),
              ),
              SizedBox(
                width: 56,
                child: _BidCell(row: r),
              ),
              Expanded(
                child: _TeamCell(
                  declarationPoints: r.declarationPointsTheirs,
                  trickPoints: r.trickPointsTheirs,
                  runningTotal: runningTheirs[i],
                  changedThisHand: r.roundedTheirs != 0,
                ),
              ),
            ],
          ),
        );
        return onRowTap == null
            ? row
            : InkWell(onTap: () => onRowTap!(i), child: row);
      },
    );
  }
}

class _TeamCell extends StatelessWidget {
  final int declarationPoints;
  final int trickPoints;
  final int runningTotal;
  final bool changedThisHand;

  const _TeamCell({
    required this.declarationPoints,
    required this.trickPoints,
    required this.runningTotal,
    required this.changedThisHand,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            declarationPoints > 0 ? '$declarationPoints' : '–',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            trickPoints > 0 ? '$trickPoints' : '–',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            changedThisHand ? '$runningTotal' : '–',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _BidCell extends StatelessWidget {
  final ScoreRow row;

  const _BidCell({required this.row});

  @override
  Widget build(BuildContext context) {
    final color = row.contractMade ? Colors.white : Colors.redAccent.shade100;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SuitIcon(row.trumpSuit, size: 15, color: color),
        const SizedBox(height: 2),
        Text(
          row.isCapot ? 'ΚΑΠΟ' : '${row.biddingValue ~/ 10}',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            decoration: row.contractMade ? null : TextDecoration.lineThrough,
            decorationColor: color,
            decorationThickness: 2,
          ),
        ),
      ],
    );
  }
}
