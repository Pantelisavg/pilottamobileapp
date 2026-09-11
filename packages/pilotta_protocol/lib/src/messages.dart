import 'package:pilotta_engine/pilotta_engine.dart';

import 'codec.dart';

/// Messages a client sends. The server always knows which connection (and
/// therefore which room + seat) a message came from, so these never carry a
/// seat themselves.
sealed class ClientMessage {
  const ClientMessage();

  Map<String, dynamic> toJson();

  static ClientMessage fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'create_room':
        return CreateRoomMessage(
          playerName: json['playerName'] as String,
          targetScore: json['targetScore'] as int,
        );
      case 'join_room':
        return JoinRoomMessage(
          roomCode: json['roomCode'] as String,
          playerName: json['playerName'] as String,
        );
      case 'start':
        return const StartMessage();
      case 'bid':
        return BidMessage(auctionCallFromJson(json['call'] as Map<String, dynamic>));
      case 'play_card':
        return PlayCardMessage(cardFromJson(json['card'] as Map<String, dynamic>));
      case 'ready_for_next_hand':
        return const ReadyForNextHandMessage();
      case 'leave':
        return const LeaveMessage();
      default:
        throw FormatException('Unknown client message type: ${json['type']}');
    }
  }
}

class CreateRoomMessage extends ClientMessage {
  final String playerName;
  final int targetScore;
  CreateRoomMessage({required this.playerName, required this.targetScore});

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'create_room', 'playerName': playerName, 'targetScore': targetScore};
}

class JoinRoomMessage extends ClientMessage {
  final String roomCode;
  final String playerName;
  JoinRoomMessage({required this.roomCode, required this.playerName});

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'join_room', 'roomCode': roomCode, 'playerName': playerName};
}

/// Host-only: begins the match, filling any seats nobody has joined with
/// bots so a game can start with 1-4 humans.
class StartMessage extends ClientMessage {
  const StartMessage();
  @override
  Map<String, dynamic> toJson() => {'type': 'start'};
}

class BidMessage extends ClientMessage {
  final AuctionCall call;
  BidMessage(this.call);
  @override
  Map<String, dynamic> toJson() => {'type': 'bid', 'call': auctionCallToJson(call)};
}

class PlayCardMessage extends ClientMessage {
  final PlayingCard card;
  PlayCardMessage(this.card);
  @override
  Map<String, dynamic> toJson() => {'type': 'play_card', 'card': cardToJson(card)};
}

class ReadyForNextHandMessage extends ClientMessage {
  const ReadyForNextHandMessage();
  @override
  Map<String, dynamic> toJson() => {'type': 'ready_for_next_hand'};
}

class LeaveMessage extends ClientMessage {
  const LeaveMessage();
  @override
  Map<String, dynamic> toJson() => {'type': 'leave'};
}

/// Messages the server sends. [RoomSnapshotMessage] is the workhorse: a
/// full, per-recipient tailored snapshot of room + hand state sent after
/// every change, rather than incremental diffs — simple to get right, and
/// small enough for a card game that this is never a bandwidth concern.
sealed class ServerMessage {
  const ServerMessage();

  Map<String, dynamic> toJson();

  static ServerMessage fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'welcome':
        return WelcomeMessage(
          roomCode: json['roomCode'] as String,
          yourSeat: Seat.values.byName(json['yourSeat'] as String),
        );
      case 'error':
        return ServerErrorMessage(json['message'] as String);
      case 'snapshot':
        return RoomSnapshotMessage.fromJson(json);
      default:
        throw FormatException('Unknown server message type: ${json['type']}');
    }
  }
}

class WelcomeMessage extends ServerMessage {
  final String roomCode;
  final Seat yourSeat;
  WelcomeMessage({required this.roomCode, required this.yourSeat});

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'welcome', 'roomCode': roomCode, 'yourSeat': yourSeat.name};
}

class ServerErrorMessage extends ServerMessage {
  final String message;
  ServerErrorMessage(this.message);
  @override
  Map<String, dynamic> toJson() => {'type': 'error', 'message': message};
}

enum RoomPhase { lobby, bidding, playing, handSummary, matchOver }

class SeatInfo {
  final String? playerName;
  final bool isBot;
  final bool connected;
  const SeatInfo({this.playerName, required this.isBot, required this.connected});

  Map<String, dynamic> toJson() =>
      {'playerName': playerName, 'isBot': isBot, 'connected': connected};

  static SeatInfo fromJson(Map<String, dynamic> json) => SeatInfo(
        playerName: json['playerName'] as String?,
        isBot: json['isBot'] as bool,
        connected: json['connected'] as bool,
      );
}

/// A full snapshot of everything one particular recipient is allowed to
/// see: public room/game state, plus their own private hand.
class RoomSnapshotMessage extends ServerMessage {
  final String roomCode;
  final Seat yourSeat;
  final RoomPhase phase;
  final Map<Seat, SeatInfo> seats;
  final int targetScore;
  final Map<String, int> totals; // "northSouth" / "eastWest" -> points

  final Seat? dealer;
  final List<Map<String, dynamic>>? auctionCalls;
  final Seat? seatToAct;
  final Map<String, dynamic>? contract;

  final List<PlayingCard> yourHand;
  final Map<Seat, int> handSizes;
  final List<Map<String, dynamic>>? currentTrick; // [{seat, card}]
  final Seat? trickLeader;

  final String? banner;
  final Map<String, dynamic>? lastHandResult;
  final Set<Seat> readyForNextHand;
  final String? winnerTeam;

  const RoomSnapshotMessage({
    required this.roomCode,
    required this.yourSeat,
    required this.phase,
    required this.seats,
    required this.targetScore,
    required this.totals,
    this.dealer,
    this.auctionCalls,
    this.seatToAct,
    this.contract,
    this.yourHand = const [],
    this.handSizes = const {},
    this.currentTrick,
    this.trickLeader,
    this.banner,
    this.lastHandResult,
    this.readyForNextHand = const {},
    this.winnerTeam,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'snapshot',
        'roomCode': roomCode,
        'yourSeat': yourSeat.name,
        'phase': phase.name,
        'seats': {for (final e in seats.entries) e.key.name: e.value.toJson()},
        'targetScore': targetScore,
        'totals': totals,
        'dealer': dealer?.name,
        'auctionCalls': auctionCalls,
        'seatToAct': seatToAct?.name,
        'contract': contract,
        'yourHand': cardsToJson(yourHand),
        'handSizes': {for (final e in handSizes.entries) e.key.name: e.value},
        'currentTrick': currentTrick,
        'trickLeader': trickLeader?.name,
        'banner': banner,
        'lastHandResult': lastHandResult,
        'readyForNextHand': readyForNextHand.map((s) => s.name).toList(),
        'winnerTeam': winnerTeam,
      };

  static RoomSnapshotMessage fromJson(Map<String, dynamic> json) {
    return RoomSnapshotMessage(
      roomCode: json['roomCode'] as String,
      yourSeat: Seat.values.byName(json['yourSeat'] as String),
      phase: RoomPhase.values.byName(json['phase'] as String),
      seats: {
        for (final entry in (json['seats'] as Map<String, dynamic>).entries)
          Seat.values.byName(entry.key): SeatInfo.fromJson(entry.value as Map<String, dynamic>),
      },
      targetScore: json['targetScore'] as int,
      totals: (json['totals'] as Map<String, dynamic>).cast<String, int>(),
      dealer: (json['dealer'] as String?) == null ? null : Seat.values.byName(json['dealer'] as String),
      auctionCalls: (json['auctionCalls'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      seatToAct:
          (json['seatToAct'] as String?) == null ? null : Seat.values.byName(json['seatToAct'] as String),
      contract: json['contract'] as Map<String, dynamic>?,
      yourHand: cardsFromJson(json['yourHand'] as List<dynamic>),
      handSizes: {
        for (final entry in (json['handSizes'] as Map<String, dynamic>).entries)
          Seat.values.byName(entry.key): entry.value as int,
      },
      currentTrick: (json['currentTrick'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      trickLeader:
          (json['trickLeader'] as String?) == null ? null : Seat.values.byName(json['trickLeader'] as String),
      banner: json['banner'] as String?,
      lastHandResult: json['lastHandResult'] as Map<String, dynamic>?,
      readyForNextHand: {
        for (final s in (json['readyForNextHand'] as List<dynamic>)) Seat.values.byName(s as String),
      },
      winnerTeam: json['winnerTeam'] as String?,
    );
  }
}
