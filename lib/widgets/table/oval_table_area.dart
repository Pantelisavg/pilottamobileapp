import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

import '../auction_history_dialog.dart';
import '../last_trick_dialog.dart';
import '../seat_layout.dart';
import 'auction_status_panel.dart';
import 'game_table_data.dart';
import 'opponent_seat.dart';
import 'oval_geometry.dart';
import 'trick_area.dart';

/// The table itself: the 3 opponents positioned around an oval, the current
/// trick in the middle, the live auction panel while bidding, and the
/// peek-last-trick / how-the-bidding-went buttons during play — shared
/// replacement for local's `_TableArea` and online's `_OnlineTableArea`.
///
/// [opponentSeatBuilder], when given, replaces the default [OpponentSeat]
/// per seat — used online to add the disconnected badge and turn-timer
/// ring, neither of which has a local-play equivalent.
class OvalTableArea extends StatelessWidget {
  final GameTableData controller;
  final Widget Function(Seat seat)? opponentSeatBuilder;

  const OvalTableArea({
    super.key,
    required this.controller,
    this.opponentSeatBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final me = controller.viewerSeat;

    return Stack(
      children: [
        for (final seat in Seat.values)
          if (seat != me)
            Align(
              alignment: ovalSeatAlignment(seat, me),
              child: opponentSeatBuilder?.call(seat) ??
                  OpponentSeat(controller: controller, seat: seat),
            ),
        Center(child: TrickArea(controller: controller)),
        if (controller.phase == RoomPhase.bidding)
          Align(
            alignment: Alignment.center,
            child: AuctionStatusPanel(controller: controller),
          ),
        if (controller.phase == RoomPhase.playing &&
            controller.lastCompletedTrickPlayed != null)
          Positioned(
            top: 0,
            left: 0,
            child: IconButton(
              tooltip: 'Προηγούμενη μπάζα',
              icon: const Icon(Icons.history, color: Colors.white70),
              onPressed: () => showLastTrickDialog(
                context,
                played: controller.lastCompletedTrickPlayed!,
                winner: controller.lastCompletedTrickWinner,
                viewerSeat: me,
              ),
            ),
          ),
        if (controller.phase == RoomPhase.playing &&
            (controller.auction?.calls.isNotEmpty ?? false))
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              tooltip: 'Πώς πήγαν οι δηλώσεις',
              icon: const Icon(Icons.gavel, color: Colors.white70),
              onPressed: () => showAuctionHistoryDialog(
                context,
                calls: controller.auction!.calls,
                viewerSeat: me,
                seatLabel: (seat) => seatLabelRelativeTo(seat, me),
              ),
            ),
          ),
      ],
    );
  }
}
