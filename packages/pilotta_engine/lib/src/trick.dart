import 'card.dart';
import 'seat.dart';

/// A single trick in progress or completed: up to 4 cards, one per seat,
/// played in turn order starting from [leader].
class Trick {
  final Seat leader;
  final Suit trumpSuit;

  /// House-rule variant: when true, a player following suit in ANY suit
  /// (not just trump) must beat the current best card of that suit if able
  /// to — not just when trump is the led suit or when forced to cut in with
  /// trump. Standard rule (false, the default) only requires overtaking in
  /// trump; plain-suit followers may always play any card of that suit.
  final bool mustOvertrumpAllSuits;

  final List<({Seat seat, PlayingCard card})> _played = [];

  Trick({
    required this.leader,
    required this.trumpSuit,
    this.mustOvertrumpAllSuits = false,
  });

  List<({Seat seat, PlayingCard card})> get played => List.unmodifiable(_played);

  bool get isEmpty => _played.isEmpty;
  bool get isComplete => _played.length == 4;

  Suit? get ledSuit => _played.isEmpty ? null : _played.first.card.suit;

  Seat get seatToPlay => _played.isEmpty ? leader : _played.last.seat.next;

  /// The card currently winning the trick, and who played it.
  ({Seat seat, PlayingCard card})? get currentWinner {
    if (_played.isEmpty) return null;
    var best = _played.first;
    for (final entry in _played.skip(1)) {
      if (_beats(entry.card, best.card)) best = entry;
    }
    return best;
  }

  bool _beats(PlayingCard candidate, PlayingCard current) {
    final candidateIsTrump = candidate.suit == trumpSuit;
    final currentIsTrump = current.suit == trumpSuit;
    if (candidateIsTrump && !currentIsTrump) return true;
    if (!candidateIsTrump && currentIsTrump) return false;
    if (candidate.suit != current.suit) {
      // Neither is trump and suits differ: candidate didn't follow suit or
      // beat trump, so it cannot win.
      return false;
    }
    return candidate.outranks(current, trumpSuit);
  }

  /// Every card [seat] is legally allowed to play from [hand], given the
  /// state of this trick so far. Implements, in order of precedence:
  /// 1. Must follow the led suit if holding any card of that suit.
  /// 1a. Following suit in a *plain* (non-trump) suit is normally free —
  ///     no obligation to beat the current best card of that suit — unless
  ///     [mustOvertrumpAllSuits] is enabled, in which case the same
  ///     must-beat-if-able requirement as rule 2 applies here too, as long
  ///     as nobody has cut in with trump yet (once a trump has been played,
  ///     a plain-suit card can never win regardless, so there's nothing to
  ///     overtake).
  /// 2. If following suit in the trump suit (or forced to play trump per
  ///    rule 3), must overtake the current best trump if able to.
  /// 3. If unable to follow the led suit, must play a trump if holding any.
  /// 4. Otherwise, any card may be played (discard).
  List<PlayingCard> legalPlays(List<PlayingCard> hand) {
    if (isEmpty) return List.unmodifiable(hand);

    final led = ledSuit!;
    final sameSuit = hand.where((c) => c.suit == led).toList();
    final best = currentWinner!.card;
    final trumpInHand = hand.where((c) => c.suit == trumpSuit).toList();

    if (sameSuit.isNotEmpty) {
      final nobodyHasTrumpedIn = best.suit == led;
      final mustTryToWin =
          led == trumpSuit || (mustOvertrumpAllSuits && nobodyHasTrumpedIn);
      if (mustTryToWin) {
        // Following suit and required to try to win: beat the current best
        // card of the led suit if possible ("must overtrump if able to").
        final overtaking =
            sameSuit.where((c) => c.outranks(best, trumpSuit)).toList();
        return overtaking.isNotEmpty ? overtaking : sameSuit;
      }
      return sameSuit;
    }

    if (trumpInHand.isNotEmpty) {
      // Void in the led suit: must trump. If the trick has already been
      // trumped, must overtake it if possible.
      if (best.suit == trumpSuit) {
        final overtaking =
            trumpInHand.where((c) => c.outranks(best, trumpSuit)).toList();
        return overtaking.isNotEmpty ? overtaking : trumpInHand;
      }
      return trumpInHand;
    }

    // Void in led suit and holding no trump: free discard.
    return List.unmodifiable(hand);
  }

  void play(Seat seat, PlayingCard card) {
    if (isComplete) {
      throw StateError('Trick already has 4 cards.');
    }
    if (seat != seatToPlay) {
      throw StateError('It is ${seatToPlay.name}\'s turn to play.');
    }
    _played.add((seat: seat, card: card));
  }

  Seat get winner {
    if (!isComplete) {
      throw StateError('Trick is not complete yet.');
    }
    return currentWinner!.seat;
  }

  /// Sum of all card point values in this trick (does not include the
  /// +10 last-trick bonus, which is tracked at the hand level).
  int get points => _played.fold(0, (sum, e) => sum + e.card.pointValue(trumpSuit));
}
