import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('playerName defaults to "Εσύ" and persists across reloads', () async {
    final settings = await AppSettings.load();
    expect(settings.playerName, 'Εσύ');

    await settings.setPlayerName('Πέτρος');
    expect(settings.playerName, 'Πέτρος');

    final reloaded = await AppSettings.load();
    expect(reloaded.playerName, 'Πέτρος');
  });

  test(
      'setPlayerName trims whitespace and falls back to the default when blank',
      () async {
    final settings = await AppSettings.load();

    await settings.setPlayerName('  Νίκος  ');
    expect(settings.playerName, 'Νίκος');

    await settings.setPlayerName('   ');
    expect(settings.playerName, 'Εσύ');
  });

  test(
      'handAscending defaults to false (A-K-Q-...-7) and persists when toggled',
      () async {
    final settings = await AppSettings.load();
    expect(settings.handAscending, isFalse);

    await settings.setHandAscending(true);
    expect(settings.handAscending, isTrue);

    final reloaded = await AppSettings.load();
    expect(reloaded.handAscending, isTrue);
  });
}
