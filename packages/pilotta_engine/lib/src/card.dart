/// The four suits of a 32-card Pilotta deck.
enum Suit {
  hearts,
  diamonds,
  clubs,
  spades;

  bool get isRed => this == Suit.hearts || this == Suit.diamonds;
}

/// The eight ranks present in a 32-card deck (7 through Ace).
enum Rank {
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace;

  String get short {
    switch (this) {
      case Rank.seven:
        return '7';
      case Rank.eight:
        return '8';
      case Rank.nine:
        return '9';
      case Rank.ten:
        return '10';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
      case Rank.ace:
        return 'A';
    }
  }
}

/// Card point values and trick-taking order differ depending on whether the
/// card's suit is the trump suit for the current hand.
///
/// Trump order (high to low): J, 9, A, 10, K, Q, 8, 7
/// Plain order (high to low): A, 10, K, Q, J, 9, 8, 7
const List<Rank> trumpOrderHighToLow = [
  Rank.jack,
  Rank.nine,
  Rank.ace,
  Rank.ten,
  Rank.king,
  Rank.queen,
  Rank.eight,
  Rank.seven,
];

const List<Rank> plainOrderHighToLow = [
  Rank.ace,
  Rank.ten,
  Rank.king,
  Rank.queen,
  Rank.jack,
  Rank.nine,
  Rank.eight,
  Rank.seven,
];

const Map<Rank, int> trumpCardPoints = {
  Rank.jack: 20,
  Rank.nine: 14,
  Rank.ace: 11,
  Rank.ten: 10,
  Rank.king: 4,
  Rank.queen: 3,
  Rank.eight: 0,
  Rank.seven: 0,
};

const Map<Rank, int> plainCardPoints = {
  Rank.ace: 11,
  Rank.ten: 10,
  Rank.king: 4,
  Rank.queen: 3,
  Rank.jack: 2,
  Rank.nine: 0,
  Rank.eight: 0,
  Rank.seven: 0,
};

/// A single playing card. Immutable and comparable by identity of
/// (suit, rank) — a 32-card deck has exactly one of each.
class PlayingCard {
  final Suit suit;
  final Rank rank;

  const PlayingCard(this.suit, this.rank);

  /// Point value of this card when [trumpSuit] is the trump suit for the
  /// current hand.
  int pointValue(Suit trumpSuit) {
    return suit == trumpSuit ? trumpCardPoints[rank]! : plainCardPoints[rank]!;
  }

  /// Rank order index within its own suit context (0 = highest).
  /// Uses trump ordering if [trumpSuit] equals this card's suit, otherwise
  /// plain ordering.
  int _orderIndex(Suit trumpSuit) {
    final order = suit == trumpSuit ? trumpOrderHighToLow : plainOrderHighToLow;
    return order.indexOf(rank);
  }

  /// Returns true if this card outranks [other] assuming both are of the
  /// same suit (or comparing trump vs trump). Lower index = higher rank.
  bool outranks(PlayingCard other, Suit trumpSuit) {
    assert(suit == other.suit);
    return _orderIndex(trumpSuit) < other._orderIndex(trumpSuit);
  }

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => '${rank.short}${_suitSymbol(suit)}';

  static String _suitSymbol(Suit s) {
    switch (s) {
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
      case Suit.spades:
        return '♠';
    }
  }
}

/// A full, ordered 32-card deck.
class Deck {
  static List<PlayingCard> full() {
    final cards = <PlayingCard>[];
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        cards.add(PlayingCard(suit, rank));
      }
    }
    return cards;
  }
}
