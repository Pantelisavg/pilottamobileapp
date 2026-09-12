import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/widgets/bidding_panel.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

void main() {
  Future<void> pump(WidgetTester tester, Auction auction) => tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BiddingPanel(auction: auction, seat: Seat.south, onCall: (_) {}),
        ),
      ));

  testWidgets('slider bounds are the real 80-800 range, not the old 250 cap', (tester) async {
    final auction = Auction(Seat.south);
    await pump(tester, auction);

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, kMinBidValue.toDouble());
    expect(slider.max, kMaxBidValue.toDouble());
    expect(slider.max, isNot(250));
  });

  testWidgets('dragging the slider all the way right reaches 800 (shorthand 80)', (tester) async {
    final auction = Auction(Seat.south);
    await pump(tester, auction);

    // A drag far past the track's right edge always clamps to the max,
    // regardless of the exact pixel width of the track.
    await tester.drag(find.byType(Slider), const Offset(5000, 0));
    await tester.pump();

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, kMaxBidValue.toDouble());
    expect(find.text('${kMaxBidValue ~/ 10}'), findsOneWidget); // "80" shown
  });

  testWidgets('the slider can jump straight to a mid-range value in one drag, '
      'not just one step at a time', (tester) async {
    final auction = Auction(Seat.south);
    await pump(tester, auction);

    final trackWidth = tester.getSize(find.byType(Slider)).width;
    final sliderTopLeft = tester.getTopLeft(find.byType(Slider));
    await tester.dragFrom(
      sliderTopLeft + const Offset(5, 20),
      Offset(trackWidth / 2, 0),
    );
    await tester.pump();

    final slider = tester.widget<Slider>(find.byType(Slider));
    final shorthand = slider.value ~/ 10;
    // Well past what a handful of "+" taps would reach, and well past the
    // old 250 (shorthand 25) ceiling — confirms a single drag reaches deep
    // into the range instead of requiring dozens of taps.
    expect(shorthand, greaterThan(25));
  });

  testWidgets('the +/- buttons still fine-tune by one step (10 actual)', (tester) async {
    final auction = Auction(Seat.south);
    await pump(tester, auction);

    final before = tester.widget<Slider>(find.byType(Slider)).value;
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    final after = tester.widget<Slider>(find.byType(Slider)).value;
    expect(after, before + kBidIncrement);
  });
}
