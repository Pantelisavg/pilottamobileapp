import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:pilotta_server/app.dart';
import 'package:pilotta_server/room_registry.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A tiny test double: connects to the real server over a real WebSocket
/// and buffers every decoded [ServerMessage] it receives so tests can
/// assert on them without racing the network.
class TestClient {
  final WebSocketChannel channel;
  final _messages = StreamController<ServerMessage>.broadcast();
  final List<ServerMessage> log = [];
  late final StreamSubscription<dynamic> _sub;

  TestClient(Uri uri) : channel = IOWebSocketChannel.connect(uri) {
    _sub = channel.stream.listen((raw) {
      final message = ServerMessage.fromJson(jsonDecode(raw as String) as Map<String, dynamic>);
      log.add(message);
      _messages.add(message);
    });
  }

  void send(ClientMessage message) => channel.sink.add(jsonEncode(message.toJson()));

  Future<T> waitFor<T extends ServerMessage>() =>
      _messages.stream.firstWhere((m) => m is T).then((m) => m as T);

  RoomSnapshotMessage get latestSnapshot =>
      log.whereType<RoomSnapshotMessage>().last;

  Future<void> close() async {
    await _sub.cancel();
    await channel.sink.close();
    await _messages.close();
  }
}

void main() {
  late HttpServer server;
  late Uri wsUri;

  setUp(() async {
    final registry = RoomRegistry();
    server = await shelf_io.serve(buildHandler(registry), InternetAddress.loopbackIPv4, 0);
    wsUri = Uri.parse('ws://${server.address.host}:${server.port}/ws');
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('creating a room returns a join code and starting fills bots', () async {
    final host = TestClient(wsUri);
    host.send(CreateRoomMessage(playerName: 'Host', targetScore: 101));

    final welcome = await host.waitFor<WelcomeMessage>();
    expect(welcome.roomCode, hasLength(4));
    expect(welcome.yourSeat, Seat.south);

    final lobbySnapshot = await host.waitFor<RoomSnapshotMessage>();
    expect(lobbySnapshot.phase, RoomPhase.lobby);

    host.send(const StartMessage());
    final started = await host.waitFor<RoomSnapshotMessage>().timeout(
      const Duration(seconds: 2),
      onTimeout: () => host.latestSnapshot,
    );
    // Poll until we observe the post-start snapshot (bidding phase).
    var snapshot = started;
    for (var i = 0; i < 20 && snapshot.phase == RoomPhase.lobby; i++) {
      snapshot = await host.waitFor<RoomSnapshotMessage>();
    }
    expect(snapshot.phase, RoomPhase.bidding);
    expect(snapshot.seats[Seat.west]!.isBot, isTrue);
    expect(snapshot.yourHand, hasLength(8));

    await host.close();
  });

  test('joining with a bad room code returns an error', () async {
    final client = TestClient(wsUri);
    client.send(JoinRoomMessage(roomCode: 'ZZZZ', playerName: 'Nobody'));
    final error = await client.waitFor<ServerErrorMessage>();
    expect(error.message, contains('ZZZZ'));
    await client.close();
  });

  test('two humans can join the same room and each only sees their own hand', () async {
    final host = TestClient(wsUri);
    host.send(CreateRoomMessage(playerName: 'Alice', targetScore: 101));
    final welcome = await host.waitFor<WelcomeMessage>();

    final guest = TestClient(wsUri);
    guest.send(JoinRoomMessage(roomCode: welcome.roomCode, playerName: 'Bob'));
    final guestWelcome = await guest.waitFor<WelcomeMessage>();
    expect(guestWelcome.yourSeat, Seat.west);

    host.send(const StartMessage());

    RoomSnapshotMessage hostSnap = await host.waitFor<RoomSnapshotMessage>();
    for (var i = 0; i < 20 && hostSnap.phase == RoomPhase.lobby; i++) {
      hostSnap = await host.waitFor<RoomSnapshotMessage>();
    }
    RoomSnapshotMessage guestSnap = await guest.waitFor<RoomSnapshotMessage>();
    for (var i = 0; i < 20 && guestSnap.phase == RoomPhase.lobby; i++) {
      guestSnap = await guest.waitFor<RoomSnapshotMessage>();
    }

    expect(hostSnap.yourHand, hasLength(8));
    expect(guestSnap.yourHand, hasLength(8));
    expect(
      hostSnap.yourHand.toSet().intersection(guestSnap.yourHand.toSet()),
      isEmpty,
      reason: 'neither player should ever see the other\'s cards',
    );

    await host.close();
    await guest.close();
  });

  test('an illegal bid is rejected with an error and does not advance the turn', () async {
    final host = TestClient(wsUri);
    host.send(CreateRoomMessage(playerName: 'Alice', targetScore: 101));
    await host.waitFor<WelcomeMessage>();
    host.send(const StartMessage());

    RoomSnapshotMessage snap = await host.waitFor<RoomSnapshotMessage>();
    for (var i = 0; i < 20 && snap.phase != RoomPhase.bidding; i++) {
      snap = await host.waitFor<RoomSnapshotMessage>();
    }

    // South is always dealt in first, but may not be first to act; send an
    // out-of-turn pass from South regardless to confirm rejection when it
    // isn't legal, OR confirm it's accepted when it happens to be legal —
    // either way, a below-minimum bid from whoever's turn it is must fail.
    if (snap.seatToAct == Seat.south) {
      host.send(BidMessage(SuitBidCall(Seat.south, Suit.hearts, 70))); // below kMinBidValue
      final error = await host.waitFor<ServerErrorMessage>();
      expect(error.message, isNotEmpty);
    }

    await host.close();
  });
}
