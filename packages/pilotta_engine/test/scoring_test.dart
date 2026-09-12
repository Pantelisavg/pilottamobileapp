import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:test/test.dart';

void main() {
  group('roundToTens', () {
    test('example from the rules: 287-43 rounds to 29-4', () {
      final result = roundToTens(
        northSouthTotal: 287,
        eastWestTotal: 43,
        biddingTeam: Team.northSouth,
      );
      expect(result.northSouth, 29);
      expect(result.eastWest, 4);
    });

    test('a remainder of exactly 5 rounds down, not up (pilotta.io: 85 -> 8)', () {
      final result = roundToTens(
        northSouthTotal: 85,
        eastWestTotal: 77,
        biddingTeam: Team.northSouth,
      );
      expect(result.northSouth, 8); // 85 -> 8, not 9
      expect(result.eastWest, 8); // 77 -> 8 (remainder 7 rounds up)
    });

    test('"Ο Κανόνας του 6": both remainders exactly 6, bidding team rounds up', () {
      // 126-36 from the rules text: the bidding team (here northSouth)
      // rounds up regardless of which side actually won more raw trick
      // points — this is a fixed tie-break by role, not by point count.
      final result = roundToTens(
        northSouthTotal: 126,
        eastWestTotal: 36,
        biddingTeam: Team.northSouth,
      );
      expect(result.northSouth, 13); // rounds up: bidding team
      expect(result.eastWest, 3); // rounds down: defence

      final reversed = roundToTens(
        northSouthTotal: 126,
        eastWestTotal: 36,
        biddingTeam: Team.eastWest,
      );
      expect(reversed.northSouth, 12); // now forced down: not the bidder
      expect(reversed.eastWest, 4); // rounds up: the bidder
    });

    test('no remainder on either side: exact division', () {
      final result = roundToTens(
        northSouthTotal: 160,
        eastWestTotal: 0,
        biddingTeam: Team.northSouth,
      );
      expect(result.northSouth, 16);
      expect(result.eastWest, 0);
    });

    test('worked example from the Cypriot rules text: 180-62 rounds to 18-6, '
        'not 18-7 — a larger remainder below the threshold still rounds down', () {
      final result = roundToTens(
        northSouthTotal: 180,
        eastWestTotal: 62,
        biddingTeam: Team.northSouth,
      );
      expect(result.northSouth, 18);
      expect(result.eastWest, 6);
    });
  });

  group('settleContract', () {
    test('plain contract made: keeps own points plus contract value', () {
      final settlement = settleContract(
        biddingTeam: Team.northSouth,
        biddingTeamPoints: 100,
        opponentPoints: 62,
        contractValue: 80,
      );
      expect(settlement.contractMade, isTrue);
      expect(settlement.rawTotals[Team.northSouth], 100 + 80);
      expect(settlement.rawTotals[Team.eastWest], 62);
    });

    test('plain contract failed: defence gets the bid plus the whole pool '
        '(bid + all 162 trick points + all declarations), per the rules '
        'spec — not just the pool', () {
      final settlement = settleContract(
        biddingTeam: Team.northSouth,
        biddingTeamPoints: 60,
        opponentPoints: 102,
        contractValue: 80,
      );
      expect(settlement.contractMade, isFalse);
      expect(settlement.rawTotals[Team.northSouth], 0);
      expect(settlement.rawTotals[Team.eastWest], 80 + 60 + 102);
    });

    test('doubled and made: pilotta.io worked example (80 bid, 97 vs 65 trick '
        'points, no declarations) scores 322-0, not a per-side multiply', () {
      final settlement = settleContract(
        biddingTeam: Team.northSouth,
        biddingTeamPoints: 97,
        opponentPoints: 65,
        contractValue: 80,
        multiplierFactor: 2,
      );
      expect(settlement.contractMade, isTrue);
      // 80*2 (doubled contract value) + 162 (full trick/declaration pool).
      expect(settlement.rawTotals[Team.northSouth], 322);
      // Doubling strips the defence of the points it would normally have
      // kept in a plain contract.
      expect(settlement.rawTotals[Team.eastWest], 0);
    });

    test('redoubled and made: contract value is quadrupled, pool still flat', () {
      final settlement = settleContract(
        biddingTeam: Team.northSouth,
        biddingTeamPoints: 97,
        opponentPoints: 65,
        contractValue: 80,
        multiplierFactor: 4,
      );
      expect(settlement.rawTotals[Team.northSouth], 80 * 4 + 162);
      expect(settlement.rawTotals[Team.eastWest], 0);
    });

    test('doubled and failed: the defence sweeps the pool plus the doubled '
        'contract value, per the rules spec\'s "bid + all 162 trick points '
        '+ all declarations" formula scaled by the doubling multiplier', () {
      final settlement = settleContract(
        biddingTeam: Team.northSouth,
        biddingTeamPoints: 60,
        opponentPoints: 102,
        contractValue: 80,
        multiplierFactor: 2,
      );
      expect(settlement.contractMade, isFalse);
      expect(settlement.rawTotals[Team.northSouth], 0);
      expect(settlement.rawTotals[Team.eastWest], 80 * 2 + 162);
    });

    test('capot contract success is judged by madeOverride, not points', () {
      final settlement = settleContract(
        biddingTeam: Team.northSouth,
        biddingTeamPoints: 300, // would normally exceed contractValue
        opponentPoints: 0,
        contractValue: kCapotValue,
        madeOverride: false, // did not actually sweep all tricks
      );
      expect(settlement.contractMade, isFalse);
      expect(settlement.rawTotals[Team.northSouth], 0);
    });

    test('reverse capot: bidding team bids capot but the defence sweeps all '
        '8 tricks instead — the defence gets the bid (250) plus the whole '
        'pool, same failed-contract formula as any other failed bid', () {
      final settlement = settleContract(
        biddingTeam: Team.northSouth,
        biddingTeamPoints: 0,
        opponentPoints: kTotalTrickPoints, // defence swept everything
        contractValue: kCapotValue,
        madeOverride: false,
      );
      expect(settlement.contractMade, isFalse);
      expect(settlement.rawTotals[Team.northSouth], 0);
      expect(settlement.rawTotals[Team.eastWest], kCapotValue + kTotalTrickPoints);
    });
  });
}
