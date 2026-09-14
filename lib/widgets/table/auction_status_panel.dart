import 'package:flutter/material.dart';

import '../auction_call_label.dart';
import '../seat_layout.dart';
import '../suit_icon.dart';
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
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
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
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            if (bid == null)
              const Text('Καμία δήλωση ακόμα',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold))
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${bid.isCapot ? 'Καπό' : bid.value} ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  SuitIcon(bid.suit, size: 18, color: Colors.white),
                  Text(' — ${seatLabelRelativeTo(bid.seat, me)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            const SizedBox(height: 6),
            Text('Σειρά: ${seatLabelRelativeTo(auction.seatToAct, me)}',
                style:
                    const TextStyle(color: Colors.amberAccent, fontSize: 12)),
            if (auction.calls.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: Colors.white24),
              const SizedBox(height: 6),
              // Capped to the most recent few calls — a plain, unscrolled
              // list so its height is always small and bounded, whatever
              // Align/Stack above happens to have room for.
              for (final call
                  in auction.calls.reversed.take(5).toList().reversed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: auctionCallLabel(
                        call, seatLabelRelativeTo(call.seat, me)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
