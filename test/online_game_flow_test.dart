import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/controllers/online_game_controller.dart';
import 'package:pilotta/controllers/room_client_controller.dart';
import 'package:pilotta/screens/networked_game_screen.dart';
import 'package:pilotta/settings/app_settings.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:pilotta_server/app.dart';
import 'package:pilotta_server/room_registry.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// End-to-end check that the real app widgets, talking to a real running
/// instance of the server package over a real WebSocket on localhost, can
/// take a host from an empty lobby through to a dealt hand — the same path
/// a phone would take against a hosted server, minus the network hop.
///
/// Everything that touches real sockets (starting the server, connecting,
/// waiting for round trips) has to run inside `tester.runAsync`: the
/// default widget-test zone fakes the clock and never lets real dart:io
/// callbacks complete.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('creating a room, starting it, and seeing the dealt hand renders end to end',
      (tester) async {
    late HttpServer server;
    late OnlineGameController controller;
    late AppSettings settings;

    await tester.runAsync(() async {
      final registry = RoomRegistry();
      server = await shelf_io.serve(buildHandler(registry), InternetAddress.loopbackIPv4, 0);
      final wsUri = Uri.parse('ws://${server.address.host}:${server.port}/ws');
      controller = OnlineGameController(serverUri: wsUri);
      settings = await AppSettings.load();
    });
    addTearDown(() => controller.dispose());
    addTearDown(() => server.close(force: true));

    await tester.pumpWidget(MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<RoomClientController>.value(value: controller),
          ChangeNotifierProvider<AppSettings>.value(value: settings),
        ],
        child: const NetworkedGameScreen(),
      ),
    ));
    await tester.pump();

    await tester.runAsync(() async {
      controller.createRoom(playerName: 'Δοκιμή', targetScore: 101);
      for (var i = 0; i < 100 && !controller.inRoom; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();

    expect(controller.inRoom, isTrue);
    expect(controller.mySeat, Seat.south);
    expect(find.text('Κωδικός δωματίου'), findsOneWidget);
    expect(find.text(controller.roomCode!), findsOneWidget);
    expect(find.textContaining('Έναρξη'), findsOneWidget);

    await tester.runAsync(() async {
      controller.start();
      for (var i = 0; i < 100 && controller.snapshot!.phase == RoomPhase.lobby; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();

    expect(controller.snapshot!.phase, RoomPhase.bidding);
    expect(controller.snapshot!.yourHand, hasLength(8));
    // The table screen (not the lobby) should now be showing.
    expect(find.text('Κωδικός δωματίου'), findsNothing);
  });
}
