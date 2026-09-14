import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/controllers/local_game_controller.dart';
import 'package:pilotta/widgets/table/turn_guidance_banner.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> pumpBanner(
          WidgetTester tester, LocalGameController controller) =>
      tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider.value(
          value: controller,
          child: Scaffold(body: TurnGuidanceBanner(controller: controller)),
        ),
      ));

  testWidgets('shows nothing when it is not the viewer\'s turn to play',
      (tester) async {
    final controller = LocalGameController(
      targetScore: 101,
      random: Random(7),
      trickCollectDelay: const Duration(milliseconds: 5),
      persistProgress: false,
    );

    await pumpBanner(tester, controller);
    // Still bidding — definitely not the viewer's turn to play.
    expect(find.byType(Text), findsNothing);

    // Let any pending bot-bidding timer actually settle before disposing,
    // rather than leaving it merely cancelled — matches the pattern used
    // throughout local_game_controller_test.dart.
    controller.dispose();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
      'shows one of the known guidance messages as soon as it is the '
      'viewer\'s turn to play — either leading or following', (tester) async {
    final controller = LocalGameController(
      targetScore: 101,
      random: Random(7),
      trickCollectDelay: const Duration(milliseconds: 5),
      persistProgress: false,
    );

    var guard = 0;
    while (!controller.isHumanTurnToPlay && guard++ < 5000) {
      if (controller.isHumanTurnToBid) {
        controller.submitBid(PassCall(controller.humanSeat));
      } else {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
    expect(controller.isHumanTurnToPlay, isTrue,
        reason: 'should reach the human\'s turn to play well within the '
            'guard limit');

    await pumpBanner(tester, controller);

    final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data);
    expect(
      texts.any((t) =>
          t != null &&
          (t.contains('Η σειρά σου') ||
              t.contains('Ακολούθησε') ||
              t.contains('κόψε') ||
              t.contains('Παίξε ό,τι θες'))),
      isTrue,
      reason: 'expected one of the known guidance messages, got: $texts',
    );

    controller.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
