import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/widgets/fanned_hand.dart';
import 'package:pilotta/widgets/playing_card_widget.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

/// [FannedHand] animates a fresh deal fanning in card by card, and a
/// played card lifting/fading out before it actually leaves the hand —
/// these tests check the animation actually moves through intermediate
/// states, and that the final settled state matches what the static
/// layout always looked like (full opacity, real onTap firing).
void main() {
  const cards = [
    PlayingCard(Suit.spades, Rank.ace),
    PlayingCard(Suit.hearts, Rank.king),
    PlayingCard(Suit.clubs, Rank.queen),
  ];

  Future<void> pumpHand(
    WidgetTester tester, {
    required void Function(PlayingCard) onTap,
  }) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FannedHand(
          cards: cards,
          legal: cards.toSet(),
          isMyTurn: true,
          onTap: onTap,
        ),
      ),
    ));
  }

  List<double> opacitiesIn(WidgetTester tester) => tester
      .widgetList<Opacity>(find.descendant(
          of: find.byType(FannedHand), matching: find.byType(Opacity)))
      .map((o) => o.opacity)
      .toList();

  testWidgets(
      'a freshly dealt hand fans in — mid-animation some cards are not yet '
      'fully visible, and it settles with every card fully visible',
      (tester) async {
    await pumpHand(tester, onTap: (_) {});

    await tester.pump(const Duration(milliseconds: 50));
    expect(opacitiesIn(tester).any((o) => o < 1.0), isTrue);

    await tester.pumpAndSettle();
    expect(opacitiesIn(tester), everyElement(1.0));
  });

  testWidgets(
      'tapping a legal card animates it out before the real onTap fires',
      (tester) async {
    PlayingCard? played;
    await pumpHand(tester, onTap: (c) => played = c);
    await tester.pumpAndSettle();

    await tester.tap(find.byWidgetPredicate(
        (w) => w is PlayingCardWidget && w.card == cards.first));
    await tester.pump();
    expect(played, isNull,
        reason: 'the lift-and-fade plays before the real onTap fires');

    await tester.pump(const Duration(milliseconds: 200));
    expect(played, cards.first);
  });
}
