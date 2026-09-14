import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import '../declaration_label.dart';
import '../seat_layout.dart';
import '../suit_icon.dart';
import 'game_table_data.dart';

/// The score breakdown shown between hands — shared replacement for
/// local's `_HandSummaryOverlay` and online's `_OnlineHandSummaryOverlay`.
///
/// The online version had drifted slightly from local's (it never showed
/// the Belote/Rebelote row) purely because it was built by hand-decoding
/// JSON separately — now that both read the same [HandResult] via
/// [GameTableData.lastHandResult], that gap is closed as a side effect.
class HandSummaryOverlay extends StatelessWidget {
  final GameTableData controller;
  const HandSummaryOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final result = controller.lastHandResult!;
    final ourTeam = controller.viewerSeat.team;
    final contract = result.contract;
    final iAmReady = controller.viewerIsReadyForNextHand;

    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result.contractMade ? 'Το συμβόλαιο βγήκε' : 'Μέσα!',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${contract.isCapot ? 'Καπό' : contract.value} ',
                      style: const TextStyle(fontSize: 14)),
                  SuitIcon(contract.trumpSuit, size: 16),
                  Text(
                      ' — ${seatLabelRelativeTo(contract.biddingSeat, controller.viewerSeat)}',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
              const Divider(height: 24),
              _row('Πόντοι φύλλων',
                  '${result.trickPoints[ourTeam]} – ${result.trickPoints[ourTeam.opponent]}'),
              if (result.declarations.winningTeam != null)
                _row(
                  'Δηλώσεις',
                  result.declarations.winningTeam == ourTeam
                      ? '${result.declarations.winningTeamPoints} – 0'
                      : '0 – ${result.declarations.winningTeamPoints}',
                ),
              if (result.declarations.beloteSeat != null)
                _row(
                    'Μπελότ-Ρεμπελότ',
                    result.declarations.beloteSeat!.team == ourTeam
                        ? '20 – 0'
                        : '0 – 20'),
              for (final entry in result.declarations.forfeitedPerSeat.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${seatLabelRelativeTo(entry.key, controller.viewerSeat)} ξέχασε να αποκαλύψει: '
                    '${declarationPointsLabel(entry.value)} (χαμένο)',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.redAccent),
                  ),
                ),
              _row('Σύνολο',
                  '${result.rawTotals[ourTeam]} – ${result.rawTotals[ourTeam.opponent]}'),
              const Divider(height: 24),
              _row(
                'Βαθμολογία γύρου',
                '${ourTeam == Team.northSouth ? result.rounded.northSouth : result.rounded.eastWest}'
                    ' – '
                    '${ourTeam == Team.northSouth ? result.rounded.eastWest : result.rounded.northSouth}',
                bold: true,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: iAmReady ? null : controller.continueAfterHand,
                child: Text(iAmReady
                    ? 'Περιμένουμε τους άλλους...'
                    : 'Επόμενη μοιρασιά'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style =
        TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
