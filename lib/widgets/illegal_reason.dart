import 'package:pilotta_engine/pilotta_engine.dart';

/// A short Greek explanation of why [card] isn't currently a legal play in
/// [trick] for a hand holding [hand] — purely for a UI tooltip; mirrors the
/// precedence order in [Trick.legalPlays] without affecting legality itself.
String illegalPlayReason(Trick trick, List<PlayingCard> hand, PlayingCard card) {
  if (trick.isEmpty) return 'Δεν είναι έγκυρη κίνηση.';
  final led = trick.ledSuit!;
  final sameSuit = hand.where((c) => c.suit == led).toList();
  final trumpInHand = hand.where((c) => c.suit == trick.trumpSuit).toList();

  if (sameSuit.isNotEmpty) {
    if (card.suit != led) return 'Πρέπει να ακολουθήσεις το χρώμα που παίχτηκε.';
    return 'Πρέπει να ανεβείς σε αυτό το χρώμα αν μπορείς.';
  }
  if (trumpInHand.isNotEmpty) {
    if (card.suit != trick.trumpSuit) return 'Δεν έχεις το χρώμα — πρέπει να κόψεις με ατού.';
    return 'Πρέπει να ανεβάσεις το ατού αν μπορείς.';
  }
  return 'Δεν είναι έγκυρη κίνηση.';
}
