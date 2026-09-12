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
  }) =>
      sendMessage(CreateRoomMessage(
        playerName: playerName,
        targetScore: targetScore,
        mustOvertrumpAllSuits: mustOvertrumpAllSuits,
      ));

  void joinRoom({required String roomCode, required String playerName}) =>
      sendMessage(JoinRoomMessage(roomCode: roomCode, playerName: playerName));

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
}
