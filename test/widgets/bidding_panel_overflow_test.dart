import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/settings/app_settings.dart';
import 'package:pilotta/widgets/bidding_panel.dart';
import 'package:pilotta/widgets/table/game_table_data.dart';
import 'package:pilotta/widgets/table/human_hand_panel.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A minimal [GameTableData] double exposing just what [HumanHandPanel]
/// reads (myHand, currentTrick, isViewerTurnToPlay, viewerLegalPlays) — any
/// other member throws if touched, via [noSuchMethod].
class _FakeGameTableData extends ChangeNotifier implements GameTableData {
  @override
  final List<PlayingCard> myHand;
  @override
  Trick? currentTrick;
  @override
  final bool isViewerTurnToPlay = true;
  @override
  final List<PlayingCard> viewerLegalPlays = const [];

  _FakeGameTableData({required this.myHand, this.currentTrick});

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

/// Regression coverage for the real-device "BOTTOM OVERFLOWED BY 113
/// PIXELS" bug: on a landscape-locked phone, height (not width) is the
/// scarce dimension, and [HumanHandPanel] + [BiddingPanel] sit as two
/// non-flexible siblings of the table's [Expanded] area in
/// `local_game_screen.dart` — so if their combined natural height exceeds
/// whatever vertical budget is actually left after system chrome eats into
/// the nominal window height, a real overflow happens regardless of the
/// Expanded table area (which can always shrink to zero, but never fixes
/// an overflow caused by its non-flexible siblings).
///
/// These tests reproduce that same three-widget arrangement (Expanded
/// placeholder + HumanHandPanel + BiddingPanel in a Column) constrained to
/// a tight, explicit height budget, and assert no RenderFlex overflow is
/// thrown — both at a realistic "Medium Phone" landscape budget and at an
/// intentionally tighter "compact/small-height device" budget.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final hand = List.generate(
      8, (i) => PlayingCard(Suit.values[i % 4], Rank.values[i % 8]));

  Future<AppSettings> pumpPanels(
    WidgetTester tester, {
    required Size windowSize,
    required double budgetHeight,
  }) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final settings = await AppSettings.load();
    final auction = Auction(Seat.south);
    final controller = _FakeGameTableData(myHand: hand, currentTrick: null);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: budgetHeight,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Expanded(child: SizedBox()),
                  HumanHandPanel(controller: controller),
                  BiddingPanel(
                    auction: auction,
                    seat: Seat.south,
                    onCall: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return settings;
  }

  testWidgets(
      'fits within a realistic tight Medium-Phone-landscape budget '
      '(non-compact tier) without a RenderFlex overflow', (tester) async {
    // Window height 411 (a Medium Phone's short side in landscape) keeps
    // both panels in their non-compact tier (MediaQuery height >= 380).
    // The actual body budget after status/nav-bar chrome on a real device
    // is meaningfully less than the nominal 411 — assuming ~131px of
    // chrome (close to the reverse-engineered real-device shortfall that
    // originally overflowed by 113px against roughly this same budget)
    // leaves 280px, tighter than a bare SafeArea would realistically give.
    await pumpPanels(
      tester,
      windowSize: const Size(900, 411),
      budgetHeight: 280,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'fits within a tighter compact/small-height-device budget '
      '(compact tier) without a RenderFlex overflow', (tester) async {
    // Window height 320 (< 380) engages the compact tier in both panels.
    // Status/nav-bar chrome is roughly constant in dp regardless of screen
    // size, so the same ~110-131px chrome assumption applied to a smaller
    // 320 window leaves a much tighter 210px budget here.
    await pumpPanels(
      tester,
      windowSize: const Size(700, 320),
      budgetHeight: 210,
    );

    expect(tester.takeException(), isNull);
  });
}
