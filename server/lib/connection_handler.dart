import 'dart:convert';
import 'dart:developer' as developer;

import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'room_registry.dart';

/// Wires one WebSocket connection to the room lifecycle: create/join a
/// room, forward bidding/play actions into it, and push a tailored
/// snapshot back to this connection every time the room's state changes.
///
/// Each connection is single-room, single-seat for its whole lifetime
/// (matching how the app only ever plays one match at a time): a fresh
/// WebSocket is expected if a player wants to join a different room.
class ConnectionHandler {
  final WebSocketChannel _channel;
  final RoomRegistry _registry;

  PilottaRoom? _room;
  Seat? _seat;
  void Function()? _roomListener;

  ConnectionHandler(this._channel, this._registry) {
    _channel.stream.listen(
      _onData,
      onDone: _onDone,
      onError: (Object error, StackTrace trace) {
        developer.log('WebSocket error', error: error, stackTrace: trace, name: 'pilotta_server');
        _onDone();
      },
    );
  }

  void _send(ServerMessage message) {
    _channel.sink.add(jsonEncode(message.toJson()));
  }

  void _sendError(String message) => _send(ServerErrorMessage(message));

  void _onData(dynamic raw) {
    final ClientMessage message;
    try {
      message = ClientMessage.fromJson(jsonDecode(raw as String) as Map<String, dynamic>);
    } catch (_) {
      _sendError('Μη έγκυρο μήνυμα.');
      return;
    }

    switch (message) {
      case CreateRoomMessage():
        _createRoom(message);
      case JoinRoomMessage():
        _joinRoom(message);
      case StartMessage():
        _start();
      case BidMessage():
        _bid(message);
      case PlayCardMessage():
        _playCard(message);
      case AnnounceDeclarationMessage():
        _announceDeclaration();
      case RevealDeclarationMessage():
        _revealDeclaration();
      case ReadyForNextHandMessage():
        _readyForNextHand();
      case LeaveMessage():
        _leave();
    }
  }

  void _createRoom(CreateRoomMessage message) {
    if (_room != null) {
      _sendError('Είσαι ήδη σε δωμάτιο.');
      return;
    }
    final room = _registry.createRoom(
      targetScore: message.targetScore,
      mustOvertrumpAllSuits: message.mustOvertrumpAllSuits,
    );
    final seat = room.join(message.playerName);
    if (seat == null) {
      // Unreachable for a brand-new room, but handled for symmetry.
      _sendError('Δεν ήταν δυνατή η δημιουργία δωματίου.');
      return;
    }
    _bindTo(room, seat);
    _send(WelcomeMessage(roomCode: room.roomCode, yourSeat: seat));
    _broadcastSnapshotTo(_channel, room, seat);
  }

  void _joinRoom(JoinRoomMessage message) {
    if (_room != null) {
      _sendError('Είσαι ήδη σε δωμάτιο.');
      return;
    }
    final room = _registry.find(message.roomCode);
    if (room == null) {
      _sendError('Δεν βρέθηκε δωμάτιο με κωδικό "${message.roomCode}".');
      return;
    }
    final seat = room.join(message.playerName);
    if (seat == null) {
      _sendError('Το δωμάτιο είναι γεμάτο.');
      return;
    }
    _bindTo(room, seat);
    _send(WelcomeMessage(roomCode: room.roomCode, yourSeat: seat));
    _broadcastSnapshotTo(_channel, room, seat);
  }

  void _bindTo(PilottaRoom room, Seat seat) {
    _room = room;
    _seat = seat;
    _roomListener = () => _broadcastSnapshotTo(_channel, room, seat);
    room.addListener(_roomListener!);
  }

  void _broadcastSnapshotTo(WebSocketChannel channel, PilottaRoom room, Seat seat) {
    channel.sink.add(jsonEncode(room.buildSnapshotFor(seat).toJson()));
  }

  void _start() {
    final room = _room;
    if (room == null) {
      _sendError('Δεν είσαι σε δωμάτιο.');
      return;
    }
    if (!room.canStart) {
      _sendError('Το παιχνίδι δεν μπορεί να ξεκινήσει ακόμα.');
      return;
    }
    room.start();
  }

  void _bid(BidMessage message) {
    final room = _room;
    final seat = _seat;
    if (room == null || seat == null) {
      _sendError('Δεν είσαι σε δωμάτιο.');
      return;
    }
    final error = room.handleBid(seat, message.call);
    if (error != null) _sendError(error);
  }

  void _playCard(PlayCardMessage message) {
    final room = _room;
    final seat = _seat;
    if (room == null || seat == null) {
      _sendError('Δεν είσαι σε δωμάτιο.');
      return;
    }
    final error = room.handlePlayCard(seat, message.card);
    if (error != null) _sendError(error);
  }

  void _announceDeclaration() {
    final room = _room;
    final seat = _seat;
    if (room == null || seat == null) {
      _sendError('Δεν είσαι σε δωμάτιο.');
      return;
    }
    final error = room.handleAnnounceDeclaration(seat);
    if (error != null) _sendError(error);
  }

  void _revealDeclaration() {
    final room = _room;
    final seat = _seat;
    if (room == null || seat == null) {
      _sendError('Δεν είσαι σε δωμάτιο.');
      return;
    }
    final error = room.handleRevealDeclaration(seat);
    if (error != null) _sendError(error);
  }

  void _readyForNextHand() {
    final room = _room;
    final seat = _seat;
    if (room == null || seat == null) return;
    room.markReadyForNextHand(seat);
  }

  void _leave() {
    final room = _room;
    final seat = _seat;
    if (room == null || seat == null) return;
    room.leave(seat);
    _unbind();
  }

  void _onDone() {
    final room = _room;
    final seat = _seat;
    if (room != null && seat != null) {
      room.setConnected(seat, false);
    }
    _unbind();
  }

  void _unbind() {
    if (_room != null && _roomListener != null) {
      _room!.removeListener(_roomListener!);
    }
    _room = null;
    _seat = null;
    _roomListener = null;
  }
}
