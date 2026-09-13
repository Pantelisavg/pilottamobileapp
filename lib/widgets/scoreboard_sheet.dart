import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

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
  });
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
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0E3428),
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
                : _Ledger(rows: rows, scrollController: scrollController),
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

  const _Ledger({required this.rows, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    var runningMine = 0;
    var runningTheirs = 0;

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) =>
          const Divider(color: Colors.white12, height: 1),
      itemBuilder: (context, i) {
        final r = rows[i];
        runningMine += r.roundedMine;
        runningTheirs += r.roundedTheirs;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: _TeamCell(
                  declarationPoints: r.declarationPointsMine,
                  runningTotal: runningMine,
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
                  runningTotal: runningTheirs,
                  changedThisHand: r.roundedTheirs != 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TeamCell extends StatelessWidget {
  final int declarationPoints;
  final int runningTotal;
  final bool changedThisHand;

  const _TeamCell({
    required this.declarationPoints,
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
