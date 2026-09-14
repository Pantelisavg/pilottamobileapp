import 'package:flutter/material.dart';

import '../../screens/how_to_play_screen.dart';

/// Opens the rules/scoring reference on top of the table — meant for
/// checking a rule mid-match without leaving the game (pops right back).
class CheatSheetButton extends StatelessWidget {
  const CheatSheetButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_book_outlined),
      tooltip: 'Πώς παίζεται',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
      ),
    );
  }
}
