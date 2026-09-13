import 'dart:convert';
import 'dart:math';

import 'package:nearby_connections/nearby_connections.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

import '../controllers/room_client_controller.dart';
import 'nearby_transport.dart';

const _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

String _generateCode(Random random) =>
    List.generate(4, (_) => _codeAlphabet[random.nextInt(_codeAlphabet.length)]).join();

/// The host side of a Bluetooth/local-network match: this device owns the
/// one authoritative [PilottaRoom] directly (no internet, no server — it
/// *is* the server for this table) and also plays its own seat in it.
///
/// It extends [RoomClientController] so the exact same [NetworkedGameScreen]
/// used for online play and for Bluetooth guests works for the host too:
/// the host's own UI actions ([start], [submitBid], [playCard], ...) are
/// intercepted in [sendMessage] and applied straight to the local [room]
/// instead of being serialized anywhere, while up to three guest devices
/// connect over Nearby Connections and are routed through [_onGuestMessage]
/// exactly like a WebSocket connection would be on the online server.
class BluetoothHostSession extends RoomClientController {
  final PilottaRoom room;
  final String hostName;
  final NearbyTransport _transport = NearbyTransport();
  final Map<String, Seat> _endpointSeat = {};

  bool advertising = false;

  BluetoothHostSession({
    required int targetScore,
    required this.hostName,
    Random? random,
    bool mustOvertrumpAllSuits = false,
  }) : room = PilottaRoom(
          roomCode: _generateCode(random ?? Random()),
          targetScore: targetScore,
          random: random,
          mustOvertrumpAllSuits: mustOvertrumpAllSuits,
        ) {
    final seat = room.join(hostName)!;
    handleServerMessage(WelcomeMessage(roomCode: room.roomCode, yourSeat: seat));
    room.addListener(_onRoomChanged);
    _onRoomChanged();
  }

  Future<void> startAdvertising() async {
    final granted = await _transport.ensurePermissions();
    if (!granted) {
      lastError = 'Χρειάζονται δικαιώματα Bluetooth/Τοποθεσίας για να σε βρουν άλλες συσκευές.';
      notifyListeners();
      return;
    }
    try {
      advertising = await _transport.startAdvertising(
        userName: hostName,
        onConnectionRequested: (endpointId, endpointName) {
          _transport.acceptConnection(endpointId, onMessage: _onGuestMessage);
        },
        onConnectionResult: (endpointId, status) {
          if (status != Status.CONNECTED) {
            _endpointSeat.remove(endpointId);
          }
        },
        onDisconnected: (endpointId) {
          final seat = _endpointSeat.remove(endpointId);
          if (seat != null) room.setConnected(seat, false);
        },
      );
    } catch (_) {
      advertising = false;
      lastError = 'Δεν ήταν δυνατή η εκκίνηση διαφήμισης Bluetooth.';
    }
    notifyListeners();
  }

  void _onGuestMessage(String endpointId, String raw) {
    final ClientMessage message;
    try {
      message = ClientMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return;
    }

    switch (message) {
      case JoinRoomMessage():
        final seat = room.join(message.playerName);
        if (seat == null) {
          _transport.sendMessage(
              endpointId, jsonEncode(ServerErrorMessage('Το δωμάτιο είναι γεμάτο.').toJson()));
          return;
        }
        _endpointSeat[endpointId] = seat;
        _transport.sendMessage(
            endpointId, jsonEncode(WelcomeMessage(roomCode: room.roomCode, yourSeat: seat).toJson()));
        _transport.sendMessage(endpointId, jsonEncode(room.buildSnapshotFor(seat).toJson()));
      case StartMessage():
        room.start();
      case BidMessage():
        final seat = _endpointSeat[endpointId];
        final error = seat == null ? 'Άγνωστη θέση.' : room.handleBid(seat, message.call);
        if (error != null) {
          _transport.sendMessage(endpointId, jsonEncode(ServerErrorMessage(error).toJson()));
        }
      case PlayCardMessage():
        final seat = _endpointSeat[endpointId];
        final error = seat == null ? 'Άγνωστη θέση.' : room.handlePlayCard(seat, message.card);
        if (error != null) {
          _transport.sendMessage(endpointId, jsonEncode(ServerErrorMessage(error).toJson()));
        }
      case AnnounceDeclarationMessage():
        final seat = _endpointSeat[endpointId];
        final error = seat == null ? 'Άγνωστη θέση.' : room.handleAnnounceDeclaration(seat);
        if (error != null) {
          _transport.sendMessage(endpointId, jsonEncode(ServerErrorMessage(error).toJson()));
        }
      case RevealDeclarationMessage():
        final seat = _endpointSeat[endpointId];
        final error = seat == null ? 'Άγνωστη θέση.' : room.handleRevealDeclaration(seat);
        if (error != null) {
          _transport.sendMessage(endpointId, jsonEncode(ServerErrorMessage(error).toJson()));
        }
      case ReadyForNextHandMessage():
        final seat = _endpointSeat[endpointId];
        if (seat != null) room.markReadyForNextHand(seat);
      case SendChatMessage():
        final seat = _endpointSeat[endpointId];
        final error = seat == null ? 'Άγνωστη θέση.' : room.sendChat(seat, message.text);
        if (error != null) {
          _transport.sendMessage(endpointId, jsonEncode(ServerErrorMessage(error).toJson()));
        }
      case LeaveMessage():
        final seat = _endpointSeat.remove(endpointId);
        if (seat != null) room.leave(seat);
      case CreateRoomMessage():
        break; // not applicable: the room already exists.
    }
  }

  void _onRoomChanged() {
    handleServerMessage(room.buildSnapshotFor(mySeat!));
    for (final entry in _endpointSeat.entries) {
      _transport.sendMessage(entry.key, jsonEncode(room.buildSnapshotFor(entry.value).toJson()));
    }
  }

  @override
  void sendMessage(ClientMessage message) {
    switch (message) {
      case StartMessage():
        room.start();
      case BidMessage():
        room.handleBid(mySeat!, message.call);
      case PlayCardMessage():
        room.handlePlayCard(mySeat!, message.card);
      case AnnounceDeclarationMessage():
        room.handleAnnounceDeclaration(mySeat!);
      case RevealDeclarationMessage():
        room.handleRevealDeclaration(mySeat!);
      case ReadyForNextHandMessage():
        room.markReadyForNextHand(mySeat!);
      case SendChatMessage():
        room.sendChat(mySeat!, message.text);
      case LeaveMessage():
        room.leave(mySeat!);
      case CreateRoomMessage():
      case JoinRoomMessage():
        break; // not applicable: the host already owns a room.
    }
  }

  @override
  void dispose() {
    room.removeListener(_onRoomChanged);
    _transport.stopAdvertising();
    _transport.stopAllEndpoints();
    room.dispose();
    super.dispose();
  }
}
