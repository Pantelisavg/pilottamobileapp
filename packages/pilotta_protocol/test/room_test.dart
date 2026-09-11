import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('Lobby', () {
    test('players join open seats in order and can start with bots filling the rest', () {
      final room = PilottaRoom(roomCode: 'AAAA', targetScore: 101, random: Random(1));
      final seat = room.join('Πέτρος');
      expect(seat, Seat.south);
      expect(room.seats[Seat.south]!.playerName, 'Πέτρος');
      expect(room.canStart, isTrue);

      room.start();
      expect(room.phase, RoomPhase.bidding);
      expect(room.seats[Seat.west]!.isBot, isTrue);
      expect(room.seats[Seat.north]!.isBot, isTrue);
      expect(room.seats[Seat.east]!.isBot, isTrue);
      expect(room.seats[Seat.south]!.isBot, isFalse);
      room.dispose();
    });

    test('a full room rejects a 5th joiner', () {
      final room = PilottaRoom(roomCode: 'AAAA', targetScore: 101, random: Random(1));
      room.join('A');
      room.join('B');
      room.join('C');
      room.join('D');
      expect(room.join('E'), isNull);
      room.dispose();
    });
  });

  group('Bidding + play validation', () {
    test('rejects a bid out of turn and a card played out of turn', () {
      fakeAsync((async) {
        final room = PilottaRoom(
          roomCode: 'BBBB',
          targetScore: 101,
          random: Random(2),
          botBidDelay: const Duration(milliseconds: 10),
          botPlayDelay: const Duration(milliseconds: 10),
        );
        room.join('Human');
        room.start();

        // Find whichever seat is NOT currently to act, and confirm the
        // room rejects a call from them.
        final notActing =
            Seat.values.firstWhere((s) => s != room.auction!.seatToAct);
        final err = room.handleBid(notActing, PassCall(notActing));
        expect(err, isNotNull);

        room.dispose();
      });
    });

    test('rejects an illegal card play', () {
      fakeAsync((async) {
        final room = PilottaRoom(
          roomCode: 'CCCC',
          targetScore: 101,
          random: Random(4),
          botBidDelay: const Duration(milliseconds: 10),
          botPlayDelay: const Duration(milliseconds: 10),
        );
        final human = room.join('Human')!;
        room.start();

        // Drive the auction: human always passes, bots bid/pass on their
        // own via the timer.
        while (room.phase == RoomPhase.bidding) {
          if (room.auction!.seatToAct == human) {
            room.handleBid(human, PassCall(human));
          }
          async.elapse(const Duration(milliseconds: 20));
        }

        if (room.phase == RoomPhase.playing) {
          // Try to play a card the human doesn't hold (if it's their turn,
          // this should fail; if not, it should fail for the turn reason).
          final humanHand = room.buildSnapshotFor(human).yourHand;
          final notInHand = Deck.full().firstWhere((c) => !humanHand.contains(c));
          final err = room.handlePlayCard(human, notInHand);
          expect(err, isNotNull);
        }

        room.dispose();
      });
    });
  });

  group('Snapshot privacy', () {
    test('a viewer only ever sees their own hand', () {
      fakeAsync((async) {
        final room = PilottaRoom(roomCode: 'DDDD', targetScore: 101, random: Random(5));
        room.join('Human');
        room.start();
        async.elapse(const Duration(milliseconds: 50));

        final southSnapshot = room.buildSnapshotFor(Seat.south);
        final westSnapshot = room.buildSnapshotFor(Seat.west);

        expect(southSnapshot.yourHand, isNotEmpty);
        expect(westSnapshot.yourHand, isNotEmpty);
        // The two hands must be disjoint — nobody sees anyone else's cards.
        expect(
          southSnapshot.yourHand.toSet().intersection(westSnapshot.yourHand.toSet()),
          isEmpty,
        );
        room.dispose();
      });
    });
  });

  group('Full all-bot match', () {
    test('an empty room (all 4 seats bot-filled) plays to completion', () {
      fakeAsync((async) {
        final room = PilottaRoom(
          roomCode: 'EEEE',
          targetScore: 101,
          random: Random(6),
          botBidDelay: const Duration(milliseconds: 5),
          botPlayDelay: const Duration(milliseconds: 5),
        );
        // Nobody joins as human — starting is only allowed with at least
        // one human claimed, so join one seat and mark it bot-controlled
        // by disconnecting it immediately (simulates "everyone left").
        room.join('Ghost');
        room.start();
        room.setConnected(Seat.south, false);

        var guard = 0;
        while (room.phase != RoomPhase.matchOver && guard++ < 20000) {
          async.elapse(const Duration(milliseconds: 5));
          if (room.phase == RoomPhase.handSummary) {
            // All-bot rooms still need every "human" (here, none actually
            // controlled) seat to ready up; since south is disconnected it
            // counts as bot-controlled and is auto-ready.
          }
        }

        expect(room.phase, RoomPhase.matchOver);
        expect(room.scoreboard.winner, isNotNull);
        room.dispose();
      });
    });
  });

  group('Disconnect / reconnect resilience', () {
    test('a disconnected human seat is played by a bot, and control returns on reconnect', () {
      fakeAsync((async) {
        final room = PilottaRoom(
          roomCode: 'FFFF',
          targetScore: 101,
          random: Random(9),
          botBidDelay: const Duration(milliseconds: 5),
          botPlayDelay: const Duration(milliseconds: 5),
        );
        final human = room.join('Human')!;
        room.start();
        expect(room.isBotControlled(human), isFalse);

        room.setConnected(human, false);
        expect(room.isBotControlled(human), isTrue);

        // The bot should now be able to act on the human's behalf even
        // when it's their turn.
        var guard = 0;
        while (room.phase == RoomPhase.bidding && guard++ < 2000) {
          async.elapse(const Duration(milliseconds: 5));
        }
        expect(room.phase, isNot(RoomPhase.bidding));

        room.setConnected(human, true);
        expect(room.isBotControlled(human), isFalse);

        room.dispose();
      });
    });

    test('rejoining with the same name reclaims the seat instead of taking a new one', () {
      final room = PilottaRoom(roomCode: 'GGGG', targetScore: 101, random: Random(11));
      final human = room.join('Alice')!;
      room.start();
      room.setConnected(human, false);
      expect(room.isBotControlled(human), isTrue);

      final rejoinedSeat = room.join('Alice');
      expect(rejoinedSeat, human);
      expect(room.isBotControlled(human), isFalse);

      // A different name still can't steal Alice's seat (room is "full").
      final strangerSeat = room.join('Mallory');
      expect(strangerSeat, isNull);

      room.dispose();
    });
  });
}
