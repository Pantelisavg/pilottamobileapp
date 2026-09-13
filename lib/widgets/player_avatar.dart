import 'package:flutter/material.dart';

import '../theme/pilotta_colors.dart';

/// A circular "portrait" for a seat — since there are no real player
/// photos, a tinted wood-toned disc with a person/bot glyph stands in for
/// one, with a gold ring when it's that seat's turn and a small badge for
/// partner/disconnected status. Paired with [label] (the seat name) and
/// [cardCount] underneath.
class PlayerAvatar extends StatelessWidget {
  final String label;
  final int cardCount;
  final bool isActive;
  final bool isPartner;
  final bool isBot;
  final bool disconnected;
  final double size;

  /// An optional ring drawn around the portrait, matching its size —
  /// used for the online mode's cosmetic per-turn countdown.
  final Widget? timerOverlay;

  const PlayerAvatar({
    super.key,
    required this.label,
    required this.cardCount,
    this.isActive = false,
    this.isPartner = false,
    this.isBot = false,
    this.disconnected = false,
    this.size = 56,
    this.timerOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor =
        isActive ? PilottaColors.gold500 : (isPartner ? Colors.lightGreenAccent : Colors.white24);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (timerOverlay != null) SizedBox(width: size + 10, height: size + 10, child: timerOverlay),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [PilottaColors.wood600, PilottaColors.wood800],
                ),
                border: Border.all(color: ringColor, width: isActive ? 3 : 2),
                boxShadow: isActive
                    ? [BoxShadow(color: PilottaColors.gold500.withValues(alpha: 0.55), blurRadius: 14)]
                    : null,
              ),
              child: Icon(
                isBot ? Icons.smart_toy_outlined : Icons.person,
                color: Colors.white70,
                size: size * 0.52,
              ),
            ),
            if (disconnected)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: PilottaColors.felt900, shape: BoxShape.circle),
                  child: const Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 14),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        Text('$cardCount φύλλα', style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    );
  }
}
