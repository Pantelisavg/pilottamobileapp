import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

import '../../theme/pilotta_colors.dart';
import '../auction_history_dialog.dart';
import '../seat_layout.dart';
import 'auction_status_panel.dart';
import 'game_table_data.dart';
import 'last_trick_mini_panel.dart';
import 'opponent_seat.dart';
import 'oval_geometry.dart';
import 'trick_area.dart';
import 'trick_trump_badge.dart';

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
        Positioned.fill(
          child: CustomPaint(painter: _TableFeltPainter()),
        ),
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
        if (controller.phase == RoomPhase.playing)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(child: TrickTrumpBadge(controller: controller)),
          ),
        if (controller.phase == RoomPhase.playing &&
            controller.lastCompletedTrickPlayed != null)
          Positioned(
            top: 0,
            left: 0,
            child: LastTrickMiniPanel(controller: controller),
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

/// The felt oval itself — a soft radial highlight (as if lit from above)
/// inside a thin gold rim, inset from the full rectangular table area so
/// it reads as an object sitting on the surface rather than the surface
/// itself.
class _TableFeltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ovalRect = rect.deflate(size.shortestSide * 0.04);

    final fillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 0.9,
        colors: [PilottaColors.felt700, PilottaColors.felt900],
      ).createShader(ovalRect);
    canvas.drawOval(ovalRect, fillPaint);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = const LinearGradient(
        colors: [
          PilottaColors.gold700,
          PilottaColors.gold300,
          PilottaColors.gold700
        ],
      ).createShader(ovalRect);
    canvas.drawOval(ovalRect.deflate(1.5), rimPaint);
  }

  @override
  bool shouldRepaint(covariant _TableFeltPainter oldDelegate) => false;
}
