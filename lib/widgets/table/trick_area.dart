import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:provider/provider.dart';

import '../../settings/app_settings.dart';
import '../playing_card_widget.dart';
import 'game_table_data.dart';
import 'oval_geometry.dart';

/// The cards played so far in the current trick, positioned around the
/// table — shared replacement for local's `_TrickArea` and online's
/// `_OnlineTrickArea`, both of which reconstructed the same thing from a
/// [Trick] (local's live, online's decoded from the snapshot).
class TrickArea extends StatelessWidget {
  final GameTableData controller;
  const TrickArea({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final trick = controller.currentTrick;
    if (trick == null) return const SizedBox.shrink();

    final played = {for (final e in trick.played) e.seat: e.card};
    final settings = context.watch<AppSettings>();
    final cardScale = settings.cardScale;

    return SizedBox(
      width: 260,
      height: 240,
      child: Stack(
        children: [
          for (final seat in Seat.values)
            if (played[seat] != null)
              Align(
                alignment: ovalSeatAlignment(seat, controller.viewerSeat),
                child: PlayingCardWidget(
                    card: played[seat],
                    width: 68 * cardScale,
                    style: settings.deckStyle),
              ),
        ],
      ),
    );
  }
}
