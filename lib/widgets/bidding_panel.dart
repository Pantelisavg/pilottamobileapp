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
/// screen actions like "Play"/"Join room". This app is landscape-locked,
/// so height (not width) is the scarce dimension here; [compact] shaves a
/// little further for short-height devices.
ButtonStyle _compactCallButton({Color? background, required bool compact}) =>
    FilledButton.styleFrom(
      backgroundColor: background,
      minimumSize: Size(0, compact ? 25 : 34),
      padding: EdgeInsets.symmetric(
          horizontal: PilottaSpacing.sm, vertical: compact ? 1 : 4),
      textStyle: PilottaTypography.label.copyWith(fontSize: compact ? 11 : 13),
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

  Widget _stepButton(
      {required IconData icon,
      required bool enabled,
      required VoidCallback onPressed,
      required bool compact}) {
    final size = compact ? 22.0 : 30.0;
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
      color: Colors.white,
      iconSize: compact ? 14 : 18,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: size, minHeight: size),
    );
  }

  Widget _suitChip(Suit suit, bool compact) {
    final selected = _suit == suit;
    return GestureDetector(
      onTap: () => setState(() => _suit = suit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 10, vertical: compact ? 2 : 5),
        decoration: BoxDecoration(
          color: selected ? Colors.amber : Colors.white10,
          borderRadius: BorderRadius.circular(PilottaRadius.pill),
        ),
        child: SuitIcon(suit,
            size: compact ? 13 : 18,
            color: selected ? suitColor(suit) : Colors.white),
      ),
    );
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

    // The app is landscape-locked, so height (not width) is what a phone
    // is actually short on here — a genuinely short-height device gets an
    // extra notch of compactness rather than risking an overflow.
    final compact = MediaQuery.sizeOf(context).height < 380;

    return Container(
      padding: EdgeInsets.fromLTRB(12, compact ? 4 : 8, 12, compact ? 5 : 10),
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
          if (!canBidAtAll)
            Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
              child: Text(
                  auctionLocked
                      ? 'Η δήλωση έχει κλειδώσει'
                      : 'Έφτασε στο ανώτατο όριο (${kMaxBidValue ~/ 10})',
                  style: TextStyle(
                      color: Colors.white54, fontSize: compact ? 12 : 13)),
            )
          else ...[
            // Value, slider and suit selector all share one row instead of
            // stacking — landscape has width to spare, unlike height.
            Row(
              children: [
                _stepButton(
                  icon: Icons.remove_circle_outline,
                  enabled: canDecrement,
                  onPressed: () =>
                      setState(() => _value = value - kBidIncrement),
                  compact: compact,
                ),
                SizedBox(
                  width: compact ? 26 : 32,
                  child: Text('${value ~/ 10}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 18 : 22,
                          fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: SizedBox(
                    height: compact ? 22 : 30,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.amber,
                        thumbColor: Colors.amber,
                        inactiveTrackColor: Colors.white24,
                        valueIndicatorColor: Colors.amber.shade700,
                        trackHeight: compact ? 2 : 3,
                        overlayShape: SliderComponentShape.noOverlay,
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
                ),
                _stepButton(
                  icon: Icons.add_circle_outline,
                  enabled: canIncrement,
                  onPressed: () =>
                      setState(() => _value = value + kBidIncrement),
                  compact: compact,
                ),
                for (final suit in Suit.values)
                  Padding(
                    padding: EdgeInsets.only(left: compact ? 4 : 6),
                    child: _suitChip(suit, compact),
                  ),
              ],
            ),
          ],
          SizedBox(height: compact ? 2 : 6),
          Wrap(
            spacing: 8,
            runSpacing: compact ? 2 : 4,
            alignment: WrapAlignment.center,
            children: [
              FilledButton(
                style: _compactCallButton(compact: compact),
                onPressed: canBidValue
                    ? () =>
                        widget.onCall(SuitBidCall(widget.seat, _suit, value))
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${value ~/ 10} '),
                    SuitIcon(_suit, size: 13),
                  ],
                ),
              ),
              FilledButton(
                style: _compactCallButton(
                    background: PilottaColors.wood600, compact: compact),
                onPressed: canCallCapot
                    ? () => widget.onCall(CapotCall(widget.seat, _suit))
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [const Text('Καπό '), SuitIcon(_suit, size: 13)],
                ),
              ),
              if (_canDouble)
                FilledButton(
                  style: _compactCallButton(
                      background: Colors.orange.shade800, compact: compact),
                  onPressed: () => widget.onCall(DoubleCall(widget.seat)),
                  child: const Text('Κλειστό'),
                ),
              if (_canRedouble)
                FilledButton(
                  style: _compactCallButton(
                      background: Colors.red.shade900, compact: compact),
                  onPressed: () => widget.onCall(RedoubleCall(widget.seat)),
                  child: const Text('Ανοιχτό'),
                ),
              OutlinedButton(
                onPressed: () => widget.onCall(PassCall(widget.seat)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: Size(0, compact ? 25 : 34),
                  padding: EdgeInsets.symmetric(
                      horizontal: PilottaSpacing.sm, vertical: compact ? 1 : 4),
                  textStyle: PilottaTypography.label
                      .copyWith(fontSize: compact ? 11 : 13),
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
