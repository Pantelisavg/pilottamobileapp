import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/widgets/table/auction_rounds_grid.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

void main() {
  group('groupCallsIntoRounds', () {
    test('groups a full auction into complete rounds of 4', () {
      final calls = [
        SuitBidCall(Seat.south, Suit.spades, 80),
        PassCall(Seat.west),
        SuitBidCall(Seat.north, Suit.hearts, 90),
        PassCall(Seat.east),
        PassCall(Seat.south),
        PassCall(Seat.west),
      ];

      final rounds = groupCallsIntoRounds(calls);

      expect(rounds, hasLength(2));
      expect(rounds[0].keys, unorderedEquals(Seat.values));
      expect(rounds[0][Seat.south], calls[0]);
      expect(rounds[0][Seat.west], calls[1]);
      expect(rounds[0][Seat.north], calls[2]);
      expect(rounds[0][Seat.east], calls[3]);
      // Second round only has south and west so far — an incomplete
      // final round, exactly as it would look mid-auction.
      expect(rounds[1].keys, unorderedEquals({Seat.south, Seat.west}));
      expect(rounds[1][Seat.south], calls[4]);
      expect(rounds[1][Seat.west], calls[5]);
    });

    test('an all-pass redeal (4 calls, one round) groups cleanly', () {
      final calls = [
        PassCall(Seat.south),
        PassCall(Seat.west),
        PassCall(Seat.north),
        PassCall(Seat.east),
      ];

      final rounds = groupCallsIntoRounds(calls);

      expect(rounds, hasLength(1));
      expect(rounds[0].keys, unorderedEquals(Seat.values));
    });

    test('no calls yet produces no rounds', () {
      expect(groupCallsIntoRounds(const []), isEmpty);
    });
  });
}
