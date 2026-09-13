import 'package:pilotta_engine/pilotta_engine.dart';

/// Suit display order for a sorted hand: grouped by suit, with the suit
/// groups themselves alternating red/black/red/black so adjacent groups
/// are always easy to tell apart at a glance.
const List<Suit> handSuitOrder = [Suit.hearts, Suit.clubs, Suit.diamonds, Suit.spades];

/// Sorts [cards] for display in a player's hand: grouped by suit (in
/// [handSuitOrder]'s red/black/red/black order), highest rank first within
/// each suit.
List<PlayingCard> sortedForHand(List<PlayingCard> cards) {
  final sorted = [...cards];
  sorted.sort((a, b) {
    final suitDiff = handSuitOrder.indexOf(a.suit).compareTo(handSuitOrder.indexOf(b.suit));
    if (suitDiff != 0) return suitDiff;
    return plainOrderHighToLow.indexOf(a.rank).compareTo(plainOrderHighToLow.indexOf(b.rank));
  });
  return sorted;
}
