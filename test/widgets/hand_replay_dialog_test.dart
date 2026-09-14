import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/settings/app_settings.dart';
import 'package:pilotta/widgets/hand_replay_dialog.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

HandResult _playHandToCompletion() {
  final hands = dealHands(Random(5));
  final contract = Contract(
    biddingSeat: Seat.south,
    trumpSuit: Suit.spades,
    value: 80,
    isCapot: false,
  );
  final hand = PilottaHand(
    contract: contract,
    initialHands: hands,
    firstLeader: Seat.south,
    auctionCalls: [
      SuitBidCall(Seat.south, Suit.spades, 80),
      PassCall(Seat.west),
      PassCall(Seat.north),
      PassCall(Seat.east),
    ],
  );
  while (!hand.isHandComplete) {
    if (hand.currentTrick.isComplete) {
      hand.startNextTrick();
      continue;
    }
    final seat = hand.currentTrick.seatToPlay;
    hand.playCard(seat, hand.legalPlays(seat).first);
  }
  return hand.finish();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'shows the last trick first, and Previous/Next step through all 8',
      (tester) async {
    final result = _playHandToCompletion();
    final settings = await AppSettings.load();

    await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
      value: settings,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showHandReplayDialog(
                context,
                result: result,
                viewerSeat: Seat.south,
                handNumber: 3,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The dialog has exactly two IconButtons: Previous (chevron_left) then
    // Next (chevron_right), in that order.
    final buttons = find.byType(IconButton);
    IconButton prevButton() => tester.widgetList<IconButton>(buttons).first;
    IconButton nextButton() => tester.widgetList<IconButton>(buttons).last;

    expect(find.text('Χέρι 3'), findsOneWidget);
    // Opens on the last trick and Next is disabled there.
    expect(find.textContaining('Μπάζα 8/8'), findsOneWidget);
    expect(nextButton().onPressed, isNull);

    await tester.tap(buttons.first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Μπάζα 7/8'), findsOneWidget);

    // Previous, all the way back to the first trick, where it disables.
    for (var i = 0; i < 6; i++) {
      await tester.tap(buttons.first);
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('Μπάζα 1/8'), findsOneWidget);
    expect(prevButton().onPressed, isNull);

    await tester.tap(find.text('Κλείσιμο'));
    await tester.pumpAndSettle();
    expect(find.text('Χέρι 3'), findsNothing);
  });
}
