import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/settings/card_deck_style.dart';
import 'package:pilotta/widgets/playing_card_widget.dart';
import 'package:pilotta/widgets/suit_icon.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

/// [PlayingCardWidget] is the one rendering seam every card in the app
/// goes through, so the two [CardDeckStyle]s need to actually look
/// different — these tests check that by counting structural markers
/// (how many suit glyphs, whether a decorative painter is present)
/// rather than asserting on exact pixel output.
void main() {
  const card = PlayingCard(Suit.hearts, Rank.king);

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Material(child: Center(child: child))),
      );

  Finder cardDescendant(Type type) => find.descendant(
        of: find.byType(PlayingCardWidget),
        matching: find.byType(type),
      );

  testWidgets('classic face shows one corner index and one centered glyph',
      (tester) async {
    await pump(tester,
        const PlayingCardWidget(card: card, style: CardDeckStyle.classic));
    expect(cardDescendant(SuitIcon), findsNWidgets(2));
  });

  testWidgets(
      'modern face mirrors the corner index at both ends, plus the '
      'centered glyph', (tester) async {
    await pump(tester,
        const PlayingCardWidget(card: card, style: CardDeckStyle.modern));
    expect(cardDescendant(SuitIcon), findsNWidgets(3));
  });

  testWidgets('classic back has no decorative painter', (tester) async {
    await pump(tester,
        const PlayingCardWidget(faceUp: false, style: CardDeckStyle.classic));
    expect(cardDescendant(CustomPaint), findsNothing);
  });

  testWidgets('modern back draws its lattice pattern', (tester) async {
    await pump(tester,
        const PlayingCardWidget(faceUp: false, style: CardDeckStyle.modern));
    expect(cardDescendant(CustomPaint), findsOneWidget);
  });
}
