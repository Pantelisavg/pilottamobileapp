import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/screens/how_to_play_screen.dart';
import 'package:pilotta/widgets/table/cheat_sheet_button.dart';
import 'package:pilotta/widgets/table/leave_table_button.dart';
import 'package:pilotta/widgets/table/leave_table_scope.dart';

/// Neither button needs a real GameTableData, so these tests pump a
/// minimal stand-in table screen instead of a full LocalGameScreen — the
/// real screen runs a live bot-bidding game with real Timers, which would
/// make these purely-navigational tests dependent on how far a random game
/// happens to progress in the meantime.
void main() {
  // Pushed on top of a "menu" route rather than used as the app's only
  // route, so popUntil(isFirst) — what leaving the table actually does —
  // has somewhere real to land on, matching how the game screens sit on
  // top of the home screen.
  Future<void> pumpTableScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: const Center(child: Text('Αρχική'))),
      ),
    );
    final context = tester.element(find.text('Αρχική'));
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LeaveTableScope(
        child: Scaffold(
          appBar: AppBar(actions: const [
            CheatSheetButton(),
            LeaveTableButton(),
          ]),
          body: const Center(child: Text('Τραπέζι')),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('cheat-sheet button opens the rules reference and pops back',
      (tester) async {
    await pumpTableScreen(tester);

    await tester.tap(find.byType(CheatSheetButton));
    await tester.pumpAndSettle();
    expect(find.byType(HowToPlayScreen), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(HowToPlayScreen),
      matching: find.byIcon(Icons.arrow_back),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Τραπέζι'), findsOneWidget);
  });

  testWidgets(
      'leave-table button asks for confirmation, and cancelling stays on '
      'the table', (tester) async {
    await pumpTableScreen(tester);

    await tester.tap(find.byType(LeaveTableButton));
    await tester.pumpAndSettle();
    expect(find.text('Αποχώρηση από το τραπέζι'), findsOneWidget);

    await tester.tap(find.text('Άκυρο'));
    await tester.pumpAndSettle();
    expect(find.text('Τραπέζι'), findsOneWidget);
  });

  testWidgets('confirming leave-table pops the table screen', (tester) async {
    await pumpTableScreen(tester);

    await tester.tap(find.byType(LeaveTableButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Αποχώρηση'));
    await tester.pumpAndSettle();

    expect(find.text('Τραπέζι'), findsNothing);
    expect(find.text('Αρχική'), findsOneWidget);
  });

  testWidgets(
      'the system back gesture goes through the same confirmation as the '
      'explicit button', (tester) async {
    await pumpTableScreen(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Αποχώρηση από το τραπέζι'), findsOneWidget);
  });
}
