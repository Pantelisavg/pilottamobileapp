import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:test/test.dart';

void main() {
  group('SimpleBot.decideBid', () {
    test(
        'never raises once the bid has been doubled, even with a strong hand '
        'in the bid suit — regression for the "Cannot raise a bid after it '
        'has been doubled" crash', () {
      final auction = Auction(Seat.south)
        ..apply(SuitBidCall(Seat.south, Suit.spades, 80))
        ..apply(DoubleCall(Seat.west))
        ..apply(PassCall(Seat.north));
      expect(auction.multiplier, ContractMultiplier.doubled);
      expect(auction.seatToAct, Seat.east);

      // A hand strong enough in spades that the old (multiplier-blind)
      // logic would have raised the bid — which auction.apply would then
      // reject as illegal.
      final strongSpadesHand = [
        const PlayingCard(Suit.spades, Rank.jack),
        const PlayingCard(Suit.spades, Rank.nine),
        const PlayingCard(Suit.spades, Rank.ace),
        const PlayingCard(Suit.hearts, Rank.seven),
        const PlayingCard(Suit.hearts, Rank.eight),
        const PlayingCard(Suit.clubs, Rank.seven),
        const PlayingCard(Suit.clubs, Rank.eight),
        const PlayingCard(Suit.diamonds, Rank.seven),
      ];

      final bot = SimpleBot();
      final call = bot.decideBid(auction, Seat.east, strongSpadesHand);

      expect(call, isA<PassCall>());
      // Applying it must not throw — proving it's actually legal, not just
      // the right type.
      auction.apply(call);
    });
  });
}
