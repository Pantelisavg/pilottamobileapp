import 'seat.dart';
import 'card.dart';

/// The lowest and highest allowed suit-bid values, and the increment
/// between allowed values (80, 90, 100, ... 800). Colloquially these are
/// spoken/displayed in shorthand tens (8 to 80) — the same convention the
/// scoreboard uses for its rounded totals — but the values here, like
/// everywhere else in the engine, are always the actual point values.
const int kMinBidValue = 80;
const int kMaxBidValue = 800;
const int kBidIncrement = 10;

/// The fixed value of a Capot call/contract.
const int kCapotValue = 250;

/// One call a player can make during the auction.
sealed class AuctionCall {
  final Seat seat;
  const AuctionCall(this.seat);
}

class PassCall extends AuctionCall {
  const PassCall(super.seat);
}

/// A normal numeric bid naming a trump suit and a game value.
class SuitBidCall extends AuctionCall {
  final Suit suit;
  final int value;
  const SuitBidCall(super.seat, this.suit, this.value);
}

/// A call for Capot: all 8 tricks, worth [kCapotValue] points.
class CapotCall extends AuctionCall {
  final Suit suit;
  const CapotCall(super.seat, this.suit);
}

/// Doubles ("Contra") the current contract's value. Only callable by an
/// opponent of the team currently holding the contract.
class DoubleCall extends AuctionCall {
  const DoubleCall(super.seat);
}

/// Redoubles ("Recontra") a doubled contract back up. Only callable by the
/// team currently holding the contract, after it has been doubled.
class RedoubleCall extends AuctionCall {
  const RedoubleCall(super.seat);
}

enum ContractMultiplier {
  none(1),
  doubled(2),
  redoubled(4);

  final int factor;
  const ContractMultiplier(this.factor);
}

/// The winning contract once the auction has settled.
class Contract {
  final Seat biddingSeat;
  final Suit trumpSuit;
  final int value;
  final bool isCapot;
  final ContractMultiplier multiplier;

  const Contract({
    required this.biddingSeat,
    required this.trumpSuit,
    required this.value,
    required this.isCapot,
    this.multiplier = ContractMultiplier.none,
  });

  Team get biddingTeam => biddingSeat.team;

  Contract copyWith({ContractMultiplier? multiplier}) => Contract(
        biddingSeat: biddingSeat,
        trumpSuit: trumpSuit,
        value: value,
        isCapot: isCapot,
        multiplier: multiplier ?? this.multiplier,
      );
}

/// Result of the auction phase: either a settled [Contract], or `null`
/// meaning every player passed and the hand must be redealt.
class AuctionResult {
  final Contract? contract;
  const AuctionResult(this.contract);

  bool get isRedeal => contract == null;
}

/// Thrown when an [AuctionCall] is not legal given the current auction
/// state.
class IllegalCallException implements Exception {
  final String message;
  IllegalCallException(this.message);
  @override
  String toString() => 'IllegalCallException: $message';
}

/// Drives the bidding phase of a hand. Players call in anti-clockwise turn
/// order starting from [startingSeat] (conventionally the seat after the
/// dealer). The auction ends once three consecutive passes follow the
/// current highest call, or all four players pass with nothing bid (a
/// redeal).
class Auction {
  final Seat startingSeat;
  final List<AuctionCall> _calls = [];
  Seat _currentSeat;

  Auction(this.startingSeat) : _currentSeat = startingSeat;

  List<AuctionCall> get calls => List.unmodifiable(_calls);

  Seat get seatToAct => _currentSeat;

  /// Whether — and how much — the current bid has been doubled/redoubled.
  /// Once this is anything but [ContractMultiplier.none], no further suit
  /// bid or Capot call is legal — only a pass, or (if just doubled) a
  /// redouble by the bidding team.
  ContractMultiplier get multiplier => _multiplier;

  /// The bid currently on the table (ignoring double/redouble), or null.
  ({Seat seat, Suit suit, int value, bool isCapot})? get currentBid {
    for (final call in _calls.reversed) {
      if (call is SuitBidCall) {
        return (
          seat: call.seat,
          suit: call.suit,
          value: call.value,
          isCapot: false
        );
      }
      if (call is CapotCall) {
        return (
          seat: call.seat,
          suit: call.suit,
          value: kCapotValue,
          isCapot: true
        );
      }
    }
    return null;
  }

  int get _consecutivePassesAtEnd {
    var count = 0;
    for (final call in _calls.reversed) {
      if (call is PassCall) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  bool get isComplete {
    if (_calls.isEmpty) return false;
    if (currentBid == null) {
      // Nobody has bid yet: complete only once all 4 have passed (redeal).
      return _consecutivePassesAtEnd >= 4;
    }
    return _consecutivePassesAtEnd >= 3;
  }

  ContractMultiplier get _multiplier {
    RedoubleCall? lastRedouble;
    DoubleCall? lastDouble;
    for (final call in _calls) {
      if (call is DoubleCall) lastDouble = call;
      if (call is RedoubleCall) lastRedouble = call;
    }
    if (lastDouble == null) return ContractMultiplier.none;
    if (lastRedouble == null) return ContractMultiplier.doubled;
    return ContractMultiplier.redoubled;
  }

  /// Validates and applies [call], advancing the turn.
  void apply(AuctionCall call) {
    if (isComplete) {
      throw IllegalCallException('Auction is already complete.');
    }
    if (call.seat != _currentSeat) {
      throw IllegalCallException(
          'It is ${_currentSeat.name}\'s turn, not ${call.seat.name}.');
    }
    _validate(call);
    _calls.add(call);
    _currentSeat = _currentSeat.next;
  }

  void _validate(AuctionCall call) {
    final bid = currentBid;
    switch (call) {
      case PassCall():
        return;
      case SuitBidCall(:final value):
        if (value < kMinBidValue) {
          throw IllegalCallException('Bid must be at least $kMinBidValue.');
        }
        if (value > kMaxBidValue) {
          throw IllegalCallException('Bid cannot exceed $kMaxBidValue.');
        }
        if ((value - kMinBidValue) % kBidIncrement != 0) {
          throw IllegalCallException(
              'Bid must increase in steps of $kBidIncrement.');
        }
        if (bid != null && value <= bid.value) {
          throw IllegalCallException(
              'Bid must exceed the current bid of ${bid.value}.');
        }
        if (bid != null && _multiplier != ContractMultiplier.none) {
          throw IllegalCallException(
              'Cannot raise a bid after it has been doubled.');
        }
      case CapotCall():
        if (bid != null && bid.isCapot) {
          throw IllegalCallException('Capot has already been called.');
        }
        if (bid != null && _multiplier != ContractMultiplier.none) {
          throw IllegalCallException(
              'Cannot raise a bid after it has been doubled.');
        }
      case DoubleCall():
        if (bid == null) {
          throw IllegalCallException('Nothing to double yet.');
        }
        if (call.seat.team == bid.seat.team) {
          throw IllegalCallException(
              'Only opponents of the bidding team may double.');
        }
        if (_multiplier != ContractMultiplier.none) {
          throw IllegalCallException('Contract has already been doubled.');
        }
      case RedoubleCall():
        if (bid == null || _multiplier != ContractMultiplier.doubled) {
          throw IllegalCallException('Nothing doubled to redouble.');
        }
        if (call.seat.team != bid.seat.team) {
          throw IllegalCallException('Only the bidding team may redouble.');
        }
    }
  }

  /// Finalizes the auction. Must only be called once [isComplete] is true.
  AuctionResult result() {
    if (!isComplete) {
      throw StateError('Auction is not complete yet.');
    }
    final bid = currentBid;
    if (bid == null) {
      return const AuctionResult(null);
    }
    return AuctionResult(Contract(
      biddingSeat: bid.seat,
      trumpSuit: bid.suit,
      value: bid.value,
      isCapot: bid.isCapot,
      multiplier: _multiplier,
    ));
  }
}
