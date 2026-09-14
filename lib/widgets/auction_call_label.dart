import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import 'suit_icon.dart';

/// A compact one-line description of a single auction call, e.g.
/// "Εσύ: 90 ♠" or "Δύση: Πάσο" — used in the bidding history tray.
///
/// Pass an empty [seatLabel] to omit the "who" prefix entirely (e.g. in a
/// grid where the seat is already conveyed by a column header) instead of
/// rendering a stray leading ": ".
Widget auctionCallLabel(AuctionCall call, String seatLabel,
    {double fontSize = 12}) {
  final style = TextStyle(color: Colors.white70, fontSize: fontSize);
  final prefix = seatLabel.isEmpty ? '' : '$seatLabel: ';
  return switch (call) {
    PassCall() => Text('$prefixΠάσο', style: style),
    DoubleCall() =>
      Text('$prefixΚλειστό', style: style.copyWith(color: Colors.orangeAccent)),
    RedoubleCall() =>
      Text('$prefixΑνοιχτό', style: style.copyWith(color: Colors.redAccent)),
    CapotCall() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$prefixΚαπό ', style: style.copyWith(color: Colors.white)),
          SuitIcon(call.suit, size: fontSize + 2, color: Colors.white),
        ],
      ),
    SuitBidCall() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$prefix${call.value} ',
              style: style.copyWith(color: Colors.white)),
          SuitIcon(call.suit, size: fontSize + 2, color: Colors.white),
        ],
      ),
  };
}
