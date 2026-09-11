import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/main.dart';
import 'package:pilotta/screens/local_game_screen.dart';
import 'package:pilotta/widgets/playing_card_widget.dart';

void main() {
  testWidgets('home screen offers a local game against bots', (tester) async {
    await tester.pumpWidget(const PilottaApp());

    expect(find.text('ΠΙΛΟΤΤΑ'), findsOneWidget);
    expect(find.text('Παιχνίδι με Bots'), findsOneWidget);
    expect(find.text('Online Παιχνίδι'), findsOneWidget);
  });

  testWidgets('starting a local game deals 8 cards to the human seat', (tester) async {
    await tester.pumpWidget(const PilottaApp());

    await tester.tap(find.text('Παιχνίδι με Bots'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(LocalGameScreen), findsOneWidget);
    final humanCards = find.descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(PlayingCardWidget),
    );
    expect(tester.widgetList(humanCards).length, 8);
  });
}
