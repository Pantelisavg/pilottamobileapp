import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/widgets/table/oval_geometry.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

void main() {
  group('ovalSeatFraction', () {
    test('the viewer\'s own seat sits at the bottom center', () {
      final f = ovalSeatFraction(Seat.south, Seat.south);
      expect(f.dx, closeTo(0.5, 1e-9));
      expect(f.dy, greaterThan(0.5)); // below center
    });

    test('the partner (straight across) sits at the top center', () {
      final f = ovalSeatFraction(Seat.north, Seat.south);
      expect(f.dx, closeTo(0.5, 1e-9));
      expect(f.dy, lessThan(0.5)); // above center
    });

    test(
        'the seat that acts right after the viewer (offset 1) sits on the '
        'right, and the one right before (offset 3) sits on the left', () {
      final right = ovalSeatFraction(Seat.west, Seat.south); // south->west
      final left = ovalSeatFraction(Seat.east, Seat.south); // east->south
      expect(right.dx, greaterThan(0.5));
      expect(right.dy, closeTo(0.5, 1e-9));
      expect(left.dx, lessThan(0.5));
      expect(left.dy, closeTo(0.5, 1e-9));
    });

    test('every fraction stays within the unit square, inset from the edge',
        () {
      for (final me in Seat.values) {
        for (final seat in Seat.values) {
          final f = ovalSeatFraction(seat, me);
          expect(f.dx, inInclusiveRange(0.0, 1.0));
          expect(f.dy, inInclusiveRange(0.0, 1.0));
          // Strictly inside the true corners — kOvalSeatInset < 1.
          expect(f.dx, isNot(0.0));
          expect(f.dx, isNot(1.0));
        }
      }
    });

    test(
        'is rotation-consistent: relative seating never changes with which '
        'seat is "me", only which seat sits where', () {
      // Whoever is "me" always sees their partner at the same fractional
      // spot, since the whole layout just rotates with the viewer.
      for (final me in Seat.values) {
        final partnerFraction = ovalSeatFraction(me.partner, me);
        expect(partnerFraction, ovalSeatFraction(Seat.north, Seat.south));
      }
    });
  });

  group('ovalSeatAlignment', () {
    test('maps fractions into Alignment\'s -1..1 coordinate space', () {
      final a = ovalSeatAlignment(Seat.north, Seat.south);
      expect(a.x, closeTo(0.0, 1e-9));
      expect(a.y, lessThan(0.0));
    });
  });
}
