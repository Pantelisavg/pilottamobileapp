import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/app_settings.dart';
import '../../theme/pilotta_colors.dart';
import '../last_trick_dialog.dart';
import '../playing_card_widget.dart';
import 'game_table_data.dart';

/// A small always-visible preview of the most recently completed trick —
/// no more tapping an icon just to check who won the last one. Tapping the
/// panel still opens [showLastTrickDialog] for the bigger, positioned view.
class LastTrickMiniPanel extends StatelessWidget {
  final GameTableData controller;
  const LastTrickMiniPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final played = controller.lastCompletedTrickPlayed;
    if (played == null) return const SizedBox.shrink();

    final winner = controller.lastCompletedTrickWinner;
    final wonByMe = winner != null && winner.team == controller.viewerSeat.team;
    final deckStyle = context.watch<AppSettings>().deckStyle;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => showLastTrickDialog(
        context,
        played: played,
        winner: winner,
        viewerSeat: controller.viewerSeat,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: PilottaColors.felt800.withValues(alpha: 0.93),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: wonByMe ? PilottaColors.success500 : PilottaColors.felt600,
          ),
          boxShadow: PilottaColors.shadowResting,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Προηγούμενη μπάζα',
                style: TextStyle(color: PilottaColors.ink400, fontSize: 8)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in played)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: PlayingCardWidget(
                        card: entry.card, width: 20, style: deckStyle),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
