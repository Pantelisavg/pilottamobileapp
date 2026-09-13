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
      return SuitBidCall(seat, Suit.values.byName(json['suit'] as String),
          json['value'] as int);
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
      multiplier:
          ContractMultiplier.values.byName(json['multiplier'] as String),
    );

Map<String, dynamic> declarationToJson(Declaration d) => {
      'seat': d.seat.name,
      'kind': d.kind.name,
      'cards': cardsToJson(d.cards),
      'pointValue': d.pointValue(),
    };

Declaration declarationFromJson(Map<String, dynamic> json) {
  final seat = Seat.values.byName(json['seat'] as String);
  final cards = cardsFromJson(json['cards'] as List<dynamic>);
  return json['kind'] == 'carre'
      ? Declaration.carre(seat, cards)
      : Declaration.sequence(seat, cards);
}

Map<String, dynamic> declarationOutcomeToJson(DeclarationOutcome o) => {
      'bestPerSeat': {
        for (final e in o.bestPerSeat.entries)
          if (e.value != null) e.key.name: declarationToJson(e.value!),
      },
      'allPerSeat': {
        for (final e in o.allPerSeat.entries)
          if (e.value.isNotEmpty)
            e.key.name: e.value.map(declarationToJson).toList(),
      },
      'forfeitedPerSeat': {
        for (final e in o.forfeitedPerSeat.entries)
          e.key.name: declarationToJson(e.value),
      },
      'winningTeam': o.winningTeam?.name,
      'winningTeamPoints': o.winningTeamPoints,
      'beloteSeat': o.beloteSeat?.name,
    };

DeclarationOutcome declarationOutcomeFromJson(Map<String, dynamic> json) {
  final bestPerSeat = <Seat, Declaration?>{
    for (final seat in Seat.values) seat: null
  };
  for (final e in (json['bestPerSeat'] as Map<String, dynamic>).entries) {
    bestPerSeat[Seat.values.byName(e.key)] =
        declarationFromJson(e.value as Map<String, dynamic>);
  }
  final allPerSeat = <Seat, List<Declaration>>{
    for (final seat in Seat.values) seat: const []
  };
  for (final e
      in (json['allPerSeat'] as Map<String, dynamic>? ?? const {}).entries) {
    allPerSeat[Seat.values.byName(e.key)] = (e.value as List<dynamic>)
        .map((c) => declarationFromJson(c as Map<String, dynamic>))
        .toList();
  }
  final forfeitedPerSeat = <Seat, Declaration>{};
  for (final e in (json['forfeitedPerSeat'] as Map<String, dynamic>).entries) {
    forfeitedPerSeat[Seat.values.byName(e.key)] =
        declarationFromJson(e.value as Map<String, dynamic>);
  }
  return DeclarationOutcome(
    bestPerSeat: bestPerSeat,
    allPerSeat: allPerSeat,
    forfeitedPerSeat: forfeitedPerSeat,
    winningTeam: (json['winningTeam'] as String?) == null
        ? null
        : Team.values.byName(json['winningTeam'] as String),
    winningTeamPoints: json['winningTeamPoints'] as int,
    beloteSeat: (json['beloteSeat'] as String?) == null
        ? null
        : Seat.values.byName(json['beloteSeat'] as String),
  );
}

Map<String, dynamic> trickToJson(Trick trick) => {
      'leader': trick.leader.name,
      'trumpSuit': trick.trumpSuit.name,
      'mustOvertrumpAllSuits': trick.mustOvertrumpAllSuits,
      'played': [
        for (final p in trick.played)
          {'seat': p.seat.name, 'card': cardToJson(p.card)},
      ],
    };

/// Rebuilds a completed [Trick] by replaying its plays in order through the
/// real [Trick.play] — same "replay through the real engine calls" approach
/// as [save.dart], rather than duplicating trick-winner bookkeeping here.
Trick trickFromJson(Map<String, dynamic> json) {
  final trick = Trick(
    leader: Seat.values.byName(json['leader'] as String),
    trumpSuit: Suit.values.byName(json['trumpSuit'] as String),
    mustOvertrumpAllSuits: json['mustOvertrumpAllSuits'] as bool,
  );
  for (final playJson
      in (json['played'] as List<dynamic>).cast<Map<String, dynamic>>()) {
    trick.play(Seat.values.byName(playJson['seat'] as String),
        cardFromJson(playJson['card'] as Map<String, dynamic>));
  }
  return trick;
}

Map<String, dynamic> handResultToJson(HandResult r) => {
      'contract': contractToJson(r.contract),
      'trickPoints': {
        for (final e in r.trickPoints.entries) e.key.name: e.value
      },
      'allTricksTeam': r.allTricksTeam?.name,
      'declarations': declarationOutcomeToJson(r.declarations),
      'contractMade': r.contractMade,
      'rawTotals': {for (final e in r.rawTotals.entries) e.key.name: e.value},
      'rounded': {
        'northSouth': r.rounded.northSouth,
        'eastWest': r.rounded.eastWest
      },
      // Kept so a UI can show how the bidding went and replay the hand
      // trick by trick after it's over — see HandResult's doc comments.
      'auctionCalls': r.auctionCalls.map(auctionCallToJson).toList(),
      'originalHands': {
        for (final seat in Seat.values)
          seat.name: cardsToJson(r.originalHands[seat] ?? const []),
      },
      'tricks': r.tricks.map(trickToJson).toList(),
    };

HandResult handResultFromJson(Map<String, dynamic> json) {
  final rounded = json['rounded'] as Map<String, dynamic>;
  return HandResult(
    contract: contractFromJson(json['contract'] as Map<String, dynamic>),
    trickPoints: {
      for (final e in (json['trickPoints'] as Map<String, dynamic>).entries)
        Team.values.byName(e.key): e.value as int,
    },
    allTricksTeam: (json['allTricksTeam'] as String?) == null
        ? null
        : Team.values.byName(json['allTricksTeam'] as String),
    declarations: declarationOutcomeFromJson(
        json['declarations'] as Map<String, dynamic>),
    contractMade: json['contractMade'] as bool,
    rawTotals: {
      for (final e in (json['rawTotals'] as Map<String, dynamic>).entries)
        Team.values.byName(e.key): e.value as int,
    },
    rounded:
        RoundedScore(rounded['northSouth'] as int, rounded['eastWest'] as int),
    // Optional/back-compat: absent on a HandResult saved before this field
    // existed (e.g. an older "continue game later" save file).
    auctionCalls: (json['auctionCalls'] as List<dynamic>?)
            ?.map((e) => auctionCallFromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    originalHands: json['originalHands'] == null
        ? const {}
        : {
            for (final e
                in (json['originalHands'] as Map<String, dynamic>).entries)
              Seat.values.byName(e.key):
                  cardsFromJson(e.value as List<dynamic>),
          },
    tricks: (json['tricks'] as List<dynamic>?)
            ?.map((e) => trickFromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}
