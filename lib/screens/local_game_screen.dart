import 'package:flutter/material.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:provider/provider.dart';

import '../controllers/local_game_controller.dart';
import '../settings/app_settings.dart';
import '../settings/sound.dart';
import '../widgets/bidding_panel.dart';
import '../widgets/chat_flash_banner.dart';
import '../widgets/chat_panel.dart';
import '../widgets/table/cheat_sheet_button.dart';
import '../widgets/table/declaration_panel.dart';
import '../widgets/table/hand_summary_overlay.dart';
import '../widgets/table/human_hand_panel.dart';
import '../widgets/table/leave_table_button.dart';
import '../widgets/table/leave_table_scope.dart';
import '../widgets/table/match_over_overlay.dart';
import '../widgets/table/oval_table_area.dart';
import '../widgets/table/score_header.dart';

class LocalGameScreen extends StatelessWidget {
  /// Set for a fresh match; null when [resumeFrom] is used instead.
  final int? targetScore;

  /// Set to continue a previously-saved match (see [LocalGameSave]);
  /// null for a fresh one.
  final Map<String, dynamic>? resumeFrom;

  const LocalGameScreen({super.key, required int this.targetScore})
      : resumeFrom = null;

  const LocalGameScreen.resume(
      {super.key, required Map<String, dynamic> this.resumeFrom})
      : targetScore = null;

  @override
  Widget build(BuildContext context) {
    final resumeFrom = this.resumeFrom;
    return ChangeNotifierProvider(
      create: (context) => resumeFrom != null
          ? LocalGameController.resumed(resumeFrom)
          : LocalGameController(
              targetScore: targetScore!,
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

    return LeaveTableScope(
      child: Scaffold(
        backgroundColor: const Color(0xFF0B3D2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF082A20),
          foregroundColor: Colors.white,
          title: ScoreHeader(controller: controller),
          titleSpacing: 12,
          actions: [
            const CheatSheetButton(),
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
            const LeaveTableButton(),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Text(controller.banner!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                  Expanded(child: OvalTableArea(controller: controller)),
                  if (controller.canAnnounceDeclaration ||
                      controller.canRevealDeclaration)
                    DeclarationPanel(controller: controller),
                  // The hand stays visible above the bidding panel — you
                  // need to see your cards while you decide what to call.
                  HumanHandPanel(controller: controller),
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
                HandSummaryOverlay(controller: controller),
              if (controller.phase == RoomPhase.matchOver)
                MatchOverOverlay(controller: controller),
              ChatFlashBanner(
                  chatLog: controller.chatLog,
                  viewerSeat: controller.humanSeat),
            ],
          ),
        ),
      ),
    );
  }
}
