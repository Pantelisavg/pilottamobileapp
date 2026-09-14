import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:provider/provider.dart';

import '../../settings/app_settings.dart';
import '../playing_card_widget.dart';
import 'game_table_data.dart';
import 'oval_geometry.dart';

/// The cards played so far in the current trick, positioned around the
/// table — shared replacement for local's `_TrickArea` and online's
/// `_OnlineTrickArea`, both of which reconstructed the same thing from a
/// [Trick] (local's live, online's decoded from the snapshot).
class TrickArea extends StatelessWidget {
  final GameTableData controller;
  const TrickArea({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final trick = controller.currentTrick;
    if (trick == null) return const SizedBox.shrink();

    final played = {for (final e in trick.played) e.seat: e.card};
    final settings = context.watch<AppSettings>();
    final cardScale = settings.cardScale;
    // Once the trick's 4th card lands, Trick.winner is already resolvable
    // — the room only *holds* the completed trick on the table for
    // trickCollectDelay before clearing it, so this window is exactly
    // when the convergence-toward-the-winner animation should run.
    final winner = trick.isComplete ? trick.winner : null;

    return SizedBox(
      width: 260,
      height: 240,
      child: Stack(
        children: [
          for (final seat in Seat.values)
            if (played[seat] != null)
              Align(
                key: ValueKey(seat),
                alignment: ovalSeatAlignment(seat, controller.viewerSeat),
                child: _TrickCard(
                  fromAlignment: ovalSeatAlignment(seat, controller.viewerSeat),
                  towardAlignment: winner != null
                      ? ovalSeatAlignment(winner, controller.viewerSeat)
                      : null,
                  child: PlayingCardWidget(
                      card: played[seat],
                      width: 68 * cardScale,
                      style: settings.deckStyle),
                ),
              ),
        ],
      ),
    );
  }
}

/// One played card's motion within the trick area: a short slide-in from
/// the direction of the seat that played it, and — once the trick
/// completes and [towardAlignment] (the winner's direction) is known — a
/// slide-and-fade convergence toward the winner instead of an instant
/// clear when the room collects the trick.
class _TrickCard extends StatefulWidget {
  final Alignment fromAlignment;
  final Alignment? towardAlignment;
  final Widget child;

  const _TrickCard({
    required this.fromAlignment,
    required this.towardAlignment,
    required this.child,
  });

  @override
  State<_TrickCard> createState() => _TrickCardState();
}

class _TrickCardState extends State<_TrickCard> with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();
  AnimationController? _collect;

  @override
  void initState() {
    super.initState();
    if (widget.towardAlignment != null) _startCollect();
  }

  @override
  void didUpdateWidget(covariant _TrickCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.towardAlignment != null && _collect == null) _startCollect();
  }

  void _startCollect() {
    _collect = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _collect?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, if (_collect != null) _collect!]),
      builder: (context, child) {
        final enter = Curves.easeOut.transform(_entrance.value.clamp(0.0, 1.0));
        var dx = widget.fromAlignment.x * 22 * (1 - enter);
        var dy = widget.fromAlignment.y * 22 * (1 - enter);
        var opacity = enter;

        final collectValue = _collect?.value ?? 0.0;
        if (collectValue > 0 && widget.towardAlignment != null) {
          final t = Curves.easeIn.transform(collectValue.clamp(0.0, 1.0));
          dx += (widget.towardAlignment!.x - widget.fromAlignment.x) * 40 * t;
          dy += (widget.towardAlignment!.y - widget.fromAlignment.y) * 40 * t;
          opacity = opacity * (1 - t);
        }

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(dx, dy), child: child),
        );
      },
      child: widget.child,
    );
  }
}
