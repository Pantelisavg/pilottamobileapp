import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/widgets/player_avatar.dart';

/// The active-turn glow used to be a fixed-intensity boxShadow; it now
/// pulses continuously while [PlayerAvatar.isActive] — these tests check
/// the glow's intensity actually changes over time, and that an inactive
/// avatar carries no glow at all (matching the pre-animation behavior).
void main() {
  BoxDecoration decorationOf(WidgetTester tester) => tester
      .widgetList<Container>(find.descendant(
          of: find.byType(PlayerAvatar), matching: find.byType(Container)))
      .map((c) => c.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.shape == BoxShape.circle && d.gradient != null);

  testWidgets('an inactive avatar has no glow', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PlayerAvatar(label: 'Αριστερά', cardCount: 8),
      ),
    ));

    expect(decorationOf(tester).boxShadow, isNull);
  });

  testWidgets('an active avatar glows and the glow keeps changing (pulsing)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PlayerAvatar(label: 'Αριστερά', cardCount: 8, isActive: true),
      ),
    ));

    await tester.pump(const Duration(milliseconds: 100));
    final first = decorationOf(tester).boxShadow!.single.blurRadius;

    await tester.pump(const Duration(milliseconds: 400));
    final second = decorationOf(tester).boxShadow!.single.blurRadius;

    expect(first, isNot(second),
        reason: 'a looping pulse should keep the glow moving, not sit at '
            'one fixed intensity');

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 1));
  });
}
