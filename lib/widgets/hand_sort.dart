import 'package:pilotta_engine/pilotta_engine.dart';

/// Suit display order for a sorted hand: grouped by suit, with the suit
/// groups themselves alternating red/black/red/black so adjacent groups
/// are always easy to tell apart at a glance.
const List<Suit> handSuitOrder = [
  Suit.hearts,
  Suit.clubs,
  Suit.diamonds,
  Suit.spades
];

/// Rank order within each suit group, highest first: A, K, Q, J, 10, 9, 8,
/// 7 — the plain face-value order players expect to see a hand laid out
/// in, as opposed to [plainOrderHighToLow] (A, 10, K, Q, J, 9, 8, 7), which
/// is the *trick-taking strength* order and not meant for display.
const List<Rank> handRankOrderHighToLow = declarationRankOrderHighToLow;

/// Sorts [cards] for display in a player's hand: grouped by suit (in
/// [handSuitOrder]'s red/black/red/black order), then by
/// [handRankOrderHighToLow] within each suit — highest rank first, or
/// lowest first if [ascending] (see [AppSettings.handAscending]).
List<PlayingCard> sortedForHand(List<PlayingCard> cards,
    {bool ascending = false}) {
  final sorted = [...cards];
  sorted.sort((a, b) {
    final suitDiff =
        handSuitOrder.indexOf(a.suit).compareTo(handSuitOrder.indexOf(b.suit));
    if (suitDiff != 0) return suitDiff;
    final rankDiff = handRankOrderHighToLow
        .indexOf(a.rank)
        .compareTo(handRankOrderHighToLow.indexOf(b.rank));
    return ascending ? -rankDiff : rankDiff;
  });
  return sorted;
}
