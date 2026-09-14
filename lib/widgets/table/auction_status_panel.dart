import 'package:flutter/material.dart';

import '../../theme/pilotta_colors.dart';
import '../../theme/pilotta_spacing.dart';
import '../seat_layout.dart';
import '../suit_icon.dart';
import 'auction_rounds_grid.dart';
import 'game_table_data.dart';

/// The live "how's the bidding going" panel shown during the auction —
/// shared replacement for local's `_AuctionStatus` and online's
/// `_OnlineAuctionStatus`, both of which read the exact same [Auction]
/// shape, just from two different controllers.
class AuctionStatusPanel extends StatelessWidget {
  final GameTableData controller;
  const AuctionStatusPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final auction = controller.auction;
    if (auction == null) return const SizedBox.shrink();
    final bid = auction.currentBid;
    final me = controller.viewerSeat;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PilottaColors.felt800.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(PilottaRadius.lg),
        border:
            Border.all(color: PilottaColors.gold500.withValues(alpha: 0.35)),
        boxShadow: PilottaColors.shadowRaised,
      ),
      // SingleChildScrollView clamps to whatever height the Align/Stack
      // above actually has available and scrolls instead of overflowing —
      // on a short screen with the bidding panel also showing, this panel
      // (bid status + history) can be taller than the space left for it.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Δηλώσεις',
                style: TextStyle(color: PilottaColors.ink200, fontSize: 12)),
            const SizedBox(height: 6),
            if (bid == null)
              const Text('Καμία δήλωση ακόμα',
                  style: TextStyle(
                      color: PilottaColors.ink50,
                      fontSize: 16,
                      fontWeight: FontWeight.bold))
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${bid.isCapot ? 'Καπό' : bid.value} ',
                      style: const TextStyle(
                          color: PilottaColors.ink50,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  SuitIcon(bid.suit, size: 18, color: PilottaColors.ink50),
                  Text(' — ${seatLabelRelativeTo(bid.seat, me)}',
                      style: const TextStyle(
                          color: PilottaColors.ink50,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            const SizedBox(height: 6),
            Text('Σειρά: ${seatLabelRelativeTo(auction.seatToAct, me)}',
                style: const TextStyle(
                    color: PilottaColors.gold300, fontSize: 12)),
            if (auction.calls.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: PilottaColors.felt600),
              const SizedBox(height: 6),
              SizedBox(
                width: 240,
                child: AuctionRoundsGrid(calls: auction.calls, viewerSeat: me),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
