import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus { connecting, connected, disconnected }

/// Drives an online match over a WebSocket connection to the Pilotta
/// server. Unlike [LocalGameController] this holds no engine state of its
/// own — the server is authoritative — it just tracks the latest
/// [RoomSnapshotMessage] and turns UI actions into [ClientMessage]s.
///
/// The one exception is bidding: to reuse [BiddingPanel] unmodified, this
/// replays the snapshot's public `auctionCalls` log through a fresh, local
/// [Auction] object each time it's requested. That replay can never fail —
/// the server already validated every call before broadcasting it — so it's
/// a safe way to get a fully-featured local auction view without the
/// server needing to serialize anything auction-specific beyond the call
/// log it already sends.
class OnlineGameController extends ChangeNotifier {
  final WebSocketChannel _channel;
  StreamSubscription<dynamic>? _sub;

  ConnectionStatus status = ConnectionStatus.connecting;
  String? roomCode;
  Seat? mySeat;
  RoomSnapshotMessage? snapshot;
  String? lastError;

  OnlineGameController({required Uri serverUri})
      : _channel = WebSocketChannel.connect(serverUri) {
    _sub = _channel.stream.listen(
      _onData,
      onDone: () {
        status = ConnectionStatus.disconnected;
        notifyListeners();
      },
      onError: (Object error, StackTrace trace) {
        status = ConnectionStatus.disconnected;
        lastError = 'Απώλεια σύνδεσης.';
        notifyListeners();
      },
    );
    status = ConnectionStatus.connected;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _channel.sink.close();
    super.dispose();
  }

  void _send(ClientMessage message) {
    _channel.sink.add(jsonEncode(message.toJson()));
  }

  void _onData(dynamic raw) {
    final ServerMessage message;
    try {
      message = ServerMessage.fromJson(jsonDecode(raw as String) as Map<String, dynamic>);
    } catch (_) {
      return;
    }
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

  void createRoom({required String playerName, required int targetScore}) =>
      _send(CreateRoomMessage(playerName: playerName, targetScore: targetScore));

  void joinRoom({required String roomCode, required String playerName}) =>
      _send(JoinRoomMessage(roomCode: roomCode, playerName: playerName));

  void start() => _send(const StartMessage());

  void submitBid(AuctionCall call) => _send(BidMessage(call));

  void playCard(PlayingCard card) => _send(PlayCardMessage(card));

  void continueAfterHand() => _send(const ReadyForNextHandMessage());

  void leaveRoom() => _send(const LeaveMessage());

  // ------------------------------------------------------------ derived

  bool get inRoom => mySeat != null && snapshot != null;

  bool get isHost => mySeat == Seat.south;

  /// A locally reconstructed [Auction], rebuilt by replaying the snapshot's
  /// public call log. Only meaningful during [RoomPhase.bidding].
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
