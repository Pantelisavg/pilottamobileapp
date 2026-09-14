import 'package:pilotta_engine/pilotta_engine.dart';

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
