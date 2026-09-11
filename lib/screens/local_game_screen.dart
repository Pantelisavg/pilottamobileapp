import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:provider/provider.dart';

import '../controllers/local_game_controller.dart';
import '../widgets/bidding_panel.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/seat_layout.dart';

class LocalGameScreen extends StatelessWidget {
  final int targetScore;
  const LocalGameScreen({super.key, required this.targetScore});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocalGameController(targetScore: targetScore),
      child: const _GameView(),
    );
  }
}

class _GameView extends StatelessWidget {
  const _GameView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocalGameController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B3D2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF082A20),
        foregroundColor: Colors.white,
        title: _ScoreHeader(controller: controller),
        titleSpacing: 12,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (controller.banner != null)
                  Container(
                    width: double.infinity,
                    color: Colors.amber.shade800,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(controller.banner!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                Expanded(child: _TableArea(controller: controller)),
                _HumanHand(controller: controller),
              ],
            ),
            if (controller.isHumanTurnToBid)
              Align(
                alignment: Alignment.bottomCenter,
                child: BiddingPanel(
                  auction: controller.auction!,
                  seat: controller.humanSeat,
                  onCall: controller.submitBid,
                ),
              ),
            if (controller.phase == RoomPhase.handSummary)
              _HandSummaryOverlay(controller: controller),
            if (controller.phase == RoomPhase.matchOver)
              _MatchOverOverlay(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final LocalGameController controller;
  const _ScoreHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final board = controller.scoreboard;
    final ourTeam = controller.humanSeat.team;
    final contract = controller.hand?.contract;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Εμείς ${board.totals[ourTeam]}  –  Αυτοί ${board.totals[ourTeam.opponent]}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Στόχος: ${board.targetScore}',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        if (contract != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${contract.isCapot ? 'Καπότο' : contract.value}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(suitSymbol(contract.trumpSuit),
                  style: TextStyle(fontSize: 22, color: contract.trumpSuit.isRed ? Colors.red.shade300 : Colors.white)),
              if (contract.multiplier != ContractMultiplier.none)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text('x${contract.multiplier.factor}',
                      style: const TextStyle(fontSize: 14, color: Colors.orangeAccent)),
                ),
            ],
          ),
      ],
    );
  }
}

class _TableArea extends StatelessWidget {
  final LocalGameController controller;
  const _TableArea({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final seat in Seat.values)
          if (seat != controller.humanSeat)
            Align(
              alignment: seatAlignmentRelativeTo(seat, controller.humanSeat),
              child: _OpponentSeat(controller: controller, seat: seat),
            ),
        Center(child: _TrickArea(controller: controller)),
        if (controller.phase == RoomPhase.bidding)
          Align(
            alignment: Alignment.center,
            child: _AuctionStatus(controller: controller),
          ),
      ],
    );
  }
}

class _OpponentSeat extends StatelessWidget {
  final LocalGameController controller;
  final Seat seat;
  const _OpponentSeat({required this.controller, required this.seat});

  @override
  Widget build(BuildContext context) {
    final isActive = controller.phase == RoomPhase.bidding
        ? controller.auction?.seatToAct == seat
        : controller.hand?.currentTrick.seatToPlay == seat;
    final cardCount = controller.handOf(seat).length;
    final isPartner = seat == controller.humanSeat.partner;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? Colors.amber.shade700 : Colors.black38,
              borderRadius: BorderRadius.circular(12),
              border: isPartner ? Border.all(color: Colors.lightGreenAccent, width: 1.5) : null,
            ),
            child: Text(
              '${seatLabelRelativeTo(seat, controller.humanSeat)} · $cardCount',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 34,
            width: 70,
            child: Stack(
              children: [
                for (var i = 0; i < cardCount; i++)
                  Positioned(
                    left: i * 7.0,
                    child: const PlayingCardWidget(faceUp: false, width: 22),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrickArea extends StatelessWidget {
  final LocalGameController controller;
  const _TrickArea({required this.controller});

  @override
  Widget build(BuildContext context) {
    final hand = controller.hand;
    if (hand == null) return const SizedBox.shrink();

    final played = {for (final e in hand.currentTrick.played) e.seat: e.card};

    return SizedBox(
      width: 220,
      height: 200,
      child: Stack(
        children: [
          for (final seat in Seat.values)
            if (played[seat] != null)
              Align(
                alignment: seatAlignmentRelativeTo(seat, controller.humanSeat),
                child: PlayingCardWidget(card: played[seat], width: 52),
              ),
        ],
      ),
    );
  }
}

class _AuctionStatus extends StatelessWidget {
  final LocalGameController controller;
  const _AuctionStatus({required this.controller});

  @override
  Widget build(BuildContext context) {
    final auction = controller.auction;
    if (auction == null) return const SizedBox.shrink();
    final bid = auction.currentBid;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Δηλώσεις', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            bid == null
                ? 'Καμία δήλωση ακόμα'
                : '${bid.isCapot ? 'Καπότο' : bid.value} ${suitSymbol(bid.suit)} — ${seatLabelRelativeTo(bid.seat, controller.humanSeat)}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text('Σειρά: ${seatLabelRelativeTo(auction.seatToAct, controller.humanSeat)}',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
        ],
      ),
    );
  }
}

class _HumanHand extends StatelessWidget {
  final LocalGameController controller;
  const _HumanHand({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cards = controller.handOf(controller.humanSeat);
    final legal = controller.humanLegalPlays.toSet();
    final isMyTurn = controller.isHumanTurnToPlay;

    final sorted = [...cards]..sort((a, b) {
        final suitDiff = a.suit.index.compareTo(b.suit.index);
        if (suitDiff != 0) return suitDiff;
        return plainOrderHighToLow.indexOf(a.rank).compareTo(plainOrderHighToLow.indexOf(b.rank));
      });

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: const Color(0xFF082A20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final card in sorted)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: PlayingCardWidget(
                  card: card,
                  selectable: isMyTurn && legal.contains(card),
                  dimmed: isMyTurn && !legal.contains(card),
                  onTap: () => controller.playCard(card),
                  width: 48,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HandSummaryOverlay extends StatelessWidget {
  final LocalGameController controller;
  const _HandSummaryOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final result = controller.lastHandResult!;
    final ourTeam = controller.humanSeat.team;
    final contract = result.contract;

    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result.contractMade ? 'Το συμβόλαιο βγήκε' : 'Μέσα!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${contract.isCapot ? 'Καπότο' : contract.value} ${suitSymbol(contract.trumpSuit)}'
                ' — ${seatLabelRelativeTo(contract.biddingSeat, controller.humanSeat)}',
                style: const TextStyle(fontSize: 14),
              ),
              const Divider(height: 24),
              _row('Πόντοι φύλλων',
                  '${result.trickPoints[ourTeam]} – ${result.trickPoints[ourTeam.opponent]}'),
              if (result.declarations.winningTeam != null)
                _row(
                  'Δηλώσεις',
                  result.declarations.winningTeam == ourTeam
                      ? '${result.declarations.winningTeamPoints} – 0'
                      : '0 – ${result.declarations.winningTeamPoints}',
                ),
              if (result.declarations.beloteSeat != null)
                _row('Μπελότ-Ρεμπελότ',
                    result.declarations.beloteSeat!.team == ourTeam ? '20 – 0' : '0 – 20'),
              _row('Σύνολο',
                  '${result.rawTotals[ourTeam]} – ${result.rawTotals[ourTeam.opponent]}'),
              const Divider(height: 24),
              _row(
                'Βαθμολογία γύρου',
                '${ourTeam == Team.northSouth ? result.rounded.northSouth : result.rounded.eastWest}'
                ' – '
                '${ourTeam == Team.northSouth ? result.rounded.eastWest : result.rounded.northSouth}',
                bold: true,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.continueAfterHand,
                child: const Text('Επόμενη μοιρασιά'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

class _MatchOverOverlay extends StatelessWidget {
  final LocalGameController controller;
  const _MatchOverOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final winner = controller.scoreboard.winner;
    final weWon = winner == controller.humanSeat.team;

    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(weWon ? 'Κερδίσατε!' : 'Χάσατε',
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '${controller.scoreboard.totals[controller.humanSeat.team]}'
            ' – '
            '${controller.scoreboard.totals[controller.humanSeat.team.opponent]}',
            style: const TextStyle(color: Colors.white70, fontSize: 20),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Πίσω στο μενού'),
          ),
        ],
      ),
    );
  }
}
