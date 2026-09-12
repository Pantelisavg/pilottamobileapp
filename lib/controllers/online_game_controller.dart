import 'dart:async';
import 'dart:convert';

import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'room_client_controller.dart';

/// Drives an online match over a WebSocket connection to the Pilotta
/// server. All game-flow logic lives in [RoomClientController]; this class
/// only knows how to get [ClientMessage]/[ServerMessage] JSON on and off a
/// WebSocket.
class OnlineGameController extends RoomClientController {
  final Uri serverUri;
  final WebSocketChannel _channel;
  StreamSubscription<dynamic>? _sub;

  OnlineGameController({required this.serverUri})
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

  @override
  void sendMessage(ClientMessage message) {
    _channel.sink.add(jsonEncode(message.toJson()));
  }

  void _onData(dynamic raw) {
    try {
      handleServerMessage(
          ServerMessage.fromJson(jsonDecode(raw as String) as Map<String, dynamic>));
    } catch (_) {
      // Malformed frame: ignore rather than crash the connection.
    }
  }
}
