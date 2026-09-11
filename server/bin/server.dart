import 'dart:io';

import 'package:pilotta_server/app.dart';
import 'package:pilotta_server/room_registry.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Entry point for the online Pilotta server. Run with:
///   dart run bin/server.dart
/// Listens for WebSocket connections at ws://<host>:<port>/ws and serves a
/// tiny plaintext health check at "/" (handy for hosting platforms that
/// ping the root path).
Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final registry = RoomRegistry();

  final server = await shelf_io.serve(buildHandler(registry), InternetAddress.anyIPv4, port);
  // ignore: avoid_print
  print('Pilotta server listening on ws://${server.address.host}:${server.port}/ws');
}
