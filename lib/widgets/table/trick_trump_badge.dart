import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import '../../theme/pilotta_colors.dart';
import '../suit_icon.dart';
import 'game_table_data.dart';

/// A small always-visible "Μπάζα x/8 · trump suit" badge shown during
/// play — the trick count is derived from how many cards have been played
/// in total (32 minus everyone's remaining hand size, floor-divided by 4),
/// which works identically for local (real [Trick] objects) and online
/// (JSON hand-size counts) without needing a dedicated counter on
/// [GameTableData].
class TrickTrumpBadge extends StatelessWidget {
  final GameTableData controller;
  const TrickTrumpBadge({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final contract = controller.contract;
    if (contract == null) return const SizedBox.shrink();

    final cardsPlayed = Seat.values
        .fold<int>(32, (sum, seat) => sum - controller.handSizeOf(seat));
    final completedTricks = (cardsPlayed ~/ 4).clamp(0, 8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: PilottaColors.felt800.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PilottaColors.gold500.withValues(alpha: 0.3)),
        boxShadow: PilottaColors.shadowResting,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Μπάζα $completedTricks/8',
              style:
                  const TextStyle(color: PilottaColors.ink200, fontSize: 11)),
          const SizedBox(width: 6),
          SuitIcon(contract.trumpSuit, size: 13, color: PilottaColors.ink200),
        ],
      ),
    );
  }
}
