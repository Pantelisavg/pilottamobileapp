import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import '../theme/pilotta_colors.dart';
import '../theme/pilotta_spacing.dart';
import '../theme/pilotta_typography.dart';
import 'playing_card_widget.dart';
import 'suit_icon.dart';

/// A compact pill button style for the auction's call buttons (bid,
/// Capot, double/redouble, pass) — the app theme's default [FilledButton]/
/// [OutlinedButton] sizing (a 56px-tall full CTA) is meant for primary
/// screen actions like "Play"/"Join room", and reads as an oversized bar
/// here next to the compact suit chips above it.
ButtonStyle _compactCallButton({Color? background}) => FilledButton.styleFrom(
      backgroundColor: background,
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: PilottaSpacing.sm + 2),
      textStyle: PilottaTypography.label.copyWith(fontSize: 13),
      shape: const StadiumBorder(),
    );

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
    return bid != null &&
        bid.seat.team != widget.seat.team &&
        widget.auction.multiplier == ContractMultiplier.none;
  }

  bool get _canRedouble {
    final bid = widget.auction.currentBid;
    return bid != null &&
        bid.seat.team == widget.seat.team &&
        widget.auction.multiplier == ContractMultiplier.doubled;
  }

  @override
  Widget build(BuildContext context) {
    final minValue = _minimumValue();
    final value = _value < minValue ? minValue : _value;
    final currentBid = widget.auction.currentBid;
    // Once doubled/redoubled, no suit bid or Capot call is legal anymore —
    // only pass, or (via _canDouble/_canRedouble above) a double/redouble.
    final auctionLocked = widget.auction.multiplier != ContractMultiplier.none;
    final canBidAtAll = !auctionLocked && minValue <= kMaxBidValue;
    final canBidValue = canBidAtAll && value <= kMaxBidValue;
    final canIncrement = canBidAtAll && value + kBidIncrement <= kMaxBidValue;
    final canDecrement = canBidAtAll && value > minValue;
    final canCallCapot = !auctionLocked && !(currentBid?.isCapot ?? false);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [PilottaColors.felt900, PilottaColors.felt800],
        ),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(PilottaRadius.lg)),
        border: Border(
          top: BorderSide(
              color: PilottaColors.gold500.withValues(alpha: 0.35), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Η δήλωσή σου', style: PilottaTypography.title),
          const SizedBox(height: 8),
          if (!canBidAtAll)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                  auctionLocked
                      ? 'Η δήλωση έχει κλειδώσει'
                      : 'Έφτασε στο ανώτατο όριο (${kMaxBidValue ~/ 10})',
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            )
          else ...[
            // Shown in the usual colloquial shorthand (8 to 80, for an
            // actual 80-800) — the same tens convention the scoreboard
            // uses for its running totals.
            Text('${value ~/ 10}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold)),
            // A slider so reaching a far-off value (e.g. jumping straight
            // to 40) doesn't mean tapping "+" dozens of times — drag for a
            // big jump, then fine-tune with the +/- buttons if needed.
            Row(
              children: [
                IconButton(
                  onPressed: canDecrement
                      ? () => setState(() => _value = value - kBidIncrement)
                      : null,
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
                  onPressed: canIncrement
                      ? () => setState(() => _value = value + kBidIncrement)
                      : null,
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
                style: _compactCallButton(),
                onPressed: canBidValue
                    ? () =>
                        widget.onCall(SuitBidCall(widget.seat, _suit, value))
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${value ~/ 10} '),
                    SuitIcon(_suit, size: 14),
                  ],
                ),
              ),
              FilledButton(
                style: _compactCallButton(background: PilottaColors.wood600),
                onPressed: canCallCapot
                    ? () => widget.onCall(CapotCall(widget.seat, _suit))
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [const Text('Καπό '), SuitIcon(_suit, size: 14)],
                ),
              ),
              if (_canDouble)
                FilledButton(
                  style: _compactCallButton(background: Colors.orange.shade800),
                  onPressed: () => widget.onCall(DoubleCall(widget.seat)),
                  child: const Text('Κλειστό'),
                ),
              if (_canRedouble)
                FilledButton(
                  style: _compactCallButton(background: Colors.red.shade900),
                  onPressed: () => widget.onCall(RedoubleCall(widget.seat)),
                  child: const Text('Ανοιχτό'),
                ),
              OutlinedButton(
                onPressed: () => widget.onCall(PassCall(widget.seat)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                      horizontal: PilottaSpacing.sm + 2),
                  textStyle: PilottaTypography.label.copyWith(fontSize: 13),
                ),
                child: const Text('Πάσο'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
