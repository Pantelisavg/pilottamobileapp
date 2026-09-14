import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/settings/app_settings.dart';
import 'package:pilotta/widgets/table/hand_sort_toggle_button.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppSettings> pumpButton(WidgetTester tester) async {
    final settings = await AppSettings.load();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: const MaterialApp(
          home: Scaffold(body: HandSortToggleButton()),
        ),
      ),
    );
    return settings;
  }

  testWidgets(
      'defaults to high-to-low and flips AppSettings.handAscending '
      'on tap', (tester) async {
    final settings = await pumpButton(tester);
    expect(settings.handAscending, isFalse);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);

    await tester.tap(find.byType(HandSortToggleButton));
    await tester.pump();

    expect(settings.handAscending, isTrue);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

    await tester.tap(find.byType(HandSortToggleButton));
    await tester.pump();

    expect(settings.handAscending, isFalse);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
  });
}
