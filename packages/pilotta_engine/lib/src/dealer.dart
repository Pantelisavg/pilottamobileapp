import 'dart:math';

import 'card.dart';
import 'seat.dart';

/// Shuffles a fresh 32-card deck and deals 8 cards to each of the 4 seats.
Map<Seat, List<PlayingCard>> dealHands([Random? random]) {
  final rng = random ?? Random();
  final deck = Deck.full()..shuffle(rng);

  final hands = <Seat, List<PlayingCard>>{};
  for (var i = 0; i < Seat.values.length; i++) {
    hands[Seat.values[i]] = deck.sublist(i * 8, (i + 1) * 8);
  }
  return hands;
}
