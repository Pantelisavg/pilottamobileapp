import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:test/test.dart';

void main() {
  group('roundToTens', () {
    test('example from the rules: 287-43 rounds to 29-4', () {
      final result = roundToTens(
        northSouthTotal: 287,
        eastWestTotal: 43,
        northSouthRawTrickPoints: 287 % 100, // any non-multiple-of-10 works
        eastWestRawTrickPoints: 43,
      );
      expect(result.northSouth, 29);
      expect(result.eastWest, 4);
    });

    test('equal remainders: team with more raw trick points rounds up', () {
      // Both totals end in 6; northSouth actually won more trick points.
      final result = roundToTens(
        northSouthTotal: 96,
        eastWestTotal: 66,
        northSouthRawTrickPoints: 96,
        eastWestRawTrickPoints: 66,
      );
      expect(result.northSouth, 10); // 9.6 -> rounds up
      expect(result.eastWest, 6); // 6.6 -> rounds down
    });

    test('no remainder on either side: exact division', () {
      final result = roundToTens(
        northSouthTotal: 160,
        eastWestTotal: 0,
        northSouthRawTrickPoints: 160,
        eastWestRawTrickPoints: 0,
      );
      expect(result.northSouth, 16);
      expect(result.eastWest, 0);
    });

    test('worked example from the Cypriot rules text: 180-62 rounds to 18-6, '
        'not 18-7 — a larger remainder below 5 still rounds down', () {
      // Bidding team bid 80, won 100 trick points (total 180, remainder 0);
      // defenders won 62 (remainder 2). 2 is numerically the larger
      // remainder of the two, but since it's still under the halfway
      // point it must round down, not up.
      final result = roundToTens(
        northSouthTotal: 180,
        eastWestTotal: 62,
        northSouthRawTrickPoints: 100,
        eastWestRawTrickPoints: 62,
      );
      expect(result.northSouth, 18);
      expect(result.eastWest, 6);
    });

    test('both remainders >= 5 but unequal (5 and 7): still only one rounds up', () {
      // 135 (remainder 5) and 27 (remainder 7) sum to 162: both remainders
      // individually clear the halfway mark, so without the conflict rule
      // both would round up and overshoot the fixed 162-point pool by one
      // unit. Raw trick points decide: eastWest actually won more (127
      // vs 35 — northSouth's total includes a 100-point contract bonus).
      final result = roundToTens(
        northSouthTotal: 135,
        eastWestTotal: 27,
        northSouthRawTrickPoints: 35,
        eastWestRawTrickPoints: 127,
      );
      expect(result.northSouth, 13); // forced down despite remainder 5
      expect(result.eastWest, 3); // rounds up: 2 + 1
    });
  });

  group('settleContract', () {
    test('bidding team makes contract: keeps points plus contract value', () {
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

    test('bidding team fails: all points go to the opponents', () {
      final settlement = settleContract(
        biddingTeam: Team.northSouth,
        biddingTeamPoints: 60,
        opponentPoints: 102,
        contractValue: 80,
      );
      expect(settlement.contractMade, isFalse);
      expect(settlement.rawTotals[Team.northSouth], 0);
      expect(settlement.rawTotals[Team.eastWest], 60 + 102);
    });

    test('doubled contract multiplies the winning side only', () {
      final made = settleContract(
        biddingTeam: Team.northSouth,
        biddingTeamPoints: 100,
        opponentPoints: 62,
        contractValue: 80,
        multiplierFactor: 2,
      );
      expect(made.rawTotals[Team.northSouth], (100 + 80) * 2);
      expect(made.rawTotals[Team.eastWest], 62);

      final failed = settleContract(
        biddingTeam: Team.northSouth,
        biddingTeamPoints: 60,
        opponentPoints: 102,
        contractValue: 80,
        multiplierFactor: 2,
      );
      expect(failed.rawTotals[Team.northSouth], 0);
      expect(failed.rawTotals[Team.eastWest], (60 + 102) * 2);
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
  });
}
