import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/app_settings.dart';
import '../../settings/sound.dart';
import '../fanned_hand.dart';
import '../hand_sort.dart';
import '../illegal_reason.dart';
import 'game_table_data.dart';
import 'throw_all_button.dart';
import 'turn_guidance_banner.dart';

/// The viewer's own hand, fanned out with legal plays highlighted — shared
/// replacement for local's `_HumanHand` and online's `_OnlineHumanHand`.
///
/// [errorText], when non-null, shows above the hand — used online for the
/// rare "server rejected that play" case (local play always accepts a
/// legal card immediately, so it never has anything to show here).
class HumanHandPanel extends StatelessWidget {
  final GameTableData controller;
  final String? errorText;

  const HumanHandPanel({
    super.key,
    required this.controller,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final cards = controller.myHand;
    final legal = controller.viewerLegalPlays.toSet();
    final isMyTurn = controller.isViewerTurnToPlay;
    final trick = controller.currentTrick;
    final settings = context.watch<AppSettings>();
    final cardScale = settings.cardScale;
    final sorted = sortedForHand(cards, ascending: settings.handAscending);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: const Color(0xFF082A20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(errorText!,
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          TurnGuidanceBanner(controller: controller),
          ThrowAllButton(controller: controller),
          FannedHand(
            cards: sorted,
            legal: legal,
            isMyTurn: isMyTurn,
            cardScale: cardScale,
            reasonFor: (card) =>
                trick != null ? illegalPlayReason(trick, cards, card) : null,
            onTap: (card) {
              playTapSound(context.read<AppSettings>());
              controller.playCard(card);
            },
          ),
        ],
      ),
    );
  }
}
