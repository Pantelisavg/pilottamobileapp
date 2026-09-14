import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/controllers/local_game_controller.dart';
import 'package:pilotta/widgets/table/trick_trump_badge.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('counts up to "Μπάζα 1/8" after exactly one full trick is played',
      (tester) async {
    final controller = LocalGameController(
      targetScore: 101,
      random: Random(7),
      trickCollectDelay: const Duration(milliseconds: 5),
      persistProgress: false,
    );
    addTearDown(controller.dispose);

    Widget buildBadge() => MaterialApp(
          home: ChangeNotifierProvider.value(
            value: controller,
            child: Scaffold(
              body: AnimatedBuilder(
                animation: controller,
                builder: (context, _) =>
                    TrickTrumpBadge(controller: controller),
              ),
            ),
          ),
        );

    // Drive through bidding (human always passes) and then exactly one
    // full trick (human plays its first legal card each turn), same loop
    // shape as local_game_controller_test.dart but pumping the fake clock
    // instead of fakeAsync's `async.elapse` so bot Timers actually fire.
    var guard = 0;
    var tricksPlayed = 0;
    while (tricksPlayed < 1 && guard++ < 5000) {
      if (controller.isHumanTurnToBid) {
        controller.submitBid(PassCall(controller.humanSeat));
      } else if (controller.isHumanTurnToPlay) {
        final before = controller.hand?.completedTricks.length ?? 0;
        controller.playCard(controller.humanLegalPlays.first);
        if ((controller.hand?.completedTricks.length ?? 0) > before) {
          tricksPlayed++;
        }
      } else {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
    expect(controller.phase, RoomPhase.playing);
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pumpWidget(buildBadge());
    expect(find.text('Μπάζα 1/8'), findsOneWidget);
  });
}
