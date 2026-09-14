import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import '../auction_call_label.dart';
import '../seat_layout.dart';

/// Groups a flat, strictly turn-ordered call log into rounds — one map per
/// trip around the table, keyed by seat. [Auction] always asks every seat
/// in turn every round regardless of pass/bid (see
/// `Auction.apply`/`Auction._currentSeat`), so a "new round" is simply
/// detected as the same seat calling again; the final round may be
/// incomplete (fewer than 4 entries) if the auction ended partway through
/// it, which this naturally handles without needing to assume exactly 4
/// calls per round.
List<Map<Seat, AuctionCall>> groupCallsIntoRounds(List<AuctionCall> calls) {
  final rounds = <Map<Seat, AuctionCall>>[];
  var current = <Seat, AuctionCall>{};
  for (final call in calls) {
    if (current.containsKey(call.seat)) {
      rounds.add(current);
      current = {};
    }
    current[call.seat] = call;
  }
  if (current.isNotEmpty) rounds.add(current);
  return rounds;
}

/// A table of the whole auction: one row per round, one column per seat
/// (in a fixed order relative to [viewerSeat] — self, right, partner,
/// left — so the grid always reads the same way regardless of who
/// actually opened the bidding), each cell showing that seat's call for
/// that round. More scannable than a flat chronological list once there
/// have been more than a handful of calls.
class AuctionRoundsGrid extends StatelessWidget {
  final List<AuctionCall> calls;
  final Seat viewerSeat;

  const AuctionRoundsGrid({
    super.key,
    required this.calls,
    required this.viewerSeat,
  });

  @override
  Widget build(BuildContext context) {
    final rounds = groupCallsIntoRounds(calls);
    final columns = [
      viewerSeat,
      viewerSeat.next,
      viewerSeat.partner,
      viewerSeat.next.partner,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final seat in columns)
              Expanded(
                child: Text(
                  seatLabelRelativeTo(seat, viewerSeat),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        for (var r = 0; r < rounds.length; r++) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(height: 1, color: Colors.white24),
          ),
          Text('ΓΥΡΟΣ ${r + 1}',
              style: const TextStyle(color: Colors.white38, fontSize: 9)),
          const SizedBox(height: 2),
          Row(
            children: [
              for (final seat in columns)
                Expanded(
                  child: Center(
                    child: rounds[r][seat] == null
                        ? const Text('–',
                            style:
                                TextStyle(color: Colors.white24, fontSize: 12))
                        : auctionCallLabel(rounds[r][seat]!, '', fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
