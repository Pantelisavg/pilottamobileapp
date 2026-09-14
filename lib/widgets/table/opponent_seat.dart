import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:provider/provider.dart';

import '../../settings/app_settings.dart';
import '../../theme/pilotta_colors.dart';
import '../player_avatar.dart';
import '../playing_card_widget.dart';
import '../seat_layout.dart';
import 'game_table_data.dart';

/// One opponent's avatar, declaration status, and face-down card fan — the
/// shared replacement for local's `_OpponentSeat` and online's
/// `_OnlineOpponentSeat`, which drew the exact same thing from two
/// differently-shaped data sources.
///
/// [disconnected] and [timerOverlay] are optional, online-only extras (local
/// bots are never "disconnected" and have no turn timer) — everything else
/// comes uniformly from [controller].
class OpponentSeat extends StatelessWidget {
  final GameTableData controller;
  final Seat seat;
  final bool disconnected;
  final Widget? timerOverlay;

  const OpponentSeat({
    super.key,
    required this.controller,
    required this.seat,
    this.disconnected = false,
    this.timerOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = controller.seatToAct == seat;
    final cardCount = controller.handSizeOf(seat);
    final isPartner = seat == controller.viewerSeat.partner;
    final declState = controller.declarationStateOf(seat);
    final revealedLabel = controller.revealedDeclarationsLabelOf(seat);
    final deckStyle = context.watch<AppSettings>().deckStyle;

    return Padding(
      padding: const EdgeInsets.all(8),
      // The table area's height isn't divided into a fixed slot per seat —
      // an opponent's avatar+cards column can outgrow whatever's actually
      // left over once the bidding panel (or other overlays) claim their
      // share, especially on a small screen. Shrink to fit rather than
      // overflow, instead of trying to fix its natural size.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerAvatar(
              label: seatLabelRelativeTo(seat, controller.viewerSeat),
              cardCount: cardCount,
              isActive: isActive,
              isPartner: isPartner,
              isBot: controller.isBotControlled(seat),
              disconnected: disconnected,
              timerOverlay: timerOverlay,
            ),
            if (declState == DeclarationAnnounceState.announced)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text('Δήλωσε — αναμένεται αποκάλυψη',
                    style:
                        TextStyle(color: PilottaColors.gold300, fontSize: 9)),
              )
            else if (declState == DeclarationAnnounceState.revealed &&
                revealedLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(revealedLabel,
                    style: const TextStyle(
                        color: PilottaColors.success500, fontSize: 9)),
              ),
            const SizedBox(height: 4),
            SizedBox(
              height: 46,
              width: 92,
              child: Stack(
                children: [
                  for (var i = 0; i < cardCount; i++)
                    Positioned(
                      left: i * 9.0,
                      child: PlayingCardWidget(
                          faceUp: false, width: 30, style: deckStyle),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
