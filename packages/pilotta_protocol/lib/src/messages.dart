import 'package:pilotta_engine/pilotta_engine.dart';

import 'chat.dart';
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
          mustOvertrumpAllSuits:
              json['mustOvertrumpAllSuits'] as bool? ?? false,
        );
      case 'join_room':
        return JoinRoomMessage(
          roomCode: json['roomCode'] as String,
          playerName: json['playerName'] as String,
        );
      case 'start':
        return const StartMessage();
      case 'bid':
        return BidMessage(
            auctionCallFromJson(json['call'] as Map<String, dynamic>));
      case 'play_card':
        return PlayCardMessage(
            cardFromJson(json['card'] as Map<String, dynamic>));
      case 'announce_declaration':
        return const AnnounceDeclarationMessage();
      case 'reveal_declaration':
        return const RevealDeclarationMessage();
      case 'ready_for_next_hand':
        return const ReadyForNextHandMessage();
      case 'send_chat':
        return SendChatMessage(json['text'] as String);
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

  /// House-rule variant for the whole room — see
  /// [PilottaRoom.mustOvertrumpAllSuits].
  final bool mustOvertrumpAllSuits;

  CreateRoomMessage({
    required this.playerName,
    required this.targetScore,
    this.mustOvertrumpAllSuits = false,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'create_room',
        'playerName': playerName,
        'targetScore': targetScore,
        'mustOvertrumpAllSuits': mustOvertrumpAllSuits,
      };
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
  Map<String, dynamic> toJson() =>
      {'type': 'bid', 'call': auctionCallToJson(call)};
}

class PlayCardMessage extends ClientMessage {
  final PlayingCard card;
  PlayCardMessage(this.card);
  @override
  Map<String, dynamic> toJson() =>
      {'type': 'play_card', 'card': cardToJson(card)};
}

/// Announces the sender's best declaration during trick 1 — see
/// [PilottaHand.announceDeclaration]. Must still be followed by
/// [RevealDeclarationMessage] before the sender plays their trick-2 card,
/// or it's forfeited.
class AnnounceDeclarationMessage extends ClientMessage {
  const AnnounceDeclarationMessage();
  @override
  Map<String, dynamic> toJson() => {'type': 'announce_declaration'};
}

/// Reveals the sender's previously-announced declaration — see
/// [PilottaHand.revealDeclaration].
class RevealDeclarationMessage extends ClientMessage {
  const RevealDeclarationMessage();
  @override
  Map<String, dynamic> toJson() => {'type': 'reveal_declaration'};
}

class ReadyForNextHandMessage extends ClientMessage {
  const ReadyForNextHandMessage();
  @override
  Map<String, dynamic> toJson() => {'type': 'ready_for_next_hand'};
}

/// A free-text chat message the sender typed — appended to the room's
/// shared [ChatEntry] log, visible to every seat.
class SendChatMessage extends ClientMessage {
  final String text;
  const SendChatMessage(this.text);
  @override
  Map<String, dynamic> toJson() => {'type': 'send_chat', 'text': text};
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
  const SeatInfo(
      {this.playerName, required this.isBot, required this.connected});

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
  final bool mustOvertrumpAllSuits;
  final Map<String, int> totals; // "northSouth" / "eastWest" -> points

  final Seat? dealer;
  final List<Map<String, dynamic>>? auctionCalls;
  final Seat? seatToAct;
  final Map<String, dynamic>? contract;

  final List<PlayingCard> yourHand;
  final Map<Seat, int> handSizes;
  final List<Map<String, dynamic>>? currentTrick; // [{seat, card}]
  final Seat? trickLeader;

  /// The most recently completed trick (before the current one), for a
  /// "peek last trick" affordance — null before any trick has finished.
  final List<Map<String, dynamic>>? lastCompletedTrick; // [{seat, card}]
  final Seat? lastCompletedTrickWinner;

  /// Every hand played so far this match, oldest first, for a paper-style
  /// scoreboard. Each entry is a `handResultToJson` map.
  final List<Map<String, dynamic>> matchHistory;

  /// Every seat's progress through the declaration announce/reveal flow —
  /// values are [DeclarationAnnounceState] names. Always public: announcing
  /// is a verbal, audible act at the table.
  final Map<Seat, String> declarationStates;

  /// The actual declaration content for every seat who has revealed theirs
  /// — safe to show the whole table since revealing means showing the
  /// cards. Seats who haven't revealed (or have nothing) are absent. A seat
  /// can hold more than one declaration at once (only the best is
  /// announced out loud, but all of them are shown and score once
  /// revealed), hence a list.
  final Map<Seat, List<Map<String, dynamic>>> revealedDeclarations;

  /// [yourSeat]'s own best declaration this hand, if any — always visible
  /// to them regardless of announce/reveal state, so their UI can offer to
  /// announce it.
  final Map<String, dynamic>? yourBestDeclaration;
  final bool canAnnounceDeclaration;
  final bool canRevealDeclaration;

  final String? banner;
  final Map<String, dynamic>? lastHandResult;
  final Set<Seat> readyForNextHand;
  final String? winnerTeam;

  /// The room's shared chat/event log (player messages + declaration and
  /// Pilotta/Repilotta announcements), oldest first. Every viewer sees the
  /// same entries — capped server-side, see `PilottaRoom._chatLog`.
  final List<ChatEntry> chatLog;

  const RoomSnapshotMessage({
    required this.roomCode,
    required this.yourSeat,
    required this.phase,
    required this.seats,
    required this.targetScore,
    this.mustOvertrumpAllSuits = false,
    required this.totals,
    this.dealer,
    this.auctionCalls,
    this.seatToAct,
    this.contract,
    this.yourHand = const [],
    this.handSizes = const {},
    this.currentTrick,
    this.trickLeader,
    this.lastCompletedTrick,
    this.lastCompletedTrickWinner,
    this.matchHistory = const [],
    this.declarationStates = const {},
    this.revealedDeclarations = const {},
    this.yourBestDeclaration,
    this.canAnnounceDeclaration = false,
    this.canRevealDeclaration = false,
    this.banner,
    this.lastHandResult,
    this.readyForNextHand = const {},
    this.winnerTeam,
    this.chatLog = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'snapshot',
        'roomCode': roomCode,
        'yourSeat': yourSeat.name,
        'phase': phase.name,
        'seats': {for (final e in seats.entries) e.key.name: e.value.toJson()},
        'targetScore': targetScore,
        'mustOvertrumpAllSuits': mustOvertrumpAllSuits,
        'totals': totals,
        'dealer': dealer?.name,
        'auctionCalls': auctionCalls,
        'seatToAct': seatToAct?.name,
        'contract': contract,
        'yourHand': cardsToJson(yourHand),
        'handSizes': {for (final e in handSizes.entries) e.key.name: e.value},
        'currentTrick': currentTrick,
        'trickLeader': trickLeader?.name,
        'lastCompletedTrick': lastCompletedTrick,
        'lastCompletedTrickWinner': lastCompletedTrickWinner?.name,
        'matchHistory': matchHistory,
        'declarationStates': {
          for (final e in declarationStates.entries) e.key.name: e.value
        },
        'revealedDeclarations': {
          for (final e in revealedDeclarations.entries) e.key.name: e.value,
        },
        'yourBestDeclaration': yourBestDeclaration,
        'canAnnounceDeclaration': canAnnounceDeclaration,
        'canRevealDeclaration': canRevealDeclaration,
        'banner': banner,
        'lastHandResult': lastHandResult,
        'readyForNextHand': readyForNextHand.map((s) => s.name).toList(),
        'winnerTeam': winnerTeam,
        'chatLog': chatLog.map((e) => e.toJson()).toList(),
      };

  static RoomSnapshotMessage fromJson(Map<String, dynamic> json) {
    return RoomSnapshotMessage(
      roomCode: json['roomCode'] as String,
      yourSeat: Seat.values.byName(json['yourSeat'] as String),
      phase: RoomPhase.values.byName(json['phase'] as String),
      seats: {
        for (final entry in (json['seats'] as Map<String, dynamic>).entries)
          Seat.values.byName(entry.key):
              SeatInfo.fromJson(entry.value as Map<String, dynamic>),
      },
      targetScore: json['targetScore'] as int,
      mustOvertrumpAllSuits: json['mustOvertrumpAllSuits'] as bool? ?? false,
      totals: (json['totals'] as Map<String, dynamic>).cast<String, int>(),
      dealer: (json['dealer'] as String?) == null
          ? null
          : Seat.values.byName(json['dealer'] as String),
      auctionCalls: (json['auctionCalls'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
      seatToAct: (json['seatToAct'] as String?) == null
          ? null
          : Seat.values.byName(json['seatToAct'] as String),
      contract: json['contract'] as Map<String, dynamic>?,
      yourHand: cardsFromJson(json['yourHand'] as List<dynamic>),
      handSizes: {
        for (final entry in (json['handSizes'] as Map<String, dynamic>).entries)
          Seat.values.byName(entry.key): entry.value as int,
      },
      currentTrick: (json['currentTrick'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
      trickLeader: (json['trickLeader'] as String?) == null
          ? null
          : Seat.values.byName(json['trickLeader'] as String),
      lastCompletedTrick: (json['lastCompletedTrick'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
      lastCompletedTrickWinner:
          (json['lastCompletedTrickWinner'] as String?) == null
              ? null
              : Seat.values.byName(json['lastCompletedTrickWinner'] as String),
      matchHistory: (json['matchHistory'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>(),
      declarationStates: {
        for (final entry
            in (json['declarationStates'] as Map<String, dynamic>? ?? const {})
                .entries)
          Seat.values.byName(entry.key): entry.value as String,
      },
      revealedDeclarations: {
        for (final entry
            in (json['revealedDeclarations'] as Map<String, dynamic>? ??
                    const {})
                .entries)
          Seat.values.byName(entry.key):
              (entry.value as List<dynamic>).cast<Map<String, dynamic>>(),
      },
      yourBestDeclaration: json['yourBestDeclaration'] as Map<String, dynamic>?,
      canAnnounceDeclaration: json['canAnnounceDeclaration'] as bool? ?? false,
      canRevealDeclaration: json['canRevealDeclaration'] as bool? ?? false,
      banner: json['banner'] as String?,
      lastHandResult: json['lastHandResult'] as Map<String, dynamic>?,
      readyForNextHand: {
        for (final s in (json['readyForNextHand'] as List<dynamic>))
          Seat.values.byName(s as String),
      },
      winnerTeam: json['winnerTeam'] as String?,
      chatLog: (json['chatLog'] as List<dynamic>? ?? const [])
          .map((e) => ChatEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
