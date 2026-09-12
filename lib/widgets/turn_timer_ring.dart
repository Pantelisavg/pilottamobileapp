import 'package:flutter/material.dart';

/// A cosmetic, non-enforcing per-turn countdown ring: purely a visual pace
/// cue for networked play (nobody is auto-played or kicked when it runs
/// out — there is no server-side timeout). Give it a [turnKey] that
/// changes exactly when a new turn starts (e.g. combining the acting seat
/// with something that changes as they act) so Flutter recreates the
/// underlying animation and restarts the countdown; the same key across
/// rebuilds keeps it running smoothly instead of jumping back to full.
class TurnTimerRing extends StatelessWidget {
  final bool active;
  final double size;
  final Duration duration;

  const TurnTimerRing({
    super.key,
    required this.active,
    this.size = 22,
    this.duration = const Duration(seconds: 20),
  });

  @override
  Widget build(BuildContext context) {
    if (!active) return SizedBox(width: size, height: size);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 0.0),
        duration: duration,
        builder: (context, value, _) {
          return CircularProgressIndicator(
            value: value,
            strokeWidth: 2.5,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(value < 0.25 ? Colors.redAccent : Colors.amberAccent),
          );
        },
      ),
    );
  }
}
