import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import 'suit_icon.dart';

/// A compact one-line description of a single auction call, e.g.
/// "Εσύ: 90 ♠" or "Δύση: Πάσο" — used in the bidding history tray.
Widget auctionCallLabel(AuctionCall call, String seatLabel,
    {double fontSize = 12}) {
  final style = TextStyle(color: Colors.white70, fontSize: fontSize);
  return switch (call) {
    PassCall() => Text('$seatLabel: Πάσο', style: style),
    DoubleCall() => Text('$seatLabel: Κλειστό',
        style: style.copyWith(color: Colors.orangeAccent)),
    RedoubleCall() => Text('$seatLabel: Ανοιχτό',
        style: style.copyWith(color: Colors.redAccent)),
    CapotCall() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$seatLabel: Καπό ', style: style.copyWith(color: Colors.white)),
          SuitIcon(call.suit, size: fontSize + 2, color: Colors.white),
        ],
      ),
    SuitBidCall() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$seatLabel: ${call.value} ',
              style: style.copyWith(color: Colors.white)),
          SuitIcon(call.suit, size: fontSize + 2, color: Colors.white),
        ],
      ),
  };
}
