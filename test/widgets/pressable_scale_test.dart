import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/widgets/pressable_scale.dart';

/// PressableScale is a purely visual pointer-down/up wrapper (deliberately
/// not a tap recognizer, so it never competes with a child's own InkWell
/// for the tap) — these check the scale actually changes on press/release,
/// and that a wrapped InkWell's own tap still fires normally underneath it.
void main() {
  double scaleOf(WidgetTester tester) =>
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

  testWidgets('scales down while pressed and back up on release',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PressableScale(child: SizedBox(width: 100, height: 40)),
      ),
    ));

    expect(scaleOf(tester), 1.0);

    final gesture = await tester
        .startGesture(tester.getCenter(find.byType(PressableScale)));
    await tester.pump();
    expect(scaleOf(tester), lessThan(1.0));

    await gesture.up();
    await tester.pump();
    expect(scaleOf(tester), 1.0);
  });

  testWidgets('does not block the wrapped widget\'s own tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PressableScale(
          child: InkWell(
            onTap: () => tapped = true,
            child: const SizedBox(width: 100, height: 40),
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
