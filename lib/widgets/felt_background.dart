import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/pilotta_colors.dart';

/// The base "table" backdrop: a warm near-black felt with a soft amber
/// glow overhead (as if lit by a single lamp over a tavern card table) and
/// a faint procedural grain instead of a flat fill — a flat single-color
/// background reads as generic app chrome, while this reads as a surface
/// with lighting and a bit of tooth to it.
class FeltBackground extends StatelessWidget {
  final Widget child;

  const FeltBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.35),
          radius: 1.3,
          colors: [PilottaColors.felt700, PilottaColors.felt900],
          stops: [0, 1],
        ),
      ),
      child: Stack(
        children: [
          // A warm lamplight glow, distinct from (and on top of) the green
          // radial above — this is what reads as "lit from a single warm
          // source" rather than just "lighter in the middle."
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.45),
                  radius: 0.9,
                  colors: [Color(0x22D9A94E), Color(0x00D9A94E)],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _GrainPainter())),
          child,
        ],
      ),
    );
  }
}

/// A faint, deterministic speckle of darker/lighter dots — cheap
/// procedural "felt grain" texture with no image asset, so a close-up on
/// the background doesn't read as a perfectly smooth gradient.
class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7);
    final dark = Paint()..color = PilottaColors.felt900.withValues(alpha: 0.25);
    final light = Paint()
      ..color = PilottaColors.gold300.withValues(alpha: 0.04);
    // A fixed dot count scaled to area, not a per-pixel loop, keeps this
    // cheap regardless of screen size.
    final count = (size.width * size.height / 900).clamp(200, 2200).round();
    for (var i = 0; i < count; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 0.9 + 0.3;
      canvas.drawCircle(Offset(dx, dy), r, rng.nextBool() ? dark : light);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) => false;
}
