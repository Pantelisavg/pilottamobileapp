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

class _PlayableHandCardState extends State<_PlayableHandCard> {
  static const _duration = Duration(milliseconds: 160);
  bool _playing = false;

  Future<void> _handleTap() async {
    if (_playing) return;
    setState(() => _playing = true);
    await Future.delayed(_duration);
    if (mounted) widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: _duration,
      curve: Curves.easeIn,
      offset: _playing ? const Offset(0, -0.35) : Offset.zero,
      child: AnimatedScale(
        duration: _duration,
        curve: Curves.easeIn,
        scale: _playing ? 0.82 : 1,
        child: AnimatedOpacity(
          duration: _duration,
          curve: Curves.easeIn,
          opacity: _playing ? 0 : 1,
          child: PlayingCardWidget(
            card: widget.card,
            selectable: widget.selectable,
            dimmed: widget.dimmed,
            onTap: widget.selectable ? _handleTap : null,
            width: widget.width,
            style: widget.style,
          ),
        ),
      ),
    );
  }
}
