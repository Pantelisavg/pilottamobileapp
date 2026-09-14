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

    // Same landscape-locked, height-is-scarce reasoning as the bidding
    // panel below it — a compact tier keeps this panel's own natural
    // height down, so on a short device it's less likely to ever need to
    // fall back on the SingleChildScrollView below.
    final compact = MediaQuery.sizeOf(context).height < 380;
    final valueFontSize = compact ? 14.0 : 16.0;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16, vertical: compact ? 8 : 12),
      decoration: BoxDecoration(
        color: PilottaColors.felt800.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(PilottaRadius.lg),
        border:
            Border.all(color: PilottaColors.gold500.withValues(alpha: 0.35)),
        boxShadow: PilottaColors.shadowRaised,
      ),
      // The parent (OvalTableArea) now passes this panel a real, explicit
      // maxHeight via ConstrainedBox — so on a short screen where even the
      // compact tier's content is still too tall, this actually scrolls
      // instead of overflowing past the space reserved for it.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Δηλώσεις',
                style: TextStyle(
                    color: PilottaColors.ink200, fontSize: compact ? 11 : 12)),
            SizedBox(height: compact ? 4 : 6),
            if (bid == null)
              Text('Καμία δήλωση ακόμα',
                  style: TextStyle(
                      color: PilottaColors.ink50,
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold))
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${bid.isCapot ? 'Καπό' : bid.value} ',
                      style: TextStyle(
                          color: PilottaColors.ink50,
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.bold)),
                  SuitIcon(bid.suit,
                      size: compact ? 15 : 18, color: PilottaColors.ink50),
                  Text(' — ${seatLabelRelativeTo(bid.seat, me)}',
                      style: TextStyle(
                          color: PilottaColors.ink50,
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            SizedBox(height: compact ? 4 : 6),
            Text('Σειρά: ${seatLabelRelativeTo(auction.seatToAct, me)}',
                style: TextStyle(
                    color: PilottaColors.gold300, fontSize: compact ? 11 : 12)),
            if (auction.calls.isNotEmpty) ...[
              SizedBox(height: compact ? 6 : 10),
              Divider(height: 1, color: PilottaColors.felt600),
              SizedBox(height: compact ? 4 : 6),
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
