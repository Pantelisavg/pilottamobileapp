import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

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
}) {
  final widget = PlayingCardWidget(
    card: card,
    selectable: selectable,
    dimmed: dimmed,
    onTap: onTap,
    width: width,
  );
  if (reason == null) return widget;
  return Tooltip(message: reason, child: widget);
}
