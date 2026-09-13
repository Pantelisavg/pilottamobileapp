import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:provider/provider.dart';

import '../controllers/online_game_controller.dart';
import '../controllers/room_client_controller.dart';
import '../settings/app_settings.dart';
import '../settings/sound.dart';
import '../widgets/auction_call_label.dart';
import '../widgets/bidding_panel.dart';
import '../widgets/chat_flash_banner.dart';
import '../widgets/chat_panel.dart';
import '../widgets/declaration_label.dart';
import '../widgets/fanned_hand.dart';
import '../widgets/hand_sort.dart';
import '../widgets/illegal_reason.dart';
import '../widgets/last_trick_dialog.dart';
import '../widgets/player_avatar.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/scoreboard_sheet.dart';
import '../widgets/seat_layout.dart';
import '../widgets/suit_icon.dart';
import '../widgets/turn_timer_ring.dart';

List<ScoreRow> _buildOnlineScoreRows(
    List<Map<String, dynamic>> history, Seat viewerSeat) {
  final myTeamKey =
      viewerSeat.team == Team.northSouth ? 'northSouth' : 'eastWest';
  final theirTeamKey = myTeamKey == 'northSouth' ? 'eastWest' : 'northSouth';
  return [
    for (var i = 0; i < history.length; i++)
      () {
        final entry = history[i];
        final contract = entry['contract'] as Map<String, dynamic>;
        final rounded = entry['rounded'] as Map<String, dynamic>;
        return ScoreRow(
          index: i + 1,
          trumpSuit: Suit.values.byName(contract['trumpSuit'] as String),
          isCapot: contract['isCapot'] as bool,
          biddingValue: contract['value'] as int,
          biddingSeatLabel: seatLabelRelativeTo(
              Seat.values.byName(contract['biddingSeat'] as String),
              viewerSeat),
          contractMade: entry['contractMade'] as bool,
          roundedMine: rounded[myTeamKey] as int,
          roundedTheirs: rounded[theirTeamKey] as int,
        );
      }(),
  ];
}

class NetworkedGameScreen extends StatelessWidget {
  const NetworkedGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RoomClientController>();

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
          Text(message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center),
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
  final RoomClientController controller;
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
              const Text('Κωδικός δωματίου',
                  style: TextStyle(color: Colors.white70)),
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
              const Text(
                  'Μοιράσου τον κωδικό με φίλους για να μπουν στο δωμάτιο.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              for (final seat in Seat.values)
                _SeatRow(seat: seat, info: snapshot.seats[seat]!),
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
                  child: Text(controller.lastError!,
                      style: const TextStyle(color: Colors.redAccent)),
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
            color: info.connected || info.playerName == null
                ? Colors.white70
                : Colors.orangeAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

class _OnlineTable extends StatelessWidget {
  final RoomClientController controller;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Συνομιλία',
            onPressed: () => showChatPanel(
              context,
              listenable: controller,
              chatLogOf: () => controller.chatLog,
              viewerSeat: me,
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
                if (snapshot.banner != null)
                  Container(
                    width: double.infinity,
                    color: Colors.amber.shade800,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(snapshot.banner!,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                Expanded(child: _OnlineTableArea(controller: controller)),
                if (snapshot.canAnnounceDeclaration ||
                    snapshot.canRevealDeclaration)
                  _OnlineDeclarationPanel(controller: controller),
                // The hand stays visible above the bidding panel — you
                // need to see your cards while you decide what to call.
                _OnlineHumanHand(controller: controller),
                if (controller.isMyTurnToBid)
                  BiddingPanel(
                    auction: controller.auction!,
                    seat: me,
                    onCall: (call) {
                      playTapSound(context.read<AppSettings>());
                      controller.submitBid(call);
                    },
                  ),
              ],
            ),
            if (snapshot.phase == RoomPhase.handSummary)
              _OnlineHandSummaryOverlay(controller: controller),
            if (snapshot.phase == RoomPhase.matchOver)
              _OnlineMatchOverOverlay(controller: controller),
            if (controller.status == ConnectionStatus.disconnected)
              _DisconnectOverlay(controller: controller),
            ChatFlashBanner(chatLog: controller.chatLog, viewerSeat: me),
          ],
        ),
      ),
    );
  }
}

class _OnlineScoreHeader extends StatelessWidget {
  final RoomClientController controller;
  const _OnlineScoreHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot!;
    final myTeamKey =
        controller.mySeat!.team == Team.northSouth ? 'northSouth' : 'eastWest';
    final theirTeamKey = myTeamKey == 'northSouth' ? 'eastWest' : 'northSouth';
    final contract = snapshot.contract;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => showScoreboardSheet(
            context,
            rows: _buildOnlineScoreRows(
                snapshot.matchHistory, controller.mySeat!),
            totalMine: snapshot.totals[myTeamKey]!,
            totalTheirs: snapshot.totals[theirTeamKey]!,
            targetScore: snapshot.targetScore,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Εμείς ${snapshot.totals[myTeamKey]}  –  Αυτοί ${snapshot.totals[theirTeamKey]}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.receipt_long,
                      color: Colors.white54, size: 16),
                ],
              ),
              Text(
                  'Στόχος: ${snapshot.targetScore} · Δωμάτιο ${snapshot.roomCode}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
        if (contract != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                contract['isCapot'] == true ? 'Καπότο' : '${contract['value']}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              SuitIcon(Suit.values.byName(contract['trumpSuit'] as String),
                  size: 22, color: Colors.white),
            ],
          ),
      ],
    );
  }
}

class _OnlineTableArea extends StatelessWidget {
  final RoomClientController controller;
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
          const Align(
              alignment: Alignment.center, child: _OnlineAuctionStatus()),
        if (snapshot.phase == RoomPhase.playing &&
            snapshot.lastCompletedTrick != null)
          Positioned(
            top: 0,
            left: 0,
            child: IconButton(
              tooltip: 'Προηγούμενη μπάζα',
              icon: const Icon(Icons.history, color: Colors.white70),
              onPressed: () {
                final played = snapshot.lastCompletedTrick!
                    .map((e) => (
                          seat: Seat.values.byName(e['seat'] as String),
                          card: cardFromJson(e['card'] as Map<String, dynamic>),
                        ))
                    .toList();
                showLastTrickDialog(
                  context,
                  played: played,
                  winner: snapshot.lastCompletedTrickWinner,
                  viewerSeat: me,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _OnlineOpponentSeat extends StatelessWidget {
  final RoomClientController controller;
  final Seat seat;
  const _OnlineOpponentSeat({required this.controller, required this.seat});

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot!;
    final isActive = snapshot.seatToAct == seat;
    final cardCount = snapshot.handSizes[seat] ?? 0;
    final isPartner = seat == controller.mySeat!.partner;
    final info = snapshot.seats[seat]!;
    final declState = snapshot.declarationStates[seat];

    return Padding(
      padding: const EdgeInsets.all(8),
      // The table area's height isn't divided into a fixed slot per seat —
      // an opponent's avatar+cards column can outgrow whatever's actually
      // left over once the bidding panel (or other overlays) claim their
      // share, especially on a small screen. Shrink to fit rather than
      // overflow, instead of trying to fix its natural size.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerAvatar(
              label: seatLabelRelativeTo(seat, controller.mySeat!),
              cardCount: cardCount,
              isActive: isActive,
              isPartner: isPartner,
              isBot: info.isBot,
              disconnected: !info.isBot && !info.connected,
              // A purely cosmetic pace cue — nothing auto-plays if it runs
              // out, there is no server-side turn timeout.
              timerOverlay: isActive && !info.isBot && info.connected
                  ? TurnTimerRing(
                      key: ValueKey(
                          '${snapshot.phase.name}|${snapshot.seatToAct?.name}'),
                      active: true,
                      size: 66,
                    )
                  : null,
            ),
            if (declState == DeclarationAnnounceState.announced.name)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text('Δήλωσε — αναμένεται αποκάλυψη',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 9)),
              )
            else if (declState == DeclarationAnnounceState.revealed.name)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                    declarationsLabelFromJsonList(
                        snapshot.revealedDeclarations[seat]!),
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
      ),
    );
  }
}

class _OnlineTrickArea extends StatelessWidget {
  final RoomClientController controller;
  const _OnlineTrickArea({required this.controller});

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot!;
    final trick = snapshot.currentTrick;
    if (trick == null) return const SizedBox.shrink();

    final cardScale = context.watch<AppSettings>().cardScale;
    return SizedBox(
      width: 260,
      height: 240,
      child: Stack(
        children: [
          for (final entry in trick)
            Align(
              alignment: seatAlignmentRelativeTo(
                  Seat.values.byName(entry['seat'] as String),
                  controller.mySeat!),
              child: PlayingCardWidget(
                card: cardFromJson(entry['card'] as Map<String, dynamic>),
                width: 68 * cardScale,
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
    return Consumer<RoomClientController>(
      builder: (context, controller, _) {
        final auction = controller.auction;
        if (auction == null) return const SizedBox.shrink();
        final bid = auction.currentBid;
        final me = controller.mySeat!;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(16)),
          // SingleChildScrollView clamps to whatever height the Align/Stack
          // above actually has available and scrolls instead of
          // overflowing on a short screen.
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
                      Text(' — ${seatLabelRelativeTo(bid.seat, me)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                const SizedBox(height: 6),
                Text('Σειρά: ${seatLabelRelativeTo(auction.seatToAct, me)}',
                    style: const TextStyle(
                        color: Colors.amberAccent, fontSize: 12)),
                if (auction.calls.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Colors.white24),
                  const SizedBox(height: 6),
                  // Capped to the most recent few calls — a plain,
                  // unscrolled list so its height is always small and
                  // bounded, whatever Align/Stack above has room for.
                  for (final call
                      in auction.calls.reversed.take(5).toList().reversed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: auctionCallLabel(
                            call, seatLabelRelativeTo(call.seat, me)),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnlineDeclarationPanel extends StatelessWidget {
  final RoomClientController controller;
  const _OnlineDeclarationPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot!;
    final declaration = snapshot.yourBestDeclaration;
    if (declaration == null) return const SizedBox.shrink();

    final canAnnounce = snapshot.canAnnounceDeclaration;
    return Container(
      width: double.infinity,
      color: Colors.indigo.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              canAnnounce
                  ? 'Έχεις ${declarationLabelFromJson(declaration)} (${declaration['pointValue']} π.) — δήλωσέ το τώρα!'
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

class _OnlineHumanHand extends StatelessWidget {
  final RoomClientController controller;
  const _OnlineHumanHand({required this.controller});

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot!;
    final cards = snapshot.yourHand;
    final isMyTurn = controller.isMyTurnToPlay;
    // Legality is computed client-side from the trick's public state (see
    // RoomClientController.legalPlaysForMe) — it never depends on other
    // players' hidden cards, so this exactly matches what the server will
    // accept. The server still validates independently; any rejection
    // (should be rare) comes back as an error banner.
    final legal = controller.legalPlaysForMe.toSet();
    final trick = controller.currentTrick;
    final cardScale = context.watch<AppSettings>().cardScale;
    final sorted = sortedForHand(cards);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: const Color(0xFF082A20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (controller.lastError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(controller.lastError!,
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          FannedHand(
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
        ],
      ),
    );
  }
}

class _OnlineHandSummaryOverlay extends StatelessWidget {
  final RoomClientController controller;
  const _OnlineHandSummaryOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final result = controller.snapshot!.lastHandResult!;
    final myTeamKey =
        controller.mySeat!.team == Team.northSouth ? 'northSouth' : 'eastWest';
    final theirTeamKey = myTeamKey == 'northSouth' ? 'eastWest' : 'northSouth';
    final contract = result['contract'] as Map<String, dynamic>;
    final trickPoints = (result['trickPoints'] as Map<String, dynamic>);
    final rawTotals = (result['rawTotals'] as Map<String, dynamic>);
    final rounded = (result['rounded'] as Map<String, dynamic>);
    final declarations = result['declarations'] as Map<String, dynamic>;
    final contractMade = result['contractMade'] as bool;
    final iAmReady =
        controller.snapshot!.readyForNextHand.contains(controller.mySeat);

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
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      '${contract['isCapot'] == true ? 'Καπότο' : contract['value']} ',
                      style: const TextStyle(fontSize: 14)),
                  SuitIcon(Suit.values.byName(contract['trumpSuit'] as String),
                      size: 16),
                ],
              ),
              const Divider(height: 24),
              _row('Πόντοι φύλλων',
                  '${trickPoints[myTeamKey]} – ${trickPoints[theirTeamKey]}'),
              if (declarations['winningTeam'] != null)
                _row(
                  'Δηλώσεις',
                  declarations['winningTeam'] == myTeamKey
                      ? '${declarations['winningTeamPoints']} – 0'
                      : '0 – ${declarations['winningTeamPoints']}',
                ),
              for (final entry
                  in (declarations['forfeitedPerSeat'] as Map<String, dynamic>)
                      .entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${seatLabelRelativeTo(Seat.values.byName(entry.key), controller.mySeat!)} '
                    'ξέχασε να αποκαλύψει: '
                    '${declarationLabelFromJson(entry.value as Map<String, dynamic>)} (χαμένο)',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.redAccent),
                  ),
                ),
              _row('Σύνολο',
                  '${rawTotals[myTeamKey]} – ${rawTotals[theirTeamKey]}'),
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
                child: Text(iAmReady
                    ? 'Περιμένουμε τους άλλους...'
                    : 'Επόμενη μοιρασιά'),
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

class _OnlineMatchOverOverlay extends StatelessWidget {
  final RoomClientController controller;
  const _OnlineMatchOverOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot!;
    final myTeamKey =
        controller.mySeat!.team == Team.northSouth ? 'northSouth' : 'eastWest';
    final theirTeamKey = myTeamKey == 'northSouth' ? 'eastWest' : 'northSouth';
    final weWon = snapshot.winnerTeam == myTeamKey;

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
              '${snapshot.totals[myTeamKey]} – ${snapshot.totals[theirTeamKey]}',
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

/// Shown when the connection to the server/host drops mid-match. The room
/// itself keeps going (a bot plays this seat until it reconnects — see
/// [PilottaRoom.setConnected]); this overlay offers to open a fresh
/// connection and rejoin with the same name, which reclaims the same seat
/// (see [PilottaRoom.join]), or to just leave.
class _DisconnectOverlay extends StatelessWidget {
  final RoomClientController controller;
  const _DisconnectOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final current = controller;
    final canReconnect = current is OnlineGameController &&
        current.roomCode != null &&
        current.playerName != null;

    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 48),
            const SizedBox(height: 12),
            const Text('Έχασες τη σύνδεση',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Το παιχνίδι συνεχίζει στο δωμάτιο — ένα bot παίζει προσωρινά τη θέση σου.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (canReconnect)
              FilledButton.icon(
                onPressed: () {
                  final fresh =
                      OnlineGameController(serverUri: current.serverUri);
                  fresh.joinRoom(
                      roomCode: current.roomCode!,
                      playerName: current.playerName!);
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) =>
                        ChangeNotifierProvider<RoomClientController>.value(
                      value: fresh,
                      child: const NetworkedGameScreen(),
                    ),
                  ));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Προσπάθεια επανασύνδεσης'),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Πίσω στο μενού'),
            ),
          ],
        ),
      ),
    );
  }
}
