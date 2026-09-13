import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:provider/provider.dart';

import '../controllers/local_game_controller.dart';
import '../settings/app_settings.dart';
import '../settings/sound.dart';
import '../widgets/auction_call_label.dart';
import '../widgets/bidding_panel.dart';
import '../widgets/chat_flash_banner.dart';
import '../widgets/chat_panel.dart';
import '../widgets/declaration_label.dart';
import '../widgets/hand_sort.dart';
import '../widgets/illegal_reason.dart';
import '../widgets/fanned_hand.dart';
import '../widgets/last_trick_dialog.dart';
import '../widgets/player_avatar.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/scoreboard_sheet.dart';
import '../widgets/seat_layout.dart';
import '../widgets/suit_icon.dart';

List<ScoreRow> _buildLocalScoreRows(List<HandResult> history, Seat viewerSeat) {
  final ourTeam = viewerSeat.team;
  return [
    for (var i = 0; i < history.length; i++)
      ScoreRow(
        index: i + 1,
        trumpSuit: history[i].contract.trumpSuit,
        isCapot: history[i].contract.isCapot,
        biddingValue: history[i].contract.value,
        biddingSeatLabel:
            seatLabelRelativeTo(history[i].contract.biddingSeat, viewerSeat),
        contractMade: history[i].contractMade,
        roundedMine: ourTeam == Team.northSouth
            ? history[i].rounded.northSouth
            : history[i].rounded.eastWest,
        roundedTheirs: ourTeam == Team.northSouth
            ? history[i].rounded.eastWest
            : history[i].rounded.northSouth,
      ),
  ];
}

class LocalGameScreen extends StatelessWidget {
  final int targetScore;
  const LocalGameScreen({super.key, required this.targetScore});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LocalGameController(
        targetScore: targetScore,
        playerName: context.read<AppSettings>().playerName,
        mustOvertrumpAllSuits:
            context.read<AppSettings>().mustOvertrumpAllSuits,
      ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Συνομιλία',
            onPressed: () => showChatPanel(
              context,
              listenable: controller,
              chatLogOf: () => controller.chatLog,
              viewerSeat: controller.humanSeat,
              onSend: controller.sendChat,
            ),
          ),
        ],
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(controller.banner!,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                Expanded(child: _TableArea(controller: controller)),
                if (controller.canAnnounceDeclaration ||
                    controller.canRevealDeclaration)
                  _DeclarationPanel(controller: controller),
                // The hand stays visible above the bidding panel — you
                // need to see your cards while you decide what to call.
                _HumanHand(controller: controller),
                if (controller.isHumanTurnToBid)
                  BiddingPanel(
                    auction: controller.auction!,
                    seat: controller.humanSeat,
                    onCall: (call) {
                      playTapSound(context.read<AppSettings>());
                      controller.submitBid(call);
                    },
                  ),
              ],
            ),
            if (controller.phase == RoomPhase.handSummary)
              _HandSummaryOverlay(controller: controller),
            if (controller.phase == RoomPhase.matchOver)
              _MatchOverOverlay(controller: controller),
            ChatFlashBanner(
                chatLog: controller.chatLog, viewerSeat: controller.humanSeat),
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
        InkWell(
          onTap: () => showScoreboardSheet(
            context,
            rows: _buildLocalScoreRows(board.history, controller.humanSeat),
            totalMine: board.totals[ourTeam]!,
            totalTheirs: board.totals[ourTeam.opponent]!,
            targetScore: board.targetScore,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Εμείς ${board.totals[ourTeam]}  –  Αυτοί ${board.totals[ourTeam.opponent]}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Icon(Icons.receipt_long,
                      color: Colors.white54, size: 16),
                ],
              ),
              Text('Στόχος: ${board.targetScore}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
        if (contract != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${contract.isCapot ? 'Καπότο' : contract.value}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              SuitIcon(contract.trumpSuit,
                  size: 22,
                  color: contract.trumpSuit.isRed
                      ? Colors.red.shade300
                      : Colors.white),
              if (contract.multiplier != ContractMultiplier.none)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text('x${contract.multiplier.factor}',
                      style: const TextStyle(
                          fontSize: 14, color: Colors.orangeAccent)),
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
        if (controller.phase == RoomPhase.playing &&
            (controller.hand?.completedTricks.isNotEmpty ?? false))
          Positioned(
            top: 0,
            left: 0,
            child: IconButton(
              tooltip: 'Προηγούμενη μπάζα',
              icon: const Icon(Icons.history, color: Colors.white70),
              onPressed: () {
                final trick = controller.hand!.completedTricks.last;
                showLastTrickDialog(
                  context,
                  played: trick.played,
                  winner: trick.winner,
                  viewerSeat: controller.humanSeat,
                );
              },
            ),
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
        : (controller.hand != null &&
            !controller.hand!.currentTrick.isComplete &&
            controller.hand!.currentTrick.seatToPlay == seat);
    final cardCount = controller.handOf(seat).length;
    final isPartner = seat == controller.humanSeat.partner;
    final declState = controller.hand?.declarationStateOf(seat);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerAvatar(
            label: seatLabelRelativeTo(seat, controller.humanSeat),
            cardCount: cardCount,
            isActive: isActive,
            isPartner: isPartner,
            isBot: controller.isBotControlled(seat),
          ),
          if (declState == DeclarationAnnounceState.announced)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text('Δήλωσε — αναμένεται αποκάλυψη',
                  style: TextStyle(color: Colors.amberAccent, fontSize: 9)),
            )
          else if (declState == DeclarationAnnounceState.revealed)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                  declarationsPointsLabel(
                      controller.hand!.allDeclarationsOf(seat)),
                  style: const TextStyle(
                      color: Colors.lightGreenAccent, fontSize: 9)),
            ),
          const SizedBox(height: 4),
          SizedBox(
            height: 46,
            width: 92,
            child: Stack(
              children: [
                for (var i = 0; i < cardCount; i++)
                  Positioned(
                    left: i * 9.0,
                    child: const PlayingCardWidget(faceUp: false, width: 30),
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
    final cardScale = context.watch<AppSettings>().cardScale;

    return SizedBox(
      width: 260,
      height: 240,
      child: Stack(
        children: [
          for (final seat in Seat.values)
            if (played[seat] != null)
              Align(
                alignment: seatAlignmentRelativeTo(seat, controller.humanSeat),
                child: PlayingCardWidget(
                    card: played[seat], width: 68 * cardScale),
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
      // SingleChildScrollView clamps to whatever height the Align/Stack
      // above actually has available and scrolls instead of overflowing —
      // on a short screen with the bidding panel also showing, this panel
      // (bid status + history) can be taller than the space left for it.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Δηλώσεις',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            if (bid == null)
              const Text('Καμία δήλωση ακόμα',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold))
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${bid.isCapot ? 'Καπότο' : bid.value} ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  SuitIcon(bid.suit, size: 18, color: Colors.white),
                  Text(
                      ' — ${seatLabelRelativeTo(bid.seat, controller.humanSeat)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            const SizedBox(height: 6),
            Text(
                'Σειρά: ${seatLabelRelativeTo(auction.seatToAct, controller.humanSeat)}',
                style:
                    const TextStyle(color: Colors.amberAccent, fontSize: 12)),
            if (auction.calls.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: Colors.white24),
              const SizedBox(height: 6),
              // Capped to the most recent few calls — a plain, unscrolled
              // list so its height is always small and bounded, whatever
              // Align/Stack above happens to have room for.
              for (final call
                  in auction.calls.reversed.take(5).toList().reversed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: auctionCallLabel(call,
                        seatLabelRelativeTo(call.seat, controller.humanSeat)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeclarationPanel extends StatelessWidget {
  final LocalGameController controller;
  const _DeclarationPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final declaration = controller.myBestDeclaration;
    if (declaration == null) return const SizedBox.shrink();

    final canAnnounce = controller.canAnnounceDeclaration;
    return Container(
      width: double.infinity,
      color: Colors.indigo.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              canAnnounce
                  ? 'Έχεις ${declaration.pointValue()} — δήλωσέ το τώρα!'
                  : 'Αποκάλυψε τη δήλωσή σου πριν παίξεις, αλλιώς χάνεται!',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            // Overrides the theme's full-width (Size.fromHeight) minimumSize,
            // which forces an infinite width crash for a button placed next
            // to something else in a Row instead of alone in a Column.
            style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: canAnnounce
                ? controller.announceDeclaration
                : controller.revealDeclaration,
            child: Text(canAnnounce ? 'Δήλωσε' : 'Αποκάλυψε'),
          ),
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
    final trick = controller.hand?.currentTrick;
    final settings = context.watch<AppSettings>();
    final cardScale = settings.cardScale;

    final sorted = sortedForHand(cards, ascending: settings.handAscending);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: const Color(0xFF082A20),
      child: FannedHand(
        cards: sorted,
        legal: legal,
        isMyTurn: isMyTurn,
        cardScale: cardScale,
        reasonFor: (card) =>
            trick != null ? illegalPlayReason(trick, cards, card) : null,
        onTap: (card) {
          playTapSound(context.read<AppSettings>());
          controller.playCard(card);
        },
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
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${contract.isCapot ? 'Καπότο' : contract.value} ',
                      style: const TextStyle(fontSize: 14)),
                  SuitIcon(contract.trumpSuit, size: 16),
                  Text(
                      ' — ${seatLabelRelativeTo(contract.biddingSeat, controller.humanSeat)}',
                      style: const TextStyle(fontSize: 14)),
                ],
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
                _row(
                    'Μπελότ-Ρεμπελότ',
                    result.declarations.beloteSeat!.team == ourTeam
                        ? '20 – 0'
                        : '0 – 20'),
              for (final entry in result.declarations.forfeitedPerSeat.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${seatLabelRelativeTo(entry.key, controller.humanSeat)} ξέχασε να αποκαλύψει: '
                    '${declarationPointsLabel(entry.value)} (χαμένο)',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.redAccent),
                  ),
                ),
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
    final style =
        TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal);
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
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold)),
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
