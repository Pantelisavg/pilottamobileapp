import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:provider/provider.dart';

import '../controllers/online_game_controller.dart';
import '../controllers/room_client_controller.dart';
import '../settings/app_settings.dart';
import '../settings/sound.dart';
import '../widgets/bidding_panel.dart';
import '../widgets/chat_flash_banner.dart';
import '../widgets/chat_panel.dart';
import '../widgets/table/declaration_panel.dart';
import '../widgets/table/hand_summary_overlay.dart';
import '../widgets/table/human_hand_panel.dart';
import '../widgets/table/match_over_overlay.dart';
import '../widgets/table/opponent_seat.dart';
import '../widgets/table/oval_table_area.dart';
import '../widgets/table/score_header.dart';
import '../widgets/turn_timer_ring.dart';

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
        title: ScoreHeader(
          controller: controller,
          extraTargetSubtitle: 'Δωμάτιο ${snapshot.roomCode}',
        ),
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
                Expanded(
                  child: OvalTableArea(
                    controller: controller,
                    opponentSeatBuilder: (seat) {
                      final info = snapshot.seats[seat]!;
                      final isActive = controller.seatToAct == seat;
                      return OpponentSeat(
                        controller: controller,
                        seat: seat,
                        disconnected: !info.isBot && !info.connected,
                        // A purely cosmetic pace cue — nothing auto-plays if
                        // it runs out, there is no server-side turn timeout.
                        timerOverlay: isActive && !info.isBot && info.connected
                            ? TurnTimerRing(
                                key: ValueKey(
                                    '${snapshot.phase.name}|${snapshot.seatToAct?.name}'),
                                active: true,
                                size: 66,
                              )
                            : null,
                      );
                    },
                  ),
                ),
                if (controller.canAnnounceDeclaration ||
                    controller.canRevealDeclaration)
                  DeclarationPanel(controller: controller),
                // The hand stays visible above the bidding panel — you
                // need to see your cards while you decide what to call.
                HumanHandPanel(
                    controller: controller, errorText: controller.lastError),
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
              HandSummaryOverlay(controller: controller),
            if (snapshot.phase == RoomPhase.matchOver)
              MatchOverOverlay(controller: controller),
            if (controller.status == ConnectionStatus.disconnected)
              _DisconnectOverlay(controller: controller),
            ChatFlashBanner(chatLog: controller.chatLog, viewerSeat: me),
          ],
        ),
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
