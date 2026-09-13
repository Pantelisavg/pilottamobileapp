import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import 'suit_icon.dart';

/// One row of the paper-style scoreboard: a single hand's contract and its
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

  const ScoreRow({
    required this.index,
    required this.trumpSuit,
    required this.isCapot,
    required this.biddingValue,
    required this.biddingSeatLabel,
    required this.contractMade,
    required this.roundedMine,
    required this.roundedTheirs,
  });
}

/// A scrollable "tally sheet" of every hand played so far this match, plus
/// the running total — a bottom sheet so it can be dismissed with a swipe,
/// matching how a physical scoresheet is something you glance at, not a
/// full navigation destination.
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Σκορ (στόχος $targetScore)',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: rows.isEmpty
                ? const Center(
                    child: Text('Δεν έχει παιχτεί ακόμα καμία μοιρασιά.',
                        style: TextStyle(color: Colors.white54)),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white12, height: 1),
                    itemBuilder: (context, i) {
                      final r = rows[rows.length - 1 - i]; // most recent first
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: Text('${r.index}',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 12)),
                            ),
                            SuitIcon(r.trumpSuit,
                                size: 16, color: Colors.white70),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${r.isCapot ? "Καπό" : r.biddingValue} — ${r.biddingSeatLabel}'
                                '${r.contractMade ? "" : " (απέτυχε)"}',
                                style: TextStyle(
                                  color: r.contractMade
                                      ? Colors.white
                                      : Colors.redAccent.shade100,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text('${r.roundedMine} – ${r.roundedTheirs}',
                                style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
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
