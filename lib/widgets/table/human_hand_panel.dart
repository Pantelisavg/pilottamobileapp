import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/app_settings.dart';
import '../../settings/sound.dart';
import '../../theme/pilotta_colors.dart';
import '../fanned_hand.dart';
import '../hand_sort.dart';
import '../illegal_reason.dart';
import 'game_table_data.dart';
import 'hand_sort_toggle_button.dart';
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
    final sorted = sortedForHand(cards, ascending: settings.handAscending);

    // Landscape-locked app: height is the scarce dimension, so this panel
    // (and the bidding panel below it, when shown) trims itself further on
    // a short-height device rather than risking a vertical overflow — a
    // small further shrink to the card size buys back real pixels here.
    final compact = MediaQuery.sizeOf(context).height < 380;
    final cardScale = settings.cardScale * (compact ? 0.8 : 1.0);

    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 4 : 8, horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [PilottaColors.felt900, PilottaColors.felt800],
        ),
        border: Border(
          top: BorderSide(
              color: PilottaColors.gold500.withValues(alpha: 0.25), width: 1),
        ),
        boxShadow: [
          BoxShadow(
              color: PilottaColors.felt900.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(errorText!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                ),
              TurnGuidanceBanner(controller: controller),
              ThrowAllButton(controller: controller),
              FannedHand(
                cards: sorted,
                legal: legal,
                isMyTurn: isMyTurn,
                cardScale: cardScale,
                deckStyle: settings.deckStyle,
                reasonFor: (card) => trick != null
                    ? illegalPlayReason(trick, cards, card)
                    : null,
                onTap: (card) {
                  playTapSound(context.read<AppSettings>());
                  controller.playCard(card);
                },
              ),
            ],
          ),
          const Positioned(top: 0, right: 0, child: HandSortToggleButton()),
        ],
      ),
    );
  }
}
