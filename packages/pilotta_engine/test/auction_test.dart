import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Auction basic flow', () {
    test('three consecutive passes after a bid ends the auction', () {
      final auction = Auction(Seat.south);
      auction.apply(SuitBidCall(Seat.south, Suit.hearts, 80));
      expect(auction.isComplete, isFalse);
      auction.apply(PassCall(Seat.west));
      auction.apply(PassCall(Seat.north));
      expect(auction.isComplete, isFalse);
      auction.apply(PassCall(Seat.east));
      expect(auction.isComplete, isTrue);

      final result = auction.result();
      expect(result.isRedeal, isFalse);
      expect(result.contract!.biddingSeat, Seat.south);
      expect(result.contract!.trumpSuit, Suit.hearts);
      expect(result.contract!.value, 80);
    });

    test('all four passing with no bid is a redeal', () {
      final auction = Auction(Seat.south);
      auction.apply(PassCall(Seat.south));
      auction.apply(PassCall(Seat.west));
      auction.apply(PassCall(Seat.north));
      expect(auction.isComplete, isFalse);
      auction.apply(PassCall(Seat.east));
      expect(auction.isComplete, isTrue);
      expect(auction.result().isRedeal, isTrue);
    });

    test('bids must strictly increase in value', () {
      final auction = Auction(Seat.south);
      auction.apply(SuitBidCall(Seat.south, Suit.hearts, 80));
      expect(
        () => auction.apply(SuitBidCall(Seat.west, Suit.clubs, 80)),
        throwsA(isA<IllegalCallException>()),
      );
    });

    test('bids must be multiples of 10 starting from 80', () {
      final auction = Auction(Seat.south);
      expect(
        () => auction.apply(SuitBidCall(Seat.south, Suit.hearts, 75)),
        throwsA(isA<IllegalCallException>()),
      );
    });

    test('calling out of turn is rejected', () {
      final auction = Auction(Seat.south);
      expect(
        () => auction.apply(PassCall(Seat.west)),
        throwsA(isA<IllegalCallException>()),
      );
    });

    test('capot can be called and outbids a suit bid without needing a higher value', () {
      final auction = Auction(Seat.south);
      auction.apply(SuitBidCall(Seat.south, Suit.hearts, 80));
      auction.apply(CapotCall(Seat.west, Suit.clubs));
      auction.apply(PassCall(Seat.north));
      auction.apply(PassCall(Seat.east));
      auction.apply(PassCall(Seat.south));
      expect(auction.isComplete, isTrue);
      final contract = auction.result().contract!;
      expect(contract.isCapot, isTrue);
      expect(contract.value, kCapotValue);
      expect(contract.biddingSeat, Seat.west);
    });
  });

  group('Double / Redouble', () {
    test('only opponents may double, only bidding team may redouble', () {
      final auction = Auction(Seat.south);
      auction.apply(SuitBidCall(Seat.south, Suit.hearts, 80));

      // South's partner (north) may not double south's own bid.
      expect(
        () => auction.apply(DoubleCall(Seat.west)),
        returnsNormally,
      );
    });

    test('doubling then redoubling sets the multiplier and locks the value', () {
      final auction = Auction(Seat.south);
      auction.apply(SuitBidCall(Seat.south, Suit.hearts, 80));
      auction.apply(DoubleCall(Seat.west));
      auction.apply(RedoubleCall(Seat.north));
      auction.apply(PassCall(Seat.east));
      auction.apply(PassCall(Seat.south));
      auction.apply(PassCall(Seat.west));
      expect(auction.isComplete, isTrue);
      final contract = auction.result().contract!;
      expect(contract.multiplier, ContractMultiplier.redoubled);
      expect(contract.multiplier.factor, 4);
    });

    test('cannot double your own team\'s bid', () {
      final auction = Auction(Seat.south);
      auction.apply(SuitBidCall(Seat.south, Suit.hearts, 80));
      auction.apply(PassCall(Seat.west));
      // It is now north's turn; north is south's partner.
      expect(
        () => auction.apply(DoubleCall(Seat.north)),
        throwsA(isA<IllegalCallException>()),
      );
    });

    test('cannot raise a bid after it has been doubled', () {
      final auction = Auction(Seat.south);
      auction.apply(SuitBidCall(Seat.south, Suit.hearts, 80));
      auction.apply(DoubleCall(Seat.west));
      expect(
        () => auction.apply(SuitBidCall(Seat.north, Suit.hearts, 90)),
        throwsA(isA<IllegalCallException>()),
      );
    });
  });
}
