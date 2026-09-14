import 'package:flutter/material.dart';

import 'game_table_data.dart';

/// The final win/loss screen — shared replacement for local's
/// `_MatchOverOverlay` and online's `_OnlineMatchOverOverlay`.
class MatchOverOverlay extends StatelessWidget {
  final GameTableData controller;
  const MatchOverOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final ourTeam = controller.viewerSeat.team;
    final weWon = controller.matchWinner == ourTeam;

    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(weWon ? 'Κερδίσατε!' : 'Χάσατε',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              '${controller.totals[ourTeam]} – ${controller.totals[ourTeam.opponent]}',
              style: const TextStyle(color: Colors.white70, fontSize: 20)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Πίσω στο μενού'),
          ),
        ],
      ),
    );
  }
}
