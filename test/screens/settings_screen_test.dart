import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/screens/settings_screen.dart';
import 'package:pilotta/settings/app_settings.dart';
import 'package:pilotta/settings/card_deck_style.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'picking the modern deck updates and persists AppSettings.deckStyle',
      (tester) async {
    final settings = await AppSettings.load();
    expect(settings.deckStyle, CardDeckStyle.classic);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    // The deck picker sits further down the settings list than the
    // default test surface's viewport shows — scroll it fully into view
    // (not just far enough to exist in the tree) before tapping.
    await tester.dragUntilVisible(
      find.text('Μοντέρνα'),
      find.byType(ListView),
      const Offset(0, -100),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -150));
    await tester.pump();
    await tester.tap(find.text('Μοντέρνα'));
    await tester.pump();

    expect(settings.deckStyle, CardDeckStyle.modern);

    // Persisted: a fresh load off the same (mocked) prefs backend sees the
    // same choice, not just the in-memory value.
    final reloaded = await AppSettings.load();
    expect(reloaded.deckStyle, CardDeckStyle.modern);
  });
}
