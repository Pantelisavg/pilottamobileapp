/// JSON (de)serialization for the pilotta_engine types that need to cross
/// the wire. Kept separate from pilotta_engine itself so the core rules
/// package has no notion of networking.
library;

import 'package:pilotta_engine/pilotta_engine.dart';

Map<String, dynamic> cardToJson(PlayingCard card) => {
      'suit': card.suit.name,
      'rank': card.rank.name,
    };

PlayingCard cardFromJson(Map<String, dynamic> json) => PlayingCard(
      Suit.values.byName(json['suit'] as String),
      Rank.values.byName(json['rank'] as String),
    );

List<Map<String, dynamic>> cardsToJson(List<PlayingCard> cards) =>
    cards.map(cardToJson).toList();

List<PlayingCard> cardsFromJson(List<dynamic> json) =>
    json.map((e) => cardFromJson(e as Map<String, dynamic>)).toList();

Map<String, dynamic> auctionCallToJson(AuctionCall call) {
  return switch (call) {
    PassCall() => {'kind': 'pass', 'seat': call.seat.name},
    SuitBidCall() => {
        'kind': 'bid',
        'seat': call.seat.name,
        'suit': call.suit.name,
        'value': call.value,
      },
    CapotCall() => {
        'kind': 'capot',
        'seat': call.seat.name,
        'suit': call.suit.name,
      },
    DoubleCall() => {'kind': 'double', 'seat': call.seat.name},
    RedoubleCall() => {'kind': 'redouble', 'seat': call.seat.name},
  };
}

AuctionCall auctionCallFromJson(Map<String, dynamic> json) {
  final seat = Seat.values.byName(json['seat'] as String);
  switch (json['kind'] as String) {
    case 'pass':
      return PassCall(seat);
    case 'bid':
      return SuitBidCall(seat, Suit.values.byName(json['suit'] as String), json['value'] as int);
    case 'capot':
      return CapotCall(seat, Suit.values.byName(json['suit'] as String));
    case 'double':
      return DoubleCall(seat);
    case 'redouble':
      return RedoubleCall(seat);
    default:
      throw FormatException('Unknown auction call kind: ${json['kind']}');
  }
}

Map<String, dynamic> contractToJson(Contract contract) => {
      'biddingSeat': contract.biddingSeat.name,
      'trumpSuit': contract.trumpSuit.name,
      'value': contract.value,
      'isCapot': contract.isCapot,
      'multiplier': contract.multiplier.name,
    };

Contract contractFromJson(Map<String, dynamic> json) => Contract(
      biddingSeat: Seat.values.byName(json['biddingSeat'] as String),
      trumpSuit: Suit.values.byName(json['trumpSuit'] as String),
      value: json['value'] as int,
      isCapot: json['isCapot'] as bool,
      multiplier: ContractMultiplier.values.byName(json['multiplier'] as String),
    );

Map<String, dynamic> declarationToJson(Declaration d) => {
      'seat': d.seat.name,
      'kind': d.kind.name,
      'cards': cardsToJson(d.cards),
      'pointValue': d.pointValue(),
    };

Map<String, dynamic> declarationOutcomeToJson(DeclarationOutcome o) => {
      'bestPerSeat': {
        for (final e in o.bestPerSeat.entries)
          if (e.value != null) e.key.name: declarationToJson(e.value!),
      },
      'forfeitedPerSeat': {
        for (final e in o.forfeitedPerSeat.entries) e.key.name: declarationToJson(e.value),
      },
      'winningTeam': o.winningTeam?.name,
      'winningTeamPoints': o.winningTeamPoints,
      'beloteSeat': o.beloteSeat?.name,
    };

Map<String, dynamic> handResultToJson(HandResult r) => {
      'contract': contractToJson(r.contract),
      'trickPoints': {for (final e in r.trickPoints.entries) e.key.name: e.value},
      'allTricksTeam': r.allTricksTeam?.name,
      'declarations': declarationOutcomeToJson(r.declarations),
      'contractMade': r.contractMade,
      'rawTotals': {for (final e in r.rawTotals.entries) e.key.name: e.value},
      'rounded': {'northSouth': r.rounded.northSouth, 'eastWest': r.rounded.eastWest},
    };
