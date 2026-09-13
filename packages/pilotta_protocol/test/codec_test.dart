import 'dart:convert';
import 'dart:math';

import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:test/test.dart';

Map<String, dynamic> roundTripJson(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  group('handResultToJson / handResultFromJson', () {
    HandResult playHand({required List<AuctionCall> auctionCalls}) {
      final hands = dealHands(Random(2));
      final contract = Contract(
        biddingSeat: Seat.south,
        trumpSuit: Suit.spades,
        value: 80,
        isCapot: false,
      );
      final hand = PilottaHand(
        contract: contract,
        initialHands: hands,
        firstLeader: Seat.south,
        auctionCalls: auctionCalls,
      );
      while (!hand.isHandComplete) {
        if (hand.currentTrick.isComplete) {
          hand.startNextTrick();
          continue;
        }
        final seat = hand.currentTrick.seatToPlay;
        hand.playCard(seat, hand.legalPlays(seat).first);
      }
      return hand.finish();
    }

    test(
        'round-trips the auction, original deal, and every completed trick '
        'through JSON — needed for the "replay this hand" scoreboard '
        'feature, both for local save/resume and for the online snapshot', () {
      final calls = [
        SuitBidCall(Seat.south, Suit.spades, 80),
        PassCall(Seat.west),
        PassCall(Seat.north),
        PassCall(Seat.east),
      ];
      final result = playHand(auctionCalls: calls);

      final decoded =
          handResultFromJson(roundTripJson(handResultToJson(result)));

      expect(decoded.auctionCalls.length, calls.length);
      for (var i = 0; i < calls.length; i++) {
        expect(decoded.auctionCalls[i].seat, calls[i].seat);
        expect(decoded.auctionCalls[i].runtimeType, calls[i].runtimeType);
      }

      for (final seat in Seat.values) {
        expect(decoded.originalHands[seat], result.originalHands[seat]);
      }

      expect(decoded.tricks, hasLength(8));
      for (var i = 0; i < 8; i++) {
        expect(decoded.tricks[i].leader, result.tricks[i].leader);
        expect(decoded.tricks[i].winner, result.tricks[i].winner);
        expect(decoded.tricks[i].played, result.tricks[i].played);
      }
    });

    test(
        'still decodes a HandResult JSON saved before this feature existed '
        '— auctionCalls/originalHands/tricks all default to empty rather '
        'than throwing', () {
      final result = playHand(auctionCalls: const []);
      final json = handResultToJson(result)
        ..remove('auctionCalls')
        ..remove('originalHands')
        ..remove('tricks');

      final decoded = handResultFromJson(roundTripJson(json));

      expect(decoded.auctionCalls, isEmpty);
      expect(decoded.originalHands, isEmpty);
      expect(decoded.tricks, isEmpty);
      // The fields that did exist before this feature still round-trip
      // correctly regardless.
      expect(decoded.contractMade, result.contractMade);
      expect(decoded.rounded.northSouth, result.rounded.northSouth);
      expect(decoded.rounded.eastWest, result.rounded.eastWest);
    });
  });
}
