import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/main.dart';
import 'package:pilotta/screens/local_game_screen.dart';
import 'package:pilotta/settings/app_settings.dart';
import 'package:pilotta/widgets/fanned_hand.dart';
import 'package:pilotta/widgets/playing_card_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home screen offers a local game against bots', (tester) async {
    final settings = await AppSettings.load();
    await tester.pumpWidget(PilottaApp(settings: settings));

    expect(find.text('ΠΙΛΟΤΤΑ'), findsOneWidget);
    expect(find.text('Παιχνίδι με Bots'), findsOneWidget);
    expect(find.text('Online Παιχνίδι'), findsOneWidget);
  });

  testWidgets('starting a local game deals 8 cards to the human seat', (tester) async {
    final settings = await AppSettings.load();
    await tester.pumpWidget(PilottaApp(settings: settings));

    await tester.tap(find.text('Παιχνίδι με Bots'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(LocalGameScreen), findsOneWidget);
    final humanCards = find.descendant(
      of: find.byType(FannedHand),
      matching: find.byType(PlayingCardWidget),
    );
    expect(tester.widgetList(humanCards).length, 8);
  });
}
