import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:provider/provider.dart';

import '../controllers/online_game_controller.dart';
import '../widgets/bidding_panel.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/seat_layout.dart';

class OnlineGameScreen extends StatelessWidget {
  const OnlineGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnlineGameController>();

    if (!controller.inRoom) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B3D2E),
        body: Center(
          child: controller.lastError != null
              ? _ConnectingError(message: controller.lastError!)
              : const CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    final snapshot = controller.snapshot!;
    if (snapshot.phase == RoomPhase.lobby) {
      return _LobbyWaitingRoom(controller: controller);
    }

    return _OnlineTable(controller: controller);
  }
}

class _ConnectingError extends StatelessWidget {
  final String message;
  const _ConnectingError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, color: Colors.white54, size: 48),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Πίσω'),
          ),
        ],
      ),
    );
  }
}

class _LobbyWaitingRoom extends StatelessWidget {
  final OnlineGameController controller;
  const _LobbyWaitingRoom({required this.controller});

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot!;
    return Scaffold(
      backgroundColor: const Color(0xFF0B3D2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF082A20),
        foregroundColor: Colors.white,
        title: const Text('Αίθουσα αναμονής'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('Κωδικός δωματίου', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              SelectableText(
                snapshot.roomCode,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Μοιράσου τον κωδικό με φίλους για να μπουν στο δωμάτιο.',
                  style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              for (final seat in Seat.values) _SeatRow(seat: seat, info: snapshot.seats[seat]!),
              const Spacer(),
              if (controller.isHost)
                FilledButton.icon(
                  onPressed: controller.start,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Έναρξη (γέμισμα κενών θέσεων με bot)'),
                )
              else
                const Text('Περιμένουμε τον οικοδεσπότη να ξεκινήσει...',
                    style: TextStyle(color: Colors.white54)),
              if (controller.lastError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(controller.lastError!, style: const TextStyle(color: Colors.redAccent)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeatRow extends StatelessWidget {
  final Seat seat;
  final SeatInfo info;
  const _SeatRow({required this.seat, required this.info});

  @override
  Widget build(BuildContext context) {
    final label = info.isBot
        ? 'Bot'
        : info.playerName == null
            ? 'Κενή θέση'
            : '${info.playerName}${info.connected ? '' : ' (αποσυνδέθηκε)'}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            info.isBot
                ? Icons.smart_toy_outlined
                : info.playerName == null
                    ? Icons.person_outline
                    : Icons.person,
            color: info.connected || info.playerName == null ? Colors.white70 : Colors.orangeAccent,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

class _OnlineTable extends StatelessWidget {
  final OnlineGameController controller;
  const _OnlineTable({required this.controller});

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot!;
    final me = controller.mySeat!;

    return Scaffold(
      backgroundColor: const Color(0xFF0B3D2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF082A20),
        foregroundColor: Colors.white,
        title: _OnlineScoreHeader(controller: controller),
        titleSpacing: 12,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (snapshot.banner != null)
                  Container(
                    width: double.infinity,
                    color: Colors.amber.shade800,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(snapshot.banner!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                Expanded(child: _OnlineTableArea(controller: controller)),
                _OnlineHumanHand(controller: controller),
              ],
            ),
            if (controller.isMyTurnToBid)
              Align(
                alignment: Alignment.bottomCenter,
                child: BiddingPanel(
                  auction: controller.auction!,
                  seat: me,
                  onCall: controller.submitBid,
                ),
              ),
            if (snapshot.phase == RoomPhase.handSummary)
              _OnlineHandSummaryOverlay(controller: controller),
            if (snapshot.phase == RoomPhase.matchOver)
              _OnlineMatchOverOverlay(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _OnlineScoreHeader extends StatelessWidget {
  final OnlineGameController controller;
  const _OnlineScoreHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot!;
    final myTeamKey = controller.mySeat!.team == Team.northSouth ? 'northSouth' : 'eastWest';
    final theirTeamKey = myTeamKey == 'northSouth' ? 'eastWest' : 'northSouth';
    final contract = snapshot.contract;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Εμείς ${snapshot.totals[myTeamKey]}  –  Αυτοί ${snapshot.totals[theirTeamKey]}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('Στόχος: ${snapshot.targetScore} · Δωμάτιο ${snapshot.roomCode}',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        if (contract != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                contract['isCapot'] == true ? 'Καπότο' : '${contract['value']}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                suitSymbol(Suit.values.byName(contract['trumpSuit'] as String)),
                style: const TextStyle(fontSize: 22),
              ),
            ],
          ),
      ],
    );
  }
}

class _OnlineTableArea extends StatelessWidget {
  final OnlineGameController controller;
  const _OnlineTableArea({required this.controller});

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot!;
    final me = controller.mySeat!;

    return Stack(
      children: [
        for (final seat in Seat.values)
          if (seat != me)
            Align(
              alignment: seatAlignmentRelativeTo(seat, me),
              child: _OnlineOpponentSeat(controller: controller, seat: seat),
            ),
        Center(child: _OnlineTrickArea(controller: controller)),
        if (snapshot.phase == RoomPhase.bidding)
          const Align(alignment: Alignment.center, child: _OnlineAuctionStatus()),
      ],
    );
  }
}

class _OnlineOpponentSeat extends StatelessWidget {
  final OnlineGameController controller;
  final Seat seat;
  const _OnlineOpponentSeat({required this.controller, required this.seat});

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot!;
    final isActive = snapshot.seatToAct == seat;
    final cardCount = snapshot.handSizes[seat] ?? 0;
    final isPartner = seat == controller.mySeat!.partner;
    final info = snapshot.seats[seat]!;

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
              '${seatLabelRelativeTo(seat, controller.mySeat!)}'
              '${info.isBot ? " 🤖" : info.connected ? "" : " ⚠"}'
              ' · $cardCount',
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

class _OnlineTrickArea extends StatelessWidget {
  final OnlineGameController controller;
  const _OnlineTrickArea({required this.controller});

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot!;
    final trick = snapshot.currentTrick;
    if (trick == null) return const SizedBox.shrink();

    return SizedBox(
      width: 220,
      height: 200,
      child: Stack(
        children: [
          for (final entry in trick)
            Align(
              alignment: seatAlignmentRelativeTo(
                  Seat.values.byName(entry['seat'] as String), controller.mySeat!),
              child: PlayingCardWidget(
                card: cardFromJson(entry['card'] as Map<String, dynamic>),
                width: 52,
              ),
            ),
        ],
      ),
    );
  }
}

class _OnlineAuctionStatus extends StatelessWidget {
  const _OnlineAuctionStatus();

  @override
  Widget build(BuildContext context) {
    return Consumer<OnlineGameController>(
      builder: (context, controller, _) {
        final auction = controller.auction;
        if (auction == null) return const SizedBox.shrink();
        final bid = auction.currentBid;
        final me = controller.mySeat!;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Δηλώσεις', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              Text(
                bid == null
                    ? 'Καμία δήλωση ακόμα'
                    : '${bid.isCapot ? 'Καπότο' : bid.value} ${suitSymbol(bid.suit)} — ${seatLabelRelativeTo(bid.seat, me)}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text('Σειρά: ${seatLabelRelativeTo(auction.seatToAct, me)}',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}

class _OnlineHumanHand extends StatelessWidget {
  final OnlineGameController controller;
  const _OnlineHumanHand({required this.controller});

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot!;
    final cards = snapshot.yourHand;
    final isMyTurn = controller.isMyTurnToPlay;
    // The server rejects illegal plays, but we don't have local rules
    // knowledge of exactly which cards are legal without the hidden hands
    // of other players — so every card is tappable on your turn, and any
    // rejection comes back as a (rare) error banner instead.
    final sorted = [...cards]..sort((a, b) {
        final suitDiff = a.suit.index.compareTo(b.suit.index);
        if (suitDiff != 0) return suitDiff;
        return plainOrderHighToLow.indexOf(a.rank).compareTo(plainOrderHighToLow.indexOf(b.rank));
      });

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: const Color(0xFF082A20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (controller.lastError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(controller.lastError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final card in sorted)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: PlayingCardWidget(
                      card: card,
                      selectable: isMyTurn,
                      onTap: () => controller.playCard(card),
                      width: 48,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineHandSummaryOverlay extends StatelessWidget {
  final OnlineGameController controller;
  const _OnlineHandSummaryOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final result = controller.snapshot!.lastHandResult!;
    final myTeamKey = controller.mySeat!.team == Team.northSouth ? 'northSouth' : 'eastWest';
    final theirTeamKey = myTeamKey == 'northSouth' ? 'eastWest' : 'northSouth';
    final contract = result['contract'] as Map<String, dynamic>;
    final trickPoints = (result['trickPoints'] as Map<String, dynamic>);
    final rawTotals = (result['rawTotals'] as Map<String, dynamic>);
    final rounded = (result['rounded'] as Map<String, dynamic>);
    final declarations = result['declarations'] as Map<String, dynamic>;
    final contractMade = result['contractMade'] as bool;
    final iAmReady = controller.snapshot!.readyForNextHand.contains(controller.mySeat);

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
                contractMade ? 'Το συμβόλαιο βγήκε' : 'Μέσα!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${contract['isCapot'] == true ? 'Καπότο' : contract['value']} '
                '${suitSymbol(Suit.values.byName(contract['trumpSuit'] as String))}',
                style: const TextStyle(fontSize: 14),
              ),
              const Divider(height: 24),
              _row('Πόντοι φύλλων', '${trickPoints[myTeamKey]} – ${trickPoints[theirTeamKey]}'),
              if (declarations['winningTeam'] != null)
                _row(
                  'Δηλώσεις',
                  declarations['winningTeam'] == myTeamKey
                      ? '${declarations['winningTeamPoints']} – 0'
                      : '0 – ${declarations['winningTeamPoints']}',
                ),
              _row('Σύνολο', '${rawTotals[myTeamKey]} – ${rawTotals[theirTeamKey]}'),
              const Divider(height: 24),
              _row(
                'Βαθμολογία γύρου',
                '${rounded[myTeamKey == 'northSouth' ? 'northSouth' : 'eastWest']}'
                ' – '
                '${rounded[theirTeamKey == 'northSouth' ? 'northSouth' : 'eastWest']}',
                bold: true,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: iAmReady ? null : controller.continueAfterHand,
                child: Text(iAmReady ? 'Περιμένουμε τους άλλους...' : 'Επόμενη μοιρασιά'),
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

class _OnlineMatchOverOverlay extends StatelessWidget {
  final OnlineGameController controller;
  const _OnlineMatchOverOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot!;
    final myTeamKey = controller.mySeat!.team == Team.northSouth ? 'northSouth' : 'eastWest';
    final theirTeamKey = myTeamKey == 'northSouth' ? 'eastWest' : 'northSouth';
    final weWon = snapshot.winnerTeam == myTeamKey;

    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(weWon ? 'Κερδίσατε!' : 'Χάσατε',
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${snapshot.totals[myTeamKey]} – ${snapshot.totals[theirTeamKey]}',
              style: const TextStyle(color: Colors.white70, fontSize: 20)),
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
