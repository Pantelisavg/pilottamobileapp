import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import '../theme/pilotta_colors.dart';
import 'playing_card_widget.dart';
import 'seat_layout.dart';
import 'table/oval_geometry.dart';

/// Shows the previous completed trick's 4 cards (positioned relative to
/// [viewerSeat], same layout as the live trick area) plus who won it.
void showLastTrickDialog(
  BuildContext context, {
  required List<({Seat seat, PlayingCard card})> played,
  required Seat? winner,
  required Seat viewerSeat,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: PilottaColors.felt800,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Προηγούμενη μπάζα',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: 220,
              height: 200,
              child: Stack(
                children: [
                  for (final entry in played)
                    Align(
                      alignment: ovalSeatAlignment(entry.seat, viewerSeat),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PlayingCardWidget(card: entry.card, width: 52),
                          if (entry.seat == winner)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Icon(Icons.emoji_events,
                                  color: Colors.amber, size: 16),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (winner != null)
              Text('Κέρδισε: ${seatLabelRelativeTo(winner, viewerSeat)}',
                  style:
                      const TextStyle(color: Colors.amberAccent, fontSize: 13)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Κλείσιμο'),
            ),
          ],
        ),
      ),
    ),
  );
}
