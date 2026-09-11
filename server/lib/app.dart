import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'connection_handler.dart';
import 'room_registry.dart';

/// Builds the shelf [Handler] for the Pilotta server: a health-check root
/// path plus the "/ws" WebSocket upgrade endpoint. Factored out of
/// bin/server.dart so tests can serve the exact same handler on an
/// ephemeral port and drive it with real WebSocket clients.
Handler buildHandler(RoomRegistry registry) {
  final wsHandler = webSocketHandler((WebSocketChannel channel, String? protocol) {
    ConnectionHandler(channel, registry);
  });

  return Cascade()
      .add((Request request) {
        if (request.url.path == 'ws') {
          return wsHandler(request);
        }
        return Response.ok('pilotta-server ok — ${registry.roomCount} active room(s)\n');
      })
      .handler;
}
