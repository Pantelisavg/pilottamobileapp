import 'package:flutter/material.dart';

import '../theme/pilotta_colors.dart';

/// A circular "portrait" for a seat — since there are no real player
/// photos, a tinted wood-toned disc with a person/bot glyph stands in for
/// one, with a gold ring when it's that seat's turn and a small badge for
/// partner/disconnected status. Paired with [label] (the seat name) and
/// [cardCount] underneath.
class PlayerAvatar extends StatefulWidget {
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
  State<PlayerAvatar> createState() => _PlayerAvatarState();
}

class _PlayerAvatarState extends State<PlayerAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PlayerAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = widget.isActive
        ? PilottaColors.gold500
        : (widget.isPartner ? Colors.lightGreenAccent : Colors.white24);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (widget.timerOverlay != null)
              SizedBox(
                  width: widget.size + 10,
                  height: widget.size + 10,
                  child: widget.timerOverlay),
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                // A slow glow pulse draws the eye to whoever's turn it is,
                // rather than a fixed-intensity ring that's easy to miss
                // at a glance.
                final glowAlpha = 0.4 + _pulse.value * 0.35;
                final blurRadius = 10 + _pulse.value * 10;
                return Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [PilottaColors.wood600, PilottaColors.wood800],
                    ),
                    border: Border.all(
                        color: ringColor, width: widget.isActive ? 3 : 2),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                                color: PilottaColors.gold500
                                    .withValues(alpha: glowAlpha),
                                blurRadius: blurRadius),
                          ]
                        : null,
                  ),
                  child: child,
                );
              },
              child: Icon(
                widget.isBot ? Icons.smart_toy_outlined : Icons.person,
                color: Colors.white70,
                size: widget.size * 0.52,
              ),
            ),
            if (widget.disconnected)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                      color: PilottaColors.felt900, shape: BoxShape.circle),
                  child: const Icon(Icons.wifi_off,
                      color: Colors.orangeAccent, size: 14),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(widget.label,
            style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight:
                    widget.isActive ? FontWeight.bold : FontWeight.normal)),
        Text('${widget.cardCount} φύλλα',
            style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    );
  }
}
