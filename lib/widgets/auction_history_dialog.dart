import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import '../theme/pilotta_colors.dart';
import 'auction_call_label.dart';

/// Shows the full auction sequence for the hand currently in play — every
/// call in order, each labelled with who made it. Since [Auction] stays put
/// on the room until the next hand's bidding starts (see
/// `PilottaRoom._startHand`), this is available throughout the whole
/// playing/hand-summary phase, not just right as bidding wraps up.
void showAuctionHistoryDialog(
  BuildContext context, {
  required List<AuctionCall> calls,
  required Seat viewerSeat,
  required String Function(Seat seat) seatLabel,
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
            const Text('Πώς πήγαν οι δηλώσεις',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final call in calls)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: auctionCallLabel(call, seatLabel(call.seat),
                            fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),
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
