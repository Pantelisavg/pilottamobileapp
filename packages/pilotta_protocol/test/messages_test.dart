import 'dart:convert';

import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:test/test.dart';

/// Round-trips a message through JSON encode+decode, the same as it would
/// travel over a WebSocket or a Nearby Connections byte payload.
T roundTripClient<T extends ClientMessage>(T message) {
  final jsonString = jsonEncode(message.toJson());
  return ClientMessage.fromJson(jsonDecode(jsonString) as Map<String, dynamic>) as T;
}

T roundTripServer<T extends ServerMessage>(T message) {
  final jsonString = jsonEncode(message.toJson());
  return ServerMessage.fromJson(jsonDecode(jsonString) as Map<String, dynamic>) as T;
}

void main() {
  group('Card codec', () {
    test('round-trips every card', () {
      for (final card in Deck.full()) {
        final decoded = cardFromJson(cardToJson(card));
        expect(decoded, card);
      }
    });
  });

  group('AuctionCall codec', () {
    test('round-trips every call type', () {
      final calls = [
        PassCall(Seat.south),
        SuitBidCall(Seat.west, Suit.hearts, 110),
        CapotCall(Seat.north, Suit.clubs),
        DoubleCall(Seat.east),
        RedoubleCall(Seat.south),
      ];
      for (final call in calls) {
        final decoded = auctionCallFromJson(auctionCallToJson(call));
        expect(decoded.runtimeType, call.runtimeType);
        expect(decoded.seat, call.seat);
        if (call is SuitBidCall) {
          expect((decoded as SuitBidCall).suit, call.suit);
          expect(decoded.value, call.value);
        }
        if (call is CapotCall) {
          expect((decoded as CapotCall).suit, call.suit);
        }
      }
    });
  });

  group('ClientMessage round trips', () {
    test('create_room', () {
      final decoded = roundTripClient(
          CreateRoomMessage(playerName: 'Πέτρος', targetScore: 151));
      expect(decoded.playerName, 'Πέτρος');
      expect(decoded.targetScore, 151);
    });

    test('join_room', () {
      final decoded =
          roundTripClient(JoinRoomMessage(roomCode: 'AB12', playerName: 'Νίκος'));
      expect(decoded.roomCode, 'AB12');
      expect(decoded.playerName, 'Νίκος');
    });

    test('start / ready_for_next_hand / leave', () {
      expect(roundTripClient(const StartMessage()), isA<StartMessage>());
      expect(roundTripClient(const ReadyForNextHandMessage()),
          isA<ReadyForNextHandMessage>());
      expect(roundTripClient(const LeaveMessage()), isA<LeaveMessage>());
    });

    test('bid and play_card carry their payload', () {
      final bid = roundTripClient(BidMessage(SuitBidCall(Seat.south, Suit.spades, 90)));
      expect((bid.call as SuitBidCall).value, 90);

      final play = roundTripClient(PlayCardMessage(const PlayingCard(Suit.hearts, Rank.ace)));
      expect(play.card, const PlayingCard(Suit.hearts, Rank.ace));
    });
  });

  group('ServerMessage round trips', () {
    test('welcome', () {
      final decoded =
          roundTripServer(WelcomeMessage(roomCode: 'ZZ99', yourSeat: Seat.east));
      expect(decoded.roomCode, 'ZZ99');
      expect(decoded.yourSeat, Seat.east);
    });

    test('error', () {
      final decoded = roundTripServer(ServerErrorMessage('room is full'));
      expect(decoded.message, 'room is full');
    });

    test('snapshot preserves hidden-hand privacy fields and public state', () {
      final snapshot = RoomSnapshotMessage(
        roomCode: 'ABCD',
        yourSeat: Seat.south,
        phase: RoomPhase.playing,
        seats: {
          Seat.south: const SeatInfo(playerName: 'Εσύ', isBot: false, connected: true),
          Seat.west: const SeatInfo(playerName: null, isBot: true, connected: true),
          Seat.north: const SeatInfo(playerName: 'Φίλος', isBot: false, connected: true),
          Seat.east: const SeatInfo(playerName: null, isBot: true, connected: true),
        },
        targetScore: 101,
        totals: {'northSouth': 40, 'eastWest': 20},
        dealer: Seat.west,
        seatToAct: Seat.south,
        contract: {'trumpSuit': 'spades', 'value': 90, 'isCapot': false},
        yourHand: const [
          PlayingCard(Suit.spades, Rank.jack),
          PlayingCard(Suit.hearts, Rank.ace),
        ],
        handSizes: {Seat.south: 2, Seat.west: 8, Seat.north: 8, Seat.east: 8},
        currentTrick: const [],
        trickLeader: Seat.south,
        banner: 'Νότος: Σκάλα 3 (20 π.)',
        readyForNextHand: {Seat.south},
      );

      final decoded = roundTripServer(snapshot);
      expect(decoded.roomCode, 'ABCD');
      expect(decoded.phase, RoomPhase.playing);
      expect(decoded.seats[Seat.west]!.isBot, isTrue);
      expect(decoded.seats[Seat.north]!.playerName, 'Φίλος');
      expect(decoded.yourHand, snapshot.yourHand);
      expect(decoded.handSizes[Seat.west], 8);
      expect(decoded.readyForNextHand, {Seat.south});
      expect(decoded.totals['northSouth'], 40);
    });
  });
}
