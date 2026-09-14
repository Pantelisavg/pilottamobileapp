import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import '../suit_icon.dart';
import 'game_table_data.dart';

/// A one-line "what am I supposed to do" hint shown above the hand on the
/// viewer's turn to play — complements (doesn't replace) the existing
/// dim-illegal-cards + tooltip treatment in [FannedHand]/[illegalPlayReason]
/// with a single up-front sentence, e.g. "Ακολούθησε ♣" or "Η σειρά σου —
/// παίξε ό,τι θες".
class TurnGuidanceBanner extends StatelessWidget {
  final GameTableData controller;
  const TurnGuidanceBanner({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!controller.isViewerTurnToPlay) return const SizedBox.shrink();
    final trick = controller.currentTrick;
    if (trick == null) return const SizedBox.shrink();

    if (trick.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 4),
        child: Text('Η σειρά σου — παίξε ό,τι θες',
            style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
      );
    }

    final led = trick.ledSuit!;
    final hand = controller.myHand;
    final hasLed = hand.any((c) => c.suit == led);
    final hasTrump = hand.any((c) => c.suit == trick.trumpSuit);

    late final String text;
    late final Suit? suit;
    if (hasLed) {
      text = 'Ακολούθησε';
      suit = led;
    } else if (hasTrump && led != trick.trumpSuit) {
      text = 'Δεν έχεις — κόψε με ατού';
      suit = trick.trumpSuit;
    } else {
      text = 'Παίξε ό,τι θες';
      suit = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$text ',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
          if (suit != null) SuitIcon(suit, size: 13, color: Colors.amberAccent),
        ],
      ),
    );
  }
}
