import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

import '../hand_replay_dialog.dart';
import '../scoreboard_sheet.dart';
import '../suit_icon.dart';
import 'game_table_data.dart';

/// The app-bar title: running score (tap to open the full ledger) plus the
/// current contract, if one has been settled — shared replacement for
/// local's `_ScoreHeader` and online's `_OnlineScoreHeader`.
///
/// Unifying these also fixes two small ways they'd drifted apart: online's
/// contract badge never showed the x2/x4 double/redouble marker or colored
/// a red trump suit, both of which local's always had — both were just
/// omissions in the online widget, not an intentional online/local
/// difference, so folding onto one shared widget restores them for online
/// too. [extraTargetSubtitle], when given, is appended after the target
/// score (used online to also show the room code).
class ScoreHeader extends StatelessWidget {
  final GameTableData controller;
  final String? extraTargetSubtitle;

  const ScoreHeader({
    super.key,
    required this.controller,
    this.extraTargetSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final ourTeam = controller.viewerSeat.team;
    final contract = controller.contract;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => showScoreboardSheet(
            context,
            rows:
                buildScoreRows(controller.matchHistory, controller.viewerSeat),
            totalMine: controller.totals[ourTeam]!,
            totalTheirs: controller.totals[ourTeam.opponent]!,
            targetScore: controller.targetScore,
            onRowTap: (i) => showHandReplayDialog(
              context,
              result: controller.matchHistory[i],
              viewerSeat: controller.viewerSeat,
              handNumber: i + 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Εμείς ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  _AnimatedScoreNumber(value: controller.totals[ourTeam]!),
                  const Text('  –  Αυτοί ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  _AnimatedScoreNumber(
                      value: controller.totals[ourTeam.opponent]!),
                  const SizedBox(width: 4),
                  const Icon(Icons.receipt_long,
                      color: Colors.white54, size: 16),
                ],
              ),
              Text(
                  'Στόχος: ${controller.targetScore}'
                  '${extraTargetSubtitle == null ? '' : ' · $extraTargetSubtitle'}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
        if (contract != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${contract.isCapot ? 'Καπό' : contract.value}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              SuitIcon(contract.trumpSuit,
                  size: 22,
                  color: contract.trumpSuit.isRed
                      ? Colors.red.shade300
                      : Colors.white),
              if (contract.multiplier != ContractMultiplier.none)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text('x${contract.multiplier.factor}',
                      style: const TextStyle(
                          fontSize: 14, color: Colors.orangeAccent)),
                ),
            ],
          ),
      ],
    );
  }
}

/// A running total that counts up (or down) to a new value over a short
/// animation instead of just snapping to it — TweenAnimationBuilder picks
/// up from wherever it currently sits whenever [value] changes, so this
/// needs no manually-tracked "previous value" of its own.
class _AnimatedScoreNumber extends StatelessWidget {
  final int value;
  const _AnimatedScoreNumber({required this.value});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: value, end: value),
      duration: const Duration(milliseconds: 400),
      builder: (context, animatedValue, child) => Text(
        '$animatedValue',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
