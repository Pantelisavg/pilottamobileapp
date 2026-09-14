import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import '../settings/card_deck_style.dart';
import 'playing_card_widget.dart';

/// A hand card that, when [reason] is non-null (the card is currently
/// unplayable), shows a tooltip explaining why on long-press/hover —
/// shared between the local and networked game screens.
Widget buildHandCard({
  required PlayingCard card,
  required bool selectable,
  required bool dimmed,
  String? reason,
  required VoidCallback onTap,
  required double width,
  CardDeckStyle style = CardDeckStyle.classic,
}) {
  final widget = _PlayableHandCard(
    card: card,
    selectable: selectable,
    dimmed: dimmed,
    onTap: onTap,
    width: width,
    style: style,
  );
  if (reason == null) return widget;
  return Tooltip(message: reason, child: widget);
}

/// Plays a brief lift-and-fade locally, *then* calls the real [onTap] —
/// which is what actually removes the card from the hand — instead of the
/// card just vanishing the instant it's tapped. Only wired up as the tap
/// handler when [selectable], matching [PlayingCardWidget]'s own rule that
/// an unselectable card ignores taps entirely.
///
/// An unselectable (illegal) card is still tappable, but tapping it just
/// shakes it — "no, not that one" — rather than doing nothing, which used
/// to be a silent dead end for anyone who tapped instead of long-pressing
/// for the tooltip.
class _PlayableHandCard extends StatefulWidget {
  final PlayingCard card;
  final bool selectable;
  final bool dimmed;
  final VoidCallback onTap;
  final double width;
  final CardDeckStyle style;

  const _PlayableHandCard({
    required this.card,
    required this.selectable,
    required this.dimmed,
    required this.onTap,
    required this.width,
    required this.style,
  });

  @override
  State<_PlayableHandCard> createState() => _PlayableHandCardState();
}

class _PlayableHandCardState extends State<_PlayableHandCard>
    with SingleTickerProviderStateMixin {
  static const _playDuration = Duration(milliseconds: 160);
  bool _playing = false;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  Future<void> _handleTap() async {
    if (_playing) return;
    setState(() => _playing = true);
    await Future.delayed(_playDuration);
    if (mounted) widget.onTap();
  }

  void _handleIllegalTap() {
    if (_shake.isAnimating) return;
    _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        // A few damped left-right oscillations reads clearly as "no",
        // rather than a single wobble that could pass for a stray jitter.
        final t = _shake.value;
        final dx = sin(t * pi * 6) * 8 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: AnimatedSlide(
        duration: _playDuration,
        curve: Curves.easeIn,
        offset: _playing ? const Offset(0, -0.35) : Offset.zero,
        child: AnimatedScale(
          duration: _playDuration,
          curve: Curves.easeIn,
          scale: _playing ? 0.82 : 1,
          child: AnimatedOpacity(
            duration: _playDuration,
            curve: Curves.easeIn,
            opacity: _playing ? 0 : 1,
            child: PlayingCardWidget(
              card: widget.card,
              selectable: widget.selectable,
              dimmed: widget.dimmed,
              onTap: widget.selectable ? _handleTap : null,
              onIllegalTap: widget.selectable ? null : _handleIllegalTap,
              width: widget.width,
              style: widget.style,
            ),
          ),
        ),
      ),
    );
  }
}
