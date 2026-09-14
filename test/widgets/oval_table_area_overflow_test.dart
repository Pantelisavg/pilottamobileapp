import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/settings/app_settings.dart';
import 'package:pilotta/widgets/bidding_panel.dart';
import 'package:pilotta/widgets/table/game_table_data.dart';
import 'package:pilotta/widgets/table/human_hand_panel.dart';
import 'package:pilotta/widgets/table/oval_table_area.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [GameTableData] double covering exactly what the bidding-screen
/// widget tree (OvalTableArea + HumanHandPanel + BiddingPanel) reads: any
/// other member throws if touched, via [noSuchMethod].
class _FakeGameTableData extends ChangeNotifier implements GameTableData {
  @override
  final RoomPhase phase;
  @override
  final Seat viewerSeat;
  @override
  final Auction? auction;
  @override
  Trick? currentTrick;
  @override
  final List<PlayingCard> myHand;
  @override
  final bool isViewerTurnToPlay = false;
  @override
  final List<PlayingCard> viewerLegalPlays = const [];
  @override
  final List<({Seat seat, PlayingCard card})>? lastCompletedTrickPlayed = null;

  _FakeGameTableData({
    required this.phase,
    required this.viewerSeat,
    required this.auction,
    required this.myHand,
  });

  @override
  int handSizeOf(Seat seat) => 8;
  @override
  bool isBotControlled(Seat seat) => seat != viewerSeat;
  @override
  DeclarationAnnounceState declarationStateOf(Seat seat) =>
      DeclarationAnnounceState.none;
  @override
  String? revealedDeclarationsLabelOf(Seat seat) => null;
  @override
  Seat? get seatToAct => auction?.seatToAct;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

/// Regression coverage for a real-device report: during bidding, on a
/// short landscape screen, the "Δηλώσεις" auction-status panel (drawn
/// centered inside [OvalTableArea]'s Stack, above the fanned hand) had no
/// real height cap — it rendered at its natural size and ran right up
/// against, or past, where [HumanHandPanel] starts, reading as the hand's
/// cards overlapping its text. [OvalTableArea] now gives it an explicit
/// maxHeight via a [LayoutBuilder] + [ConstrainedBox], with a reserved
/// margin, so it can never touch the hand panel below it.
///
/// This is checked with a *real* current bid showing (not the empty "no
/// bid yet" placeholder), since that's the content the original report
/// was about, at both a realistic Medium-Phone-landscape height and a
/// tighter compact/small-height-device height.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final hand = List.generate(
      8, (i) => PlayingCard(Suit.values[i % 4], Rank.values[i % 8]));

  Future<void> pumpBiddingScreen(
    WidgetTester tester, {
    required Size windowSize,
  }) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final settings = await AppSettings.load();
    final auction = Auction(Seat.south)
      ..apply(SuitBidCall(Seat.south, Suit.spades, 80))
      ..apply(PassCall(Seat.west))
      ..apply(PassCall(Seat.north))
      ..apply(SuitBidCall(Seat.east, Suit.hearts, 90));
    final controller = _FakeGameTableData(
      phase: RoomPhase.bidding,
      viewerSeat: Seat.south,
      auction: auction,
      myHand: hand,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(child: OvalTableArea(controller: controller)),
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
    );
    await tester.pumpAndSettle();
  }

  /// A [ConstrainedBox]/[Padding]-based reservation only actually helps if
  /// it leaves *real* clearance — an assertion that merely checks
  /// `containerRect.bottom <= handTop` is always true regardless (Align
  /// can never size a Stack child taller than the Stack's own box, so the
  /// panel geometrically can't extend past where OvalTableArea's box
  /// ends, which is exactly where HumanHandPanel begins). What actually
  /// distinguishes "has its own clear space" from "touches the cards with
  /// zero gap" is a real minimum margin between the two, so that's what
  /// this asserts.
  const minClearance = 4.0;

  testWidgets(
      'a real current bid ("80 ♠ — Αριστερά") keeps clear space above the '
      'hand panel, at a realistic Medium-Phone-landscape height',
      (tester) async {
    await pumpBiddingScreen(tester, windowSize: const Size(900, 411));

    expect(tester.takeException(), isNull);
    expect(find.text('Δηλώσεις'), findsOneWidget);
    // The real bid is showing, not the empty-state placeholder.
    expect(find.text('Καμία δήλωση ακόμα'), findsNothing);

    final handTop = tester.getTopLeft(find.byType(HumanHandPanel)).dy;
    final containerRect = tester.getRect(find
        .ancestor(
          of: find.text('Δηλώσεις'),
          matching: find.byType(Container),
        )
        .first);
    expect(handTop - containerRect.bottom, greaterThanOrEqualTo(minClearance));

    // At this realistic (non-compact-tier) height, the panel's own content
    // should fit without needing the scroll fallback — the title stays
    // fully visible within the panel's own box, not scrolled away.
    final titleRect = tester.getRect(find.text('Δηλώσεις'));
    expect(containerRect.contains(titleRect.topLeft), isTrue);
    expect(containerRect.contains(titleRect.bottomRight), isTrue);
  });

  testWidgets(
      'a real current bid keeps clear space above the hand panel at a '
      'tighter compact/small-height-device height', (tester) async {
    await pumpBiddingScreen(tester, windowSize: const Size(700, 320));

    expect(tester.takeException(), isNull);
    expect(find.text('Δηλώσεις'), findsOneWidget);

    final handTop = tester.getTopLeft(find.byType(HumanHandPanel)).dy;
    final containerRect = tester.getRect(find
        .ancestor(
          of: find.text('Δηλώσεις'),
          matching: find.byType(Container),
        )
        .first);
    expect(handTop - containerRect.bottom, greaterThanOrEqualTo(minClearance));
  });
}
