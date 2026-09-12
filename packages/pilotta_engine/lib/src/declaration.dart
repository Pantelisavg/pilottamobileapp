import 'card.dart';
import 'seat.dart';

/// Standard rank order used to evaluate sequence length/height, independent
/// of which suit is trump: A, K, Q, J, 10, 9, 8, 7.
const List<Rank> declarationRankOrderHighToLow = [
  Rank.ace,
  Rank.king,
  Rank.queen,
  Rank.jack,
  Rank.ten,
  Rank.nine,
  Rank.eight,
  Rank.seven,
];

/// Ranks that can form a declarable carre (four of a kind). Sevens and
/// eights are worth zero points in every suit and are excluded — only
/// Jacks (200), Nines (150), and Aces/Tens/Kings/Queens (100) count.
const List<Rank> _declarableCarreRanks = [
  Rank.jack,
  Rank.nine,
  Rank.ace,
  Rank.ten,
  Rank.king,
  Rank.queen,
];

enum DeclarationKind { sequence, carre }

/// A declared combination: a run of 3+ consecutive same-suit cards, or four
/// of a kind ("carre").
class Declaration {
  final Seat seat;
  final DeclarationKind kind;
  final List<PlayingCard> cards;

  Declaration._(this.seat, this.kind, this.cards);

  factory Declaration.sequence(Seat seat, List<PlayingCard> cards) {
    assert(cards.length >= 3);
    assert(cards.every((c) => c.suit == cards.first.suit));
    return Declaration._(seat, DeclarationKind.sequence, List.unmodifiable(cards));
  }

  factory Declaration.carre(Seat seat, List<PlayingCard> cards) {
    assert(cards.length == 4);
    assert(cards.every((c) => c.rank == cards.first.rank));
    return Declaration._(seat, DeclarationKind.carre, List.unmodifiable(cards));
  }

  int get length => cards.length;

  Suit get suit => cards.first.suit;

  Rank get carreRank => cards.first.rank;

  /// The highest card in a sequence, by [declarationRankOrderHighToLow].
  Rank get highCard {
    return cards
        .map((c) => c.rank)
        .reduce((a, b) => declarationRankOrderHighToLow.indexOf(a) <
                declarationRankOrderHighToLow.indexOf(b)
            ? a
            : b);
  }

  int pointValue() {
    if (kind == DeclarationKind.carre) {
      switch (carreRank) {
        case Rank.jack:
          return 200;
        case Rank.nine:
          return 150;
        default:
          return 100;
      }
    }
    switch (length) {
      case 3:
        return 20;
      case 4:
        return 50;
      default:
        return 100; // 5 or more
    }
  }

  /// Ranking used only to break ties between two carres of different rank,
  /// per the "four Jacks > four 9s > other carre" ordering.
  int _carreRankWeight() {
    switch (carreRank) {
      case Rank.jack:
        return 2;
      case Rank.nine:
        return 1;
      default:
        return 0;
    }
  }

  /// Compares this declaration against [other] primarily by point value —
  /// 200 (four Jacks) > 150 (four 9s) > 100 (a sequence of 5+, *or* a carre
  /// of Aces/Tens/Kings/Queens — these two are the same named tier and
  /// rank equally) > 50 (sequence of 4) > 20 (sequence of 3) — per the
  /// rules' own grouping, not the more common Belote convention of "a
  /// carre always outranks any sequence" regardless of value.
  ///
  /// Ties within a tier are broken by: for two carres, rank (Jacks > 9s >
  /// other — moot in practice since equal-value carres are already the
  /// same "other" tier); for two sequences, higher top card, then trump
  /// suit. A carre and a sequence tied at exactly the same value (the one
  /// concrete case: a 100-point carre vs. a 5+ sequence) have no ordering
  /// rule specified anywhere in the rules, so they're treated as a genuine
  /// tie — as with any other unresolved tie, neither declaration wins.
  ///
  /// Returns >0 if this beats other, <0 if other beats this, 0 if tied
  /// (no declaration should win — rare edge case).
  int compareTo(Declaration other, Suit trumpSuit) {
    final valueDiff = pointValue() - other.pointValue();
    if (valueDiff != 0) return valueDiff;

    if (kind != other.kind) return 0; // e.g. 100-carre vs. 5+ sequence: tied.

    if (kind == DeclarationKind.carre) {
      final weightDiff = _carreRankWeight() - other._carreRankWeight();
      if (weightDiff != 0) return weightDiff;
      final rankDiff = declarationRankOrderHighToLow.indexOf(other.carreRank) -
          declarationRankOrderHighToLow.indexOf(carreRank);
      return rankDiff;
    }
    // Both sequences at the same value tier — for length 3 or 4 that
    // already means identical length, but two 5+ runs of different
    // lengths (e.g. 5 vs. 6 cards) both score 100 and still need a
    // tiebreak, so length comes first, then top card, then trump suit.
    if (length != other.length) return length - other.length;
    final highDiff = declarationRankOrderHighToLow.indexOf(other.highCard) -
        declarationRankOrderHighToLow.indexOf(highCard);
    if (highDiff != 0) return highDiff;
    final thisTrump = suit == trumpSuit;
    final otherTrump = other.suit == trumpSuit;
    if (thisTrump == otherTrump) return 0;
    return thisTrump ? 1 : -1;
  }
}

/// Finds every sequence (length >= 3) and carre present in [hand].
/// A hand can contain multiple overlapping declarations (e.g. a 4-run also
/// contains two 3-runs); per the rules only the single highest-value
/// declaration a player holds is called, so callers typically want
/// [bestDeclaration] rather than the full list.
List<Declaration> findDeclarations(Seat seat, List<PlayingCard> hand) {
  final declarations = <Declaration>[];

  for (final suit in Suit.values) {
    final suited = hand.where((c) => c.suit == suit).toList()
      ..sort((a, b) => declarationRankOrderHighToLow
          .indexOf(a.rank)
          .compareTo(declarationRankOrderHighToLow.indexOf(b.rank)));
    if (suited.length < 3) continue;

    // Walk consecutive runs using declarationRankOrderHighToLow adjacency.
    var runStart = 0;
    for (var i = 1; i <= suited.length; i++) {
      final broke = i == suited.length ||
          declarationRankOrderHighToLow.indexOf(suited[i].rank) !=
              declarationRankOrderHighToLow.indexOf(suited[i - 1].rank) + 1;
      if (broke) {
        final runLength = i - runStart;
        if (runLength >= 3) {
          declarations.add(
              Declaration.sequence(seat, suited.sublist(runStart, i)));
        }
        runStart = i;
      }
    }
  }

  // Sevens and eights are worthless cards and don't form a declarable
  // carre — only Jacks, Nines, Aces, Tens, Kings and Queens do.
  for (final rank in _declarableCarreRanks) {
    final matching = hand.where((c) => c.rank == rank).toList();
    if (matching.length == 4) {
      declarations.add(Declaration.carre(seat, matching));
    }
  }

  return declarations;
}

/// The single best declaration a player would call (highest point value;
/// carre beats sequence; longer/higher sequence wins ties), or null if the
/// hand has none.
Declaration? bestDeclaration(Seat seat, List<PlayingCard> hand, Suit trumpSuit) {
  final all = findDeclarations(seat, hand);
  if (all.isEmpty) return null;
  return all.reduce((a, b) => a.compareTo(b, trumpSuit) >= 0 ? a : b);
}
