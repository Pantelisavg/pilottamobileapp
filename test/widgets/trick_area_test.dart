import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/settings/app_settings.dart';
import 'package:pilotta/widgets/playing_card_widget.dart';
import 'package:pilotta/widgets/table/game_table_data.dart';
import 'package:pilotta/widgets/table/trick_area.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A scriptable [GameTableData] double exposing only what [TrickArea]
/// actually reads (`currentTrick`, `viewerSeat`) — see throw_all_test.dart
/// for the same noSuchMethod convention used to satisfy the ~30-member
/// interface without stubbing every one of them.
class _FakeGameTableData extends ChangeNotifier implements GameTableData {
  Trick? trick;
  @override
  Trick? get currentTrick => trick;

  @override
  Seat get viewerSeat => Seat.south;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppSettings> pumpTrickArea(
      WidgetTester tester, _FakeGameTableData fake) async {
    final settings = await AppSettings.load();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: MaterialApp(
          home: Scaffold(body: TrickArea(controller: fake)),
        ),
      ),
    );
    return settings;
  }

  // Each card's own PlayingCardWidget wraps an inner Opacity for `dimmed`
  // (always 1.0 here) — find.ancestor isolates just the outer, animated
  // Opacity that _TrickCard itself wraps each card in.
  List<double> opacities(WidgetTester tester) => tester
      .widgetList<Opacity>(find.ancestor(
          of: find.byType(PlayingCardWidget), matching: find.byType(Opacity)))
      .map((o) => o.opacity)
      .toList();

  testWidgets(
      'a card played into an incomplete trick slides/fades in, then settles '
      'fully visible', (tester) async {
    final fake = _FakeGameTableData()
      ..trick = (Trick(leader: Seat.south, trumpSuit: Suit.spades)
        ..play(Seat.south, const PlayingCard(Suit.spades, Rank.ace)));
    await pumpTrickArea(tester, fake);

    await tester.pump(const Duration(milliseconds: 50));
    expect(opacities(tester).any((o) => o < 1.0), isTrue);

    await tester.pumpAndSettle();
    expect(opacities(tester), everyElement(1.0));
  });

  testWidgets(
      'once the 4th card completes the trick, all 4 cards converge toward '
      'the winner and fade out', (tester) async {
    final trick = Trick(leader: Seat.south, trumpSuit: Suit.spades)
      ..play(Seat.south, const PlayingCard(Suit.spades, Rank.ace))
      ..play(Seat.west, const PlayingCard(Suit.spades, Rank.seven))
      ..play(Seat.north, const PlayingCard(Suit.spades, Rank.eight))
      ..play(Seat.east, const PlayingCard(Suit.spades, Rank.nine));
    expect(trick.isComplete, isTrue);
    final fake = _FakeGameTableData()..trick = trick;

    await pumpTrickArea(tester, fake);
    await tester.pump(); // let each card's own entrance animation start

    // Mid-collect: still there, but no longer at full opacity.
    await tester.pump(const Duration(milliseconds: 300));
    final midway = opacities(tester);
    expect(midway.any((o) => o < 1.0), isTrue);

    // Fully settled: the convergence animation has run to completion and
    // every card has faded all the way out.
    await tester.pumpAndSettle();
    expect(opacities(tester), everyElement(0.0));
  });
}
