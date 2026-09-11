import 'dart:math';

import 'auction.dart';
import 'card.dart';
import 'declaration.dart';
import 'seat.dart';
import 'trick.dart';

/// A simple heuristic AI player: not a strong Pilotta player, just capable
/// enough to make legal, reasonable-looking decisions so a human can play
/// hotseat against bots without a network opponent.
class SimpleBot {
  final Random _random;
  SimpleBot([Random? random]) : _random = random ?? Random();

  /// Decides a bidding call given the current auction and this bot's hand.
  /// Bids the trump suit it holds the most (weighted) strength in, if that
  /// strength clears a simple threshold; otherwise passes. Never doubles or
  /// redoubles (kept simple and non-aggressive).
  AuctionCall decideBid(Auction auction, Seat seat, List<PlayingCard> hand) {
    final bid = auction.currentBid;

    Suit? bestSuit;
    var bestStrength = -1;
    for (final suit in Suit.values) {
      final strength = _handStrength(hand, suit);
      if (strength > bestStrength) {
        bestStrength = strength;
        bestSuit = suit;
      }
    }

    // Rough mapping from hand strength to a supportable contract value.
    final supportable = kMinBidValue + (bestStrength ~/ 6) * kBidIncrement;

    if (bid == null) {
      if (bestStrength >= 12) {
        return SuitBidCall(seat, bestSuit!, kMinBidValue);
      }
      return PassCall(seat);
    }

    final nextValue = bid.value + kBidIncrement;
    if (bid.seat.team != seat.team &&
        !bid.isCapot &&
        nextValue <= supportable &&
        bestStrength >= 14) {
      return SuitBidCall(seat, bestSuit!, nextValue);
    }
    return PassCall(seat);
  }

  int _handStrength(List<PlayingCard> hand, Suit trumpSuit) {
    var strength = 0;
    for (final card in hand) {
      if (card.suit == trumpSuit) {
        strength += switch (card.rank) {
          Rank.jack => 8,
          Rank.nine => 6,
          Rank.ace => 4,
          Rank.ten => 3,
          Rank.king => 2,
          Rank.queen => 2,
          _ => 0,
        };
      } else {
        strength += switch (card.rank) {
          Rank.ace => 3,
          Rank.ten => 2,
          _ => 0,
        };
      }
    }
    return strength;
  }

  /// Picks a legal card to play: prefers winning the trick cheaply, and
  /// otherwise discards the lowest-value card.
  PlayingCard decidePlay(Trick trick, List<PlayingCard> hand, Suit trumpSuit) {
    final legal = trick.legalPlays(hand);
    if (legal.length == 1) return legal.first;

    legal.sort((a, b) => a.pointValue(trumpSuit).compareTo(b.pointValue(trumpSuit)));
    final lowestValue = legal.first.pointValue(trumpSuit);
    final cheapest = legal.where((c) => c.pointValue(trumpSuit) == lowestValue).toList();
    return cheapest[_random.nextInt(cheapest.length)];
  }

  /// Whether this bot chooses to announce its best declaration, if any.
  /// Always announces — declarations are free points with no downside.
  Declaration? decideDeclaration(Seat seat, List<PlayingCard> hand, Suit trumpSuit) {
    return bestDeclaration(seat, hand, trumpSuit);
  }
}
