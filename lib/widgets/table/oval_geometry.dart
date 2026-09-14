import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

/// How far in from the true edge of the board a seat sits, as a fraction of
/// the oval's radius (1.0 would put every seat exactly on the boundary
/// ellipse; a bit less keeps avatars/card fans fully inside the felt).
const double kOvalSeatInset = 0.86;

/// Fractional position (0..1 on each axis, relative to the table's
/// bounding box) for [seat]'s anchor point on an oval table, seen from
/// [me]'s side (who always sits at the bottom).
///
/// Replaces the old 4-cardinal-`Alignment`-only [seatAlignmentRelativeTo]
/// (see `seat_layout.dart`) — Pilotta always seats exactly 3 opponents
/// across the arc facing the viewer, which an oval table's rim can be
/// parametrized by angle for: 90° (bottom, the viewer), 0° (right, the
/// seat that acts right after the viewer), 270° (top, the partner
/// straight across), 180° (left, the seat that acts right before the
/// viewer) — angles measured clockwise from the positive x-axis, matching
/// screen coordinates (y grows downward).
Offset ovalSeatFraction(Seat seat, Seat me) {
  final offset = (seat.index - me.index) % 4;
  final angleDegrees = switch (offset) {
    0 => 90.0,
    1 => 0.0,
    2 => 270.0,
    _ => 180.0,
  };
  final radians = angleDegrees * pi / 180;
  final x = 0.5 + 0.5 * kOvalSeatInset * cos(radians);
  final y = 0.5 + 0.5 * kOvalSeatInset * sin(radians);
  return Offset(x, y);
}

/// [ovalSeatFraction] converted to Flutter's `Alignment` coordinate space
/// (-1..1 per axis, 0 at the center) — a drop-in replacement everywhere
/// the old `seatAlignmentRelativeTo` was passed straight to an `Align`.
Alignment ovalSeatAlignment(Seat seat, Seat me) {
  final f = ovalSeatFraction(seat, me);
  return Alignment(f.dx * 2 - 1, f.dy * 2 - 1);
}

/// [ovalSeatFraction] scaled to actual pixels within a board of [boardSize]
/// — for callers doing their own `Positioned`/`Transform` placement instead
/// of an `Align`.
Offset ovalSeatOffset(Seat seat, Seat me, Size boardSize) {
  final f = ovalSeatFraction(seat, me);
  return Offset(f.dx * boardSize.width, f.dy * boardSize.height);
}
