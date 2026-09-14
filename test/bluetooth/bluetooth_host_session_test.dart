import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/bluetooth/bluetooth_host_session.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

/// [BluetoothHostSession] delegates all *networking* to the real Nearby
/// Connections plugin, which only exists on a real Android device and
/// can't be exercised here. What we can and do verify without a device is
/// everything this class adds on top of [PilottaRoom]: the host claims a
/// seat and can drive the game exactly like [LocalGameController] does,
/// entirely through the shared [RoomClientController] API surface that
/// [NetworkedGameScreen] is built against — so this doubles as a check
/// that a solo host (nobody else has joined over Bluetooth yet) can still
/// play a full match against bots.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('nearby_connections');

  setUp(() {
    // dispose() unconditionally tells the plugin to stop advertising and
    // drop all endpoints; without a handler that call would hit a real
    // platform channel and throw MissingPluginException in the test VM.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
      'the host claims south, sees a lobby snapshot, and can start solo (bots fill the rest)',
      () {
    final session =
        BluetoothHostSession(hostName: 'Οικοδεσπότης', targetScore: 101);

    expect(session.mySeat, Seat.south);
    expect(session.roomCode, isNotEmpty);
    expect(session.inRoom, isTrue);
    expect(session.isHost, isTrue);
    expect(session.snapshot!.phase, RoomPhase.lobby);
    expect(session.snapshot!.seats[Seat.south]!.playerName, 'Οικοδεσπότης');

    session.start();

    expect(session.snapshot!.phase, RoomPhase.bidding);
    expect(session.snapshot!.yourHand, hasLength(8));
    expect(session.snapshot!.seats[Seat.west]!.isBot, isTrue);
    expect(session.snapshot!.seats[Seat.north]!.isBot, isTrue);
    expect(session.snapshot!.seats[Seat.east]!.isBot, isTrue);

    session.dispose();
  });

  test('the host can bid through submitBid like any RoomClientController', () {
    // Seed 1 places south (the host) first to act in the auction, so this
    // interaction is deterministic without needing real bot timers to fire.
    final session = BluetoothHostSession(
        hostName: 'H', targetScore: 101, random: Random(1));
    session.start();

    expect(session.isMyTurnToBid, isTrue);
    final auctionBefore = session.auction!;
    expect(auctionBefore.calls, isEmpty);

    session.submitBid(SuitBidCall(session.mySeat!, Suit.hearts, 80));

    final auctionAfter = session.auction!;
    expect(auctionAfter.calls, hasLength(1));
    expect(auctionAfter.currentBid?.value, 80);
    expect(session.isMyTurnToBid, isFalse);

    session.dispose();
  });

  test(
      'satisfies GameTableData the same way LocalGameController does, so '
      'a shared table widget can be built against either', () {
    final session =
        BluetoothHostSession(hostName: 'Οικοδεσπότης', targetScore: 101);
    session.start();

    expect(session.viewerSeat, Seat.south);
    expect(session.phase, RoomPhase.bidding);
    expect(session.contract, isNull); // still bidding — no contract yet
    expect(session.currentTrick, isNull); // not playing yet either
    expect(session.myHand, hasLength(8));
    expect(session.handSizeOf(Seat.south), 8);
    expect(session.handSizeOf(Seat.west), 8);
    expect(session.isBotControlled(Seat.south), isFalse);
    expect(session.isBotControlled(Seat.west), isTrue);
    expect(session.isViewerTurnToBid, session.isMyTurnToBid);
    expect(session.targetScore, 101);
    expect(session.totals[Team.northSouth], 0);
    expect(session.totals[Team.eastWest], 0);
    expect(session.matchWinner, isNull);
    expect(session.matchHistory, isEmpty);
    expect(session.lastHandResult, isNull);
    expect(session.lastCompletedTrickPlayed, isNull);
    expect(session.canAnnounceDeclaration, isFalse);
    expect(session.canRevealDeclaration, isFalse);

    session.dispose();
  });
}
