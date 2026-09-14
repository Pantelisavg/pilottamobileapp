import 'package:flutter/material.dart';

import '../../theme/pilotta_colors.dart';
import 'game_table_data.dart';

/// The "you have a declaration — announce/reveal it" bar — shared
/// replacement for local's `_DeclarationPanel` and online's
/// `_OnlineDeclarationPanel`.
class DeclarationPanel extends StatelessWidget {
  final GameTableData controller;
  const DeclarationPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final label = controller.myBestDeclarationLabel;
    if (label == null) return const SizedBox.shrink();

    final canAnnounce = controller.canAnnounceDeclaration;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [PilottaColors.gold700, PilottaColors.gold500],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              canAnnounce
                  ? 'Έχεις $label — δήλωσέ το τώρα!'
                  : 'Αποκάλυψε τη δήλωσή σου πριν παίξεις, αλλιώς χάνεται!',
              style: const TextStyle(
                  color: PilottaColors.ink900,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            // Overrides the theme's full-width (Size.fromHeight) minimumSize,
            // which forces an infinite width crash for a button placed next
            // to something else in a Row instead of alone in a Column. Also
            // swaps the theme's default gold-on-ink button for felt-on-gold,
            // since a gold button would disappear against this gold banner.
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 40),
              backgroundColor: PilottaColors.felt900,
              foregroundColor: PilottaColors.gold300,
            ),
            onPressed: canAnnounce
                ? controller.announceDeclaration
                : controller.revealDeclaration,
            child: Text(canAnnounce ? 'Δήλωσε' : 'Αποκάλυψε'),
          ),
        ],
      ),
    );
  }
}
