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
