import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

/// Where [seat] belongs on screen relative to [me], who always sits at the
/// bottom. Offsets follow the engine's anti-clockwise turn order (south ->
/// west -> north -> east -> south), so whoever acts right after you is on
/// your right, your partner is straight across, and whoever acts right
/// before you is on your left — exactly how you'd expect to see them
/// seated at a real table.
Alignment seatAlignmentRelativeTo(Seat seat, Seat me) {
  final offset = (seat.index - me.index) % 4;
  return switch (offset) {
    0 => Alignment.bottomCenter,
    1 => Alignment.centerRight,
    2 => Alignment.topCenter,
    _ => Alignment.centerLeft,
  };
}

/// A short Greek label for [seat] relative to [me].
String seatLabelRelativeTo(Seat seat, Seat me) {
  final offset = (seat.index - me.index) % 4;
  return switch (offset) {
    0 => 'Εσύ',
    1 => 'Δεξιά',
    2 => 'Συμπαίκτης',
    _ => 'Αριστερά',
  };
}
