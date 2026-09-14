import 'package:flutter/material.dart';

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
      color: Colors.indigo.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              canAnnounce
                  ? 'Έχεις $label — δήλωσέ το τώρα!'
                  : 'Αποκάλυψε τη δήλωσή σου πριν παίξεις, αλλιώς χάνεται!',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            // Overrides the theme's full-width (Size.fromHeight) minimumSize,
            // which forces an infinite width crash for a button placed next
            // to something else in a Row instead of alone in a Column.
            style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
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
