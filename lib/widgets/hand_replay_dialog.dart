import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:provider/provider.dart';

import '../settings/app_settings.dart';
import '../theme/pilotta_colors.dart';
import 'pilotta_dialog.dart';
import 'playing_card_widget.dart';
import 'seat_layout.dart';
import 'suit_icon.dart';
import 'table/auction_rounds_grid.dart';
import 'table/oval_geometry.dart';

/// Opens a step-through replay of every trick in [result] — one full
/// completed hand from the scoreboard's history, not just the most recent
/// trick (see [showLastTrickDialog] for that, still used during live play).
void showHandReplayDialog(
  BuildContext context, {
  required HandResult result,
  required Seat viewerSeat,
  required int handNumber,
}) {
  showPilottaDialog<void>(
    context,
    builder: (context) => _HandReplayDialog(
      result: result,
      viewerSeat: viewerSeat,
      handNumber: handNumber,
    ),
  );
}

class _HandReplayDialog extends StatefulWidget {
  final HandResult result;
  final Seat viewerSeat;
  final int handNumber;

  const _HandReplayDialog({
    required this.result,
    required this.viewerSeat,
    required this.handNumber,
  });

  @override
  State<_HandReplayDialog> createState() => _HandReplayDialogState();
}

class _HandReplayDialogState extends State<_HandReplayDialog> {
  // Tricks are shown oldest-first, but a replay is most often opened to
  // check how the hand ended, so start on the last one.
  late int _trickIndex = widget.result.tricks.length - 1;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final trick = result.tricks[_trickIndex];
    final contract = result.contract;
    final deckStyle = context.watch<AppSettings>().deckStyle;

    return Dialog(
      backgroundColor: PilottaColors.felt800,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Χέρι ${widget.handNumber}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${contract.isCapot ? 'Καπό' : contract.value ~/ 10} ',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
                  SuitIcon(contract.trumpSuit, size: 14, color: Colors.white70),
                  Text(
                      ' — ${seatLabelRelativeTo(contract.biddingSeat, widget.viewerSeat)}'
                      '${result.contractMade ? '' : ' (απέτυχε)'}',
                      style: TextStyle(
                          color: result.contractMade
                              ? Colors.white70
                              : Colors.redAccent.shade100,
                          fontSize: 13)),
                ],
              ),
              if (result.auctionCalls.isNotEmpty)
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    iconColor: Colors.white70,
                    collapsedIconColor: Colors.white70,
                    title: const Text('Πώς πήγαν οι δηλώσεις',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    children: [
                      SizedBox(
                        width: 240,
                        child: AuctionRoundsGrid(
                          calls: result.auctionCalls,
                          viewerSeat: widget.viewerSeat,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: 240,
                height: 220,
                child: Stack(
                  children: [
                    for (final entry in trick.played)
                      Align(
                        alignment:
                            ovalSeatAlignment(entry.seat, widget.viewerSeat),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                seatLabelRelativeTo(
                                    entry.seat, widget.viewerSeat),
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 10)),
                            const SizedBox(height: 2),
                            PlayingCardWidget(
                                card: entry.card, width: 52, style: deckStyle),
                            if (entry.seat == trick.winner)
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
              const SizedBox(height: 8),
              Text(
                  'Μπάζα ${_trickIndex + 1}/${result.tricks.length} — Κέρδισε: '
                  '${seatLabelRelativeTo(trick.winner, widget.viewerSeat)}',
                  style:
                      const TextStyle(color: Colors.amberAccent, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Προηγούμενη μπάζα',
                    onPressed: _trickIndex > 0
                        ? () => setState(() => _trickIndex--)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    tooltip: 'Επόμενη μπάζα',
                    onPressed: _trickIndex < result.tricks.length - 1
                        ? () => setState(() => _trickIndex++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
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
}
