import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/screens/home_screen.dart';
import 'package:pilotta/settings/app_settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression coverage for "home screen should fit fully within the
/// viewport without requiring the user to scroll, on standard phone
/// screen sizes" — checked at a realistic Medium-Phone-landscape window
/// size and at a tighter, small-height-device window size. Asserts both
/// that no RenderFlex overflow fires and that the outer scroll view's
/// content actually fits (maxScrollExtent stays at/near zero), since a
/// scrollable that silently grew past the viewport would hide content
/// just as much as an overflow would.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpHome(WidgetTester tester, Size windowSize) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final settings = await AppSettings.load();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'fits a realistic Medium-Phone-landscape viewport without overflow '
      'or needing to scroll', (tester) async {
    await pumpHome(tester, const Size(900, 411));

    expect(tester.takeException(), isNull);

    // The outer SingleChildScrollView's own Scrollable is the shallowest
    // match — the name field's EditableText owns a second, deeper one.
    final position = tester
        .state<ScrollableState>(find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Scrollable),
            )
            .first)
        .position;
    expect(position.maxScrollExtent, lessThanOrEqualTo(1.0));
  });

  testWidgets('fits a tighter, small-height-device viewport without overflow',
      (tester) async {
    await pumpHome(tester, const Size(700, 320));

    expect(tester.takeException(), isNull);
  });
}
