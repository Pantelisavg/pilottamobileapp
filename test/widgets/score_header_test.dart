import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/widgets/table/game_table_data.dart';
import 'package:pilotta/widgets/table/score_header.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

/// A scriptable [GameTableData] double exposing only what [ScoreHeader]
/// reads — see throw_all_test.dart for the same noSuchMethod convention
/// used to satisfy the ~30-member interface without stubbing every one.
class _FakeGameTableData extends ChangeNotifier implements GameTableData {
  Map<Team, int> scoreTotals = {Team.northSouth: 0, Team.eastWest: 0};
  @override
  Map<Team, int> get totals => scoreTotals;

  @override
  Seat get viewerSeat => Seat.south;

  @override
  Contract? get contract => null;

  @override
  int get targetScore => 101;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

void main() {
  Future<_FakeGameTableData> pumpHeader(WidgetTester tester) async {
    final fake = _FakeGameTableData();
    await tester.pumpWidget(MaterialApp(
      home: ListenableBuilder(
        listenable: fake,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: ScoreHeader(controller: fake)),
        ),
      ),
    ));
    return fake;
  }

  testWidgets(
      'the running total counts up to a new value instead of '
      'snapping to it', (tester) async {
    final fake = await pumpHeader(tester);
    expect(find.text('0'), findsNWidgets(2));

    fake.scoreTotals = {Team.northSouth: 80, Team.eastWest: 0};
    fake.notifyListeners();
    await tester.pump();

    // Mid-animation: "our" number hasn't reached 80 yet, while the
    // opponent's untouched total (still 0) is exactly the one that should
    // remain.
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('80'), findsNothing);
    expect(find.text('0'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('80'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
