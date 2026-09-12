import 'package:flutter/material.dart';

import 'pilotta_colors.dart';

/// The three ways a table can be played, each with its own accent color
/// and icon so a session's mode is identifiable at a glance — on the home
/// screen's menu, in a lobby, and in-game — without reading text. Chosen
/// deliberately outside the felt/gold palette (cool blue vs. warm orange)
/// so neither reads as "just another gold highlight."
enum GameModeAccent {
  localBots(
    color: PilottaColors.gold500,
    icon: Icons.smart_toy_outlined,
    label: 'ΤΟΠΙΚΑ',
  ),
  online(
    color: PilottaColors.infoOnline,
    icon: Icons.public,
    label: 'ONLINE',
  ),
  bluetooth(
    color: PilottaColors.localBluetooth,
    icon: Icons.bluetooth,
    label: 'BLUETOOTH',
  );

  final Color color;
  final IconData icon;
  final String label;

  const GameModeAccent({required this.color, required this.icon, required this.label});
}

/// A small pill badge identifying which mode a screen belongs to — e.g. in
/// a lobby or at the game table — so it's never ambiguous whether you're
/// looking at an online table or a local/Bluetooth one.
class ModeBadge extends StatelessWidget {
  final GameModeAccent mode;
  final bool dense;

  const ModeBadge({super.key, required this.mode, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: mode.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: mode.color.withValues(alpha: 0.55), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mode.icon, size: dense ? 12 : 14, color: mode.color),
          SizedBox(width: dense ? 4 : 6),
          Text(
            mode.label,
            style: TextStyle(
              fontSize: dense ? 9 : 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: mode.color,
            ),
          ),
        ],
      ),
    );
  }
}
