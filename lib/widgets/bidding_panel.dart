import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import 'playing_card_widget.dart';
import 'suit_icon.dart';

/// The human player's bidding controls: pick a value + suit, call capot,
/// double/redouble, or pass.
class BiddingPanel extends StatefulWidget {
  final Auction auction;
  final Seat seat;
  final void Function(AuctionCall call) onCall;

  const BiddingPanel({
    super.key,
    required this.auction,
    required this.seat,
    required this.onCall,
  });

  @override
  State<BiddingPanel> createState() => _BiddingPanelState();
}

class _BiddingPanelState extends State<BiddingPanel> {
  late int _value = _minimumValue();
  Suit _suit = Suit.spades;

  int _minimumValue() {
    final bid = widget.auction.currentBid;
    if (bid == null) return kMinBidValue;
    return bid.value + kBidIncrement;
  }

  bool get _canDouble {
    final bid = widget.auction.currentBid;
    return bid != null && bid.seat.team != widget.seat.team;
  }

  bool get _canRedouble {
    final bid = widget.auction.currentBid;
    return bid != null && bid.seat.team == widget.seat.team;
  }

  @override
  Widget build(BuildContext context) {
    final minValue = _minimumValue();
    final value = _value < minValue ? minValue : _value;
    final canBidAtAll = minValue <= kMaxBidValue;
    final canBidValue = canBidAtAll && value <= kMaxBidValue;
    final canIncrement = canBidAtAll && value + kBidIncrement <= kMaxBidValue;
    final canDecrement = canBidAtAll && value > minValue;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF10241D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Η δήλωσή σου',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (!canBidAtAll)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Έφτασε στο ανώτατο όριο (${kMaxBidValue ~/ 10})',
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            )
          else ...[
            // Shown in the usual colloquial shorthand (8 to 80, for an
            // actual 80-800) — the same tens convention the scoreboard
            // uses for its running totals.
            Text('${value ~/ 10}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
            // A slider so reaching a far-off value (e.g. jumping straight
            // to 40) doesn't mean tapping "+" dozens of times — drag for a
            // big jump, then fine-tune with the +/- buttons if needed.
            Row(
              children: [
                IconButton(
                  onPressed: canDecrement ? () => setState(() => _value = value - kBidIncrement) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.white,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.amber,
                      thumbColor: Colors.amber,
                      inactiveTrackColor: Colors.white24,
                      valueIndicatorColor: Colors.amber.shade700,
                    ),
                    child: Slider(
                      min: minValue.toDouble(),
                      max: kMaxBidValue.toDouble(),
                      divisions: (kMaxBidValue - minValue) ~/ kBidIncrement,
                      value: value.toDouble(),
                      label: '${value ~/ 10}',
                      onChanged: (v) => setState(() => _value = v.round()),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: canIncrement ? () => setState(() => _value = value + kBidIncrement) : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.white,
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              for (final suit in Suit.values)
                ChoiceChip(
                  selected: _suit == suit,
                  onSelected: (_) => setState(() => _suit = suit),
                  backgroundColor: Colors.white10,
                  selectedColor: Colors.amber,
                  label: SuitIcon(
                    suit,
                    size: 22,
                    color: _suit == suit ? suitColor(suit) : Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton(
                onPressed:
                    canBidValue ? () => widget.onCall(SuitBidCall(widget.seat, _suit, value)) : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(canBidAtAll ? 'Δήλωση ${value ~/ 10} ' : 'Δήλωση '),
                    SuitIcon(_suit, size: 16),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => widget.onCall(CapotCall(widget.seat, _suit)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [const Text('Καπότο '), SuitIcon(_suit, size: 16)],
                ),
              ),
              if (_canDouble)
                FilledButton.tonal(
                  style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
                  onPressed: () => widget.onCall(DoubleCall(widget.seat)),
                  child: const Text('Κόντρα'),
                ),
              if (_canRedouble)
                FilledButton.tonal(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red.shade900),
                  onPressed: () => widget.onCall(RedoubleCall(widget.seat)),
                  child: const Text('Ρεκόντρα'),
                ),
              OutlinedButton(
                onPressed: () => widget.onCall(PassCall(widget.seat)),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Πάσο'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
