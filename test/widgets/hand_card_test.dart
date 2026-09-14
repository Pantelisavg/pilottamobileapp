import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/widgets/hand_card.dart';
import 'package:pilotta/widgets/playing_card_widget.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

/// An illegal (unselectable) hand card used to ignore taps entirely; it's
/// now tappable specifically to shake — these tests check the shake
/// actually moves the card and that it never calls the real (playing)
/// callback, since the card still isn't a legal play.
void main() {
  const card = PlayingCard(Suit.spades, Rank.ace);

  // Several ancestors of PlayingCardWidget happen to be Transforms (its
  // own internal one for the "selected" lift, AnimatedScale's internal
  // ScaleTransition, and the shake's own Transform.translate) — rather
  // than assume an ordering among them, just check whether *any* carries
  // a sideways offset.
  bool anySidewaysOffset(WidgetTester tester) => tester
      .widgetList<Transform>(find.ancestor(
          of: find.byType(PlayingCardWidget), matching: find.byType(Transform)))
      .any((t) => t.transform.getTranslation().x != 0);

  testWidgets('tapping an illegal card shakes it without calling onTap',
      (tester) async {
    var played = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: buildHandCard(
          card: card,
          selectable: false,
          dimmed: true,
          onTap: () => played = true,
          width: 60,
        ),
      ),
    ));

    expect(anySidewaysOffset(tester), isFalse);

    await tester.tap(find.byType(PlayingCardWidget));
    // A zero-duration pump first, establishing the shake AnimationController
    // ticker's zero-elapsed baseline on its first tick, before advancing by
    // a real duration to sample it mid-flight.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(anySidewaysOffset(tester), isTrue,
        reason: 'mid-shake the card should be offset sideways');
    expect(played, isFalse,
        reason: 'an illegal card never actually gets played');

    await tester.pumpAndSettle();
    expect(anySidewaysOffset(tester), isFalse);
    expect(played, isFalse);
  });

  testWidgets('a legal card ignores the shake path and plays normally',
      (tester) async {
    PlayingCard? played;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: buildHandCard(
          card: card,
          selectable: true,
          dimmed: false,
          onTap: () => played = card,
          width: 60,
        ),
      ),
    ));

    await tester.tap(find.byType(PlayingCardWidget));
    await tester.pump(const Duration(milliseconds: 200));

    expect(played, card);
  });
}
