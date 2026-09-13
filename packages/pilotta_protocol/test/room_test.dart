import 'dart:convert';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('Lobby', () {
    test(
        'players join open seats in order and can start with bots filling the rest',
        () {
      final room =
          PilottaRoom(roomCode: 'AAAA', targetScore: 101, random: Random(1));
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
      final room =
          PilottaRoom(roomCode: 'AAAA', targetScore: 101, random: Random(1));
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
          final notInHand =
              Deck.full().firstWhere((c) => !humanHand.contains(c));
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
        final room =
            PilottaRoom(roomCode: 'DDDD', targetScore: 101, random: Random(5));
        room.join('Human');
        room.start();
        async.elapse(const Duration(milliseconds: 50));

        final southSnapshot = room.buildSnapshotFor(Seat.south);
        final westSnapshot = room.buildSnapshotFor(Seat.west);

        expect(southSnapshot.yourHand, isNotEmpty);
        expect(westSnapshot.yourHand, isNotEmpty);
        // The two hands must be disjoint — nobody sees anyone else's cards.
        expect(
          southSnapshot.yourHand
              .toSet()
              .intersection(westSnapshot.yourHand.toSet()),
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
          trickCollectDelay: const Duration(milliseconds: 5),
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

  group('Declarations (announce/reveal)', () {
    /// Finds a seed whose dealt hand gives at least one seat an actual
    /// declaration to test the announce/reveal flow against, and drives
    /// the auction (south bids 80 spades, everyone else passes) to reach
    /// [RoomPhase.playing] deterministically regardless of seed.
    PilottaRoom roomWithADeclaration() {
      for (var seed = 0; seed < 60; seed++) {
        final room = PilottaRoom(
          roomCode: 'IIII',
          targetScore: 101,
          random: Random(seed),
          trickCollectDelay: const Duration(milliseconds: 5),
        );
        for (final name in ['A', 'B', 'C', 'D']) {
          room.join(name);
        }
        room.start();
        final firstToAct = room.auction!.seatToAct;
        room.handleBid(firstToAct, SuitBidCall(firstToAct, Suit.spades, 80));
        var next = firstToAct.next;
        while (room.phase == RoomPhase.bidding) {
          room.handleBid(next, PassCall(next));
          next = next.next;
        }
        if (Seat.values.any((s) => room.hand!.bestDeclarationOf(s) != null)) {
          return room;
        }
        room.dispose();
      }
      fail('No seed in range produced a hand with any declaration.');
    }

    test(
        'a human seat can announce during trick 1 and reveal before their '
        'trick-2 card, and it counts towards the final score', () {
      fakeAsync((async) {
        final room = roomWithADeclaration();
        final seat = Seat.values
            .firstWhere((s) => room.hand!.bestDeclarationOf(s) != null);
        final expectedPoints = room.hand!.bestDeclarationOf(seat)!.pointValue();

        expect(room.handleAnnounceDeclaration(seat), isNull);
        expect(room.hand!.declarationStateOf(seat),
            DeclarationAnnounceState.announced);

        // Play out trick 1 with everyone's first legal card. A completed
        // trick sits on the table for [trickCollectDelay] before the next
        // one starts, so elapse past that after every play.
        while (room.hand!.completedTricks.isEmpty) {
          final toAct = room.hand!.currentTrick.seatToPlay;
          room.handlePlayCard(toAct, room.hand!.legalPlays(toAct).first);
          async.elapse(const Duration(milliseconds: 10));
        }

        // Play trick 2 up to (not including) this seat's own turn, then reveal.
        while (room.hand!.currentTrick.seatToPlay != seat) {
          final toAct = room.hand!.currentTrick.seatToPlay;
          room.handlePlayCard(toAct, room.hand!.legalPlays(toAct).first);
          async.elapse(const Duration(milliseconds: 10));
        }
        expect(room.handleRevealDeclaration(seat), isNull);
        expect(room.hand!.declarationStateOf(seat),
            DeclarationAnnounceState.revealed);

        // Play out the rest of the hand.
        while (room.phase == RoomPhase.playing) {
          final toAct = room.hand!.currentTrick.seatToPlay;
          room.handlePlayCard(toAct, room.hand!.legalPlays(toAct).first);
          async.elapse(const Duration(milliseconds: 10));
        }

        final result = room.lastHandResult!;
        expect(result.declarations.bestPerSeat[seat]?.pointValue(),
            expectedPoints);
        room.dispose();
      });
    });

    test('a human seat that forgets to reveal forfeits the declaration', () {
      fakeAsync((async) {
        final room = roomWithADeclaration();
        final seat = Seat.values
            .firstWhere((s) => room.hand!.bestDeclarationOf(s) != null);

        expect(room.handleAnnounceDeclaration(seat), isNull);

        // Play the whole hand out without ever revealing.
        while (room.phase == RoomPhase.playing) {
          final toAct = room.hand!.currentTrick.seatToPlay;
          room.handlePlayCard(toAct, room.hand!.legalPlays(toAct).first);
          async.elapse(const Duration(milliseconds: 10));
        }

        final result = room.lastHandResult!;
        expect(result.declarations.bestPerSeat[seat], isNull);
        expect(result.declarations.forfeitedPerSeat[seat], isNotNull);
        room.dispose();
      });
    });

    test(
        'a bot-controlled seat cannot announce or reveal directly — bots '
        'handle their own declarations automatically', () {
      fakeAsync((async) {
        final room = PilottaRoom(
          roomCode: 'KKKK',
          targetScore: 101,
          random: Random(6),
          botBidDelay: const Duration(milliseconds: 5),
          botPlayDelay: const Duration(milliseconds: 5),
        );
        room.join('Solo');
        room.start(); // fills west/north/east with bots
        room.setConnected(Seat.south, false); // south plays as a bot too
        var guard = 0;
        while (room.phase == RoomPhase.bidding && guard++ < 2000) {
          async.elapse(const Duration(milliseconds: 5));
        }
        expect(room.phase, RoomPhase.playing);

        final botSeat = Seat.values.firstWhere((s) => room.isBotControlled(s));
        expect(room.handleAnnounceDeclaration(botSeat), isNotNull);
        expect(room.handleRevealDeclaration(botSeat), isNotNull);
        room.dispose();
      });
    });

    test(
        'the room house-rule flag is threaded down to actual trick '
        'legality (mustOvertrumpAllSuits)', () {
      final room = PilottaRoom(
        roomCode: 'JJJJ',
        targetScore: 101,
        random: Random(7),
        mustOvertrumpAllSuits: true,
      );
      // All 4 seats human, so bidding is fully caller-driven with no risk
      // of a bot-controlled seat rejecting a manually-issued call.
      for (final name in ['A', 'B', 'C', 'D']) {
        room.join(name);
      }
      room.start();
      final firstToAct = room.auction!.seatToAct;
      room.handleBid(firstToAct, SuitBidCall(firstToAct, Suit.spades, 80));
      var next = firstToAct.next;
      while (room.phase == RoomPhase.bidding) {
        room.handleBid(next, PassCall(next));
        next = next.next;
      }
      expect(room.hand!.mustOvertrumpAllSuits, isTrue);
      room.dispose();
    });
  });

  group('Disconnect / reconnect resilience', () {
    test(
        'a disconnected human seat is played by a bot, and control returns on reconnect',
        () {
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

    test(
        'rejoining with the same name reclaims the seat instead of taking a new one',
        () {
      final room =
          PilottaRoom(roomCode: 'GGGG', targetScore: 101, random: Random(11));
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

  group('Chat', () {
    test('sendChat appends a message visible in chatLog, and validates input',
        () {
      final room =
          PilottaRoom(roomCode: 'MMMM', targetScore: 101, random: Random(1));
      final south = room.join('A')!;
      room.join('B');
      room.join('C');
      room.join('D');
      room.start();

      expect(room.sendChat(south, ''), isNotNull);
      expect(room.chatLog, isEmpty);

      expect(room.sendChat(south, 'Γεια σας!'), isNull);
      expect(room.chatLog, hasLength(1));
      expect(room.chatLog.single.kind, ChatEntryKind.chat);
      expect(room.chatLog.single.seat, south);
      expect(room.chatLog.single.text, 'Γεια σας!');

      expect(room.sendChat(south, 'x' * 201), isNotNull);
      expect(room.chatLog, hasLength(1));

      room.dispose();
    });

    test(
        'announcing/revealing a declaration pushes chat entries, without '
        'leaking its content before reveal', () {
      final room =
          PilottaRoom(roomCode: 'OOOO', targetScore: 101, random: Random(1));
      for (final name in ['A', 'B', 'C', 'D']) {
        room.join(name);
      }
      room.start();
      final firstToAct = room.auction!.seatToAct;
      room.handleBid(firstToAct, SuitBidCall(firstToAct, Suit.spades, 80));
      var next = firstToAct.next;
      while (room.phase == RoomPhase.bidding) {
        room.handleBid(next, PassCall(next));
        next = next.next;
      }

      // Replace the dealt hand with one where South definitely holds a
      // declaration (Jack-Ten-Nine of hearts, a 3-card sequence).
      room.hand = PilottaHand(
        contract: room.hand!.contract,
        firstLeader: Seat.south,
        initialHands: {
          Seat.south: [
            const PlayingCard(Suit.hearts, Rank.jack),
            const PlayingCard(Suit.hearts, Rank.ten),
            const PlayingCard(Suit.hearts, Rank.nine),
            const PlayingCard(Suit.clubs, Rank.seven),
            const PlayingCard(Suit.clubs, Rank.eight),
            const PlayingCard(Suit.clubs, Rank.nine),
            const PlayingCard(Suit.clubs, Rank.ten),
            const PlayingCard(Suit.clubs, Rank.jack),
          ],
          Seat.west: [
            const PlayingCard(Suit.hearts, Rank.seven),
            const PlayingCard(Suit.hearts, Rank.eight),
            const PlayingCard(Suit.hearts, Rank.queen),
            const PlayingCard(Suit.hearts, Rank.king),
            const PlayingCard(Suit.hearts, Rank.ace),
            const PlayingCard(Suit.clubs, Rank.queen),
            const PlayingCard(Suit.clubs, Rank.king),
            const PlayingCard(Suit.clubs, Rank.ace),
          ],
          Seat.north: [
            const PlayingCard(Suit.spades, Rank.seven),
            const PlayingCard(Suit.spades, Rank.eight),
            const PlayingCard(Suit.spades, Rank.nine),
            const PlayingCard(Suit.spades, Rank.ten),
            const PlayingCard(Suit.spades, Rank.jack),
            const PlayingCard(Suit.spades, Rank.queen),
            const PlayingCard(Suit.spades, Rank.king),
            const PlayingCard(Suit.spades, Rank.ace),
          ],
          Seat.east: [
            const PlayingCard(Suit.diamonds, Rank.seven),
            const PlayingCard(Suit.diamonds, Rank.eight),
            const PlayingCard(Suit.diamonds, Rank.nine),
            const PlayingCard(Suit.diamonds, Rank.ten),
            const PlayingCard(Suit.diamonds, Rank.jack),
            const PlayingCard(Suit.diamonds, Rank.queen),
            const PlayingCard(Suit.diamonds, Rank.king),
            const PlayingCard(Suit.diamonds, Rank.ace),
          ],
        },
      );

      expect(room.handleAnnounceDeclaration(Seat.south), isNull);
      expect(room.chatLog.last.kind, ChatEntryKind.declarationAnnounced);
      expect(room.chatLog.last.seat, Seat.south);
      expect(room.chatLog.last.declarations, isNull);
      // Only the point value is spoken on announce — South's best here is
      // the 5-card clubs run (100), not the hearts 3-run (20).
      expect(room.chatLog.last.announcedValue, 100);

      expect(room.handleRevealDeclaration(Seat.south), isNull);
      expect(room.chatLog.last.kind, ChatEntryKind.declarationRevealed);
      // South's dealt hand happens to hold two separate declarations here
      // (hearts J-10-9 and clubs J-10-9-8-7) — both are revealed together.
      expect(room.chatLog.last.declarations, hasLength(2));

      room.dispose();
    });
  });

  group('Save / resume', () {
    /// Round-trips [json] through actual JSON encoding, not just Dart
    /// object identity — a real save would go through SharedPreferences as
    /// a string.
    Map<String, dynamic> roundTripJson(Map<String, dynamic> json) =>
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

    test('mid-bidding state round-trips through toSaveJson/restore', () {
      final room =
          PilottaRoom(roomCode: 'PPPP', targetScore: 101, random: Random(1));
      for (final name in ['A', 'B', 'C', 'D']) {
        room.join(name);
      }
      room.start();
      final firstToAct = room.auction!.seatToAct;
      room.handleBid(firstToAct, SuitBidCall(firstToAct, Suit.spades, 80));

      final restored = PilottaRoom.restore(roundTripJson(room.toSaveJson()));

      expect(restored.phase, RoomPhase.bidding);
      expect(restored.auction!.calls, hasLength(1));
      expect(restored.auction!.seatToAct, firstToAct.next);
      for (final seat in Seat.values) {
        expect(restored.seats[seat]!.playerName, room.seats[seat]!.playerName);
      }

      room.dispose();
      restored.dispose();
    });

    test(
        'mid-hand state (a completed trick, a revealed declaration, a '
        "partial next trick) round-trips, and play continues correctly", () {
      PilottaRoom? found;
      Seat? declSeat;
      for (var seed = 0; seed < 60; seed++) {
        final room = PilottaRoom(
          roomCode: 'QQQQ',
          targetScore: 101,
          random: Random(seed),
          trickCollectDelay: const Duration(milliseconds: 5),
        );
        for (final name in ['A', 'B', 'C', 'D']) {
          room.join(name);
        }
        room.start();
        final firstToAct = room.auction!.seatToAct;
        room.handleBid(firstToAct, SuitBidCall(firstToAct, Suit.spades, 80));
        var next = firstToAct.next;
        while (room.phase == RoomPhase.bidding) {
          room.handleBid(next, PassCall(next));
          next = next.next;
        }
        final seat = Seat.values
            .where((s) => room.hand!.bestDeclarationOf(s) != null)
            .firstOrNull;
        if (seat != null) {
          found = room;
          declSeat = seat;
          break;
        }
        room.dispose();
      }
      if (found == null) {
        fail('No seed in range produced a hand with any declaration.');
      }
      final room = found;
      final seat = declSeat!;

      fakeAsync((async) {
        expect(room.handleAnnounceDeclaration(seat), isNull);

        // Play out trick 1.
        while (room.hand!.completedTricks.isEmpty) {
          final toAct = room.hand!.currentTrick.seatToPlay;
          room.handlePlayCard(toAct, room.hand!.legalPlays(toAct).first);
          async.elapse(const Duration(milliseconds: 10));
        }

        // Reveal right before this seat's trick-2 card, then play it.
        while (room.hand!.currentTrick.seatToPlay != seat) {
          final toAct = room.hand!.currentTrick.seatToPlay;
          room.handlePlayCard(toAct, room.hand!.legalPlays(toAct).first);
          async.elapse(const Duration(milliseconds: 10));
        }
        expect(room.handleRevealDeclaration(seat), isNull);
        room.handlePlayCard(seat, room.hand!.legalPlays(seat).first);
        async.elapse(const Duration(milliseconds: 10));

        // Save mid-trick-2 (not necessarily complete).
        final expectedCompletedTricks = room.hand!.completedTricks.length;
        final expectedCurrentTrickPlays = room.hand!.currentTrick.played.length;
        final expectedDeclState = room.hand!.declarationStateOf(seat);
        final expectedValue = room.hand!.bestDeclarationOf(seat)!.pointValue();

        final restored = PilottaRoom.restore(
          roundTripJson(room.toSaveJson()),
          random: Random(999),
          trickCollectDelay: const Duration(milliseconds: 5),
        );

        expect(restored.phase, RoomPhase.playing);
        expect(
            restored.hand!.completedTricks, hasLength(expectedCompletedTricks));
        expect(restored.hand!.currentTrick.played,
            hasLength(expectedCurrentTrickPlays));
        expect(restored.hand!.declarationStateOf(seat), expectedDeclState);
        expect(restored.hand!.bestDeclarationOf(seat)!.pointValue(),
            expectedValue);

        // Play continues correctly to completion from the restored state.
        var guard = 0;
        while (restored.phase == RoomPhase.playing && guard++ < 500) {
          if (!restored.hand!.currentTrick.isComplete) {
            final toAct = restored.hand!.currentTrick.seatToPlay;
            final legal = restored.hand!.legalPlays(toAct);
            if (legal.isNotEmpty) restored.handlePlayCard(toAct, legal.first);
          }
          async.elapse(const Duration(milliseconds: 10));
        }

        expect(restored.phase, RoomPhase.handSummary);
        expect(
            restored.lastHandResult!.declarations.bestPerSeat[seat]
                ?.pointValue(),
            expectedValue);

        room.dispose();
        restored.dispose();
      });
    });

    test('scoreboard history round-trips after a hand finishes', () {
      fakeAsync((async) {
        final room = PilottaRoom(
          roomCode: 'RRRR',
          targetScore: 1000,
          random: Random(6),
          botBidDelay: const Duration(milliseconds: 5),
          botPlayDelay: const Duration(milliseconds: 5),
          trickCollectDelay: const Duration(milliseconds: 5),
        );
        // A human seat that never marks ready keeps the room resting at
        // handSummary — an all-bot room would auto-ready and sail straight
        // past it into the next hand (or straight to matchOver) instead.
        final south = room.join('Human')!;
        room.start();

        var guard = 0;
        while (room.phase == RoomPhase.bidding && guard++ < 2000) {
          if (room.auction!.seatToAct == south) {
            room.handleBid(south, PassCall(south));
          }
          async.elapse(const Duration(milliseconds: 5));
        }
        guard = 0;
        while (room.phase == RoomPhase.playing && guard++ < 5000) {
          final h = room.hand;
          if (h != null &&
              !h.currentTrick.isComplete &&
              h.currentTrick.seatToPlay == south) {
            final legal = h.legalPlays(south);
            if (legal.isNotEmpty) room.handlePlayCard(south, legal.first);
          }
          async.elapse(const Duration(milliseconds: 5));
        }
        expect(room.phase, RoomPhase.handSummary);
        expect(room.scoreboard.history, hasLength(1));

        final restored = PilottaRoom.restore(
          roundTripJson(room.toSaveJson()),
          trickCollectDelay: const Duration(milliseconds: 5),
        );

        expect(restored.phase, RoomPhase.handSummary);
        expect(restored.scoreboard.history, hasLength(1));
        expect(restored.scoreboard.totals[Team.northSouth],
            room.scoreboard.totals[Team.northSouth]);
        expect(restored.scoreboard.totals[Team.eastWest],
            room.scoreboard.totals[Team.eastWest]);

        room.dispose();
        restored.dispose();
      });
    });
  });
}
