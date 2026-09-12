import 'package:flutter/foundation.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

enum ConnectionStatus { connecting, connected, disconnected }

/// The client side of the room protocol, transport-agnostic: everything a
/// UI needs to render a networked match and act on it, whether the bytes
/// underneath travel over a WebSocket ([OnlineGameController]) or a Nearby
/// Connections link to a host device on the same phone-to-phone network
/// ([BluetoothGameController]).
///
/// Holds no game logic of its own — the remote [PilottaRoom] (on a server,
/// or on the host device) is authoritative. The one exception is bidding:
/// [auction] is rebuilt locally by replaying the snapshot's public call
/// log, purely so [BiddingPanel] can be reused unmodified without the
/// transport needing to serialize anything auction-specific.
abstract class RoomClientController extends ChangeNotifier {
  ConnectionStatus status = ConnectionStatus.connecting;
  String? roomCode;
  Seat? mySeat;
  RoomSnapshotMessage? snapshot;
  String? lastError;

  /// The name this player joined/created the room with — kept around
  /// purely so a UI can offer to reconnect with the same identity after a
  /// dropped connection (rejoining with the same name reclaims your seat,
  /// see [PilottaRoom.join]).
  String? playerName;

  /// Sends [message] to whoever is authoritative (server or host device).
  @protected
  void sendMessage(ClientMessage message);

  /// Subclasses call this with every decoded [ServerMessage] as it arrives.
  @protected
  void handleServerMessage(ServerMessage message) {
    switch (message) {
      case WelcomeMessage():
        roomCode = message.roomCode;
        mySeat = message.yourSeat;
        lastError = null;
      case RoomSnapshotMessage():
        snapshot = message;
        lastError = null;
      case ServerErrorMessage():
        lastError = message.message;
    }
    notifyListeners();
  }

  // ------------------------------------------------------------- actions

  void createRoom({
    required String playerName,
    required int targetScore,
    bool mustOvertrumpAllSuits = false,
  }) {
    this.playerName = playerName;
    sendMessage(CreateRoomMessage(
      playerName: playerName,
      targetScore: targetScore,
      mustOvertrumpAllSuits: mustOvertrumpAllSuits,
    ));
  }

  void joinRoom({required String roomCode, required String playerName}) {
    this.playerName = playerName;
    sendMessage(JoinRoomMessage(roomCode: roomCode, playerName: playerName));
  }

  void start() => sendMessage(const StartMessage());

  void submitBid(AuctionCall call) => sendMessage(BidMessage(call));

  void playCard(PlayingCard card) => sendMessage(PlayCardMessage(card));

  /// Announces this player's best declaration (only valid during trick 1).
  void announceDeclaration() => sendMessage(const AnnounceDeclarationMessage());

  /// Reveals a previously-announced declaration (must happen before this
  /// player's trick-2 card).
  void revealDeclaration() => sendMessage(const RevealDeclarationMessage());

  void continueAfterHand() => sendMessage(const ReadyForNextHandMessage());

  void leaveRoom() => sendMessage(const LeaveMessage());

  // ------------------------------------------------------------ derived

  bool get inRoom => mySeat != null && snapshot != null;

  bool get isHost => mySeat == Seat.south;

  Auction? get auction {
    final calls = snapshot?.auctionCalls;
    if (calls == null) return null;
    final decoded = calls.map(auctionCallFromJson).toList();
    final startingSeat = decoded.isNotEmpty ? decoded.first.seat : (snapshot!.seatToAct ?? Seat.south);
    final rebuilt = Auction(startingSeat);
    for (final call in decoded) {
      rebuilt.apply(call);
    }
    return rebuilt;
  }

  bool get isMyTurnToBid =>
      snapshot?.phase == RoomPhase.bidding && snapshot?.seatToAct == mySeat;

  bool get isMyTurnToPlay =>
      snapshot?.phase == RoomPhase.playing && snapshot?.seatToAct == mySeat;

  /// Reconstructs the current trick as a real [Trick] from the snapshot's
  /// public state (leader, trump suit, cards played so far, house-rule
  /// flag). Legality only ever depends on this plus the viewer's own hand
  /// — never on other players' hidden cards — so this is exact, not a
  /// heuristic guess at what the server would accept.
  Trick? get currentTrick {
    final snap = snapshot;
    final contract = snap?.contract;
    final leader = snap?.trickLeader;
    if (snap == null || contract == null || leader == null) return null;
    final trick = Trick(
      leader: leader,
      trumpSuit: Suit.values.byName(contract['trumpSuit'] as String),
      mustOvertrumpAllSuits: snap.mustOvertrumpAllSuits,
    );
    for (final entry in snap.currentTrick ?? const <Map<String, dynamic>>[]) {
      trick.play(
        Seat.values.byName(entry['seat'] as String),
        cardFromJson(entry['card'] as Map<String, dynamic>),
      );
    }
    return trick;
  }

  /// The cards [mySeat] may legally play right now, computed client-side
  /// from [currentTrick] + the viewer's own hand (see [currentTrick]).
  List<PlayingCard> get legalPlaysForMe {
    final trick = currentTrick;
    final snap = snapshot;
    if (trick == null || snap == null) return const [];
    return trick.legalPlays(snap.yourHand);
  }
}
