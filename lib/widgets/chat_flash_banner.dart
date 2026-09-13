import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

import '../theme/pilotta_colors.dart';
import 'chat_entry_label.dart';
import 'declaration_cards_row.dart';

/// Briefly flashes the latest declaration/Pilotta event to every player —
/// otherwise a seat announcing or revealing (or calling Pilotta/Repilotta)
/// is only visible in the chat log, easy to miss mid-hand. Plain chat
/// messages don't flash (see [chatEntryIsFlashWorthy]) — only the log.
class ChatFlashBanner extends StatefulWidget {
  final List<ChatEntry> chatLog;
  final Seat viewerSeat;

  const ChatFlashBanner(
      {super.key, required this.chatLog, required this.viewerSeat});

  @override
  State<ChatFlashBanner> createState() => _ChatFlashBannerState();
}

class _ChatFlashBannerState extends State<ChatFlashBanner> {
  int _lastSeenId = -1;
  ChatEntry? _visible;
  Timer? _hideTimer;
  bool _seeded = false;

  @override
  void didUpdateWidget(covariant ChatFlashBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkForNew();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _checkForNew() {
    if (!_seeded) {
      // Don't flash anything that predates this widget's first frame (a
      // rejoin/reconnect shouldn't replay the whole match's history).
      _seeded = true;
      if (widget.chatLog.isNotEmpty) _lastSeenId = widget.chatLog.last.id;
      return;
    }
    for (final entry in widget.chatLog.reversed) {
      if (entry.id <= _lastSeenId) break;
      if (chatEntryIsFlashWorthy(entry)) {
        _lastSeenId = widget.chatLog.last.id;
        _hideTimer?.cancel();
        setState(() => _visible = entry);
        // A reveal has actual cards to look at, not just a one-line call
        // out — give it a little longer on screen.
        final duration = entry.kind == ChatEntryKind.declarationRevealed
            ? const Duration(seconds: 4)
            : const Duration(seconds: 3);
        _hideTimer = Timer(duration, () {
          if (mounted) setState(() => _visible = null);
        });
        return;
      }
    }
    if (widget.chatLog.isNotEmpty) _lastSeenId = widget.chatLog.last.id;
  }

  @override
  Widget build(BuildContext context) {
    // First frame: seed without flashing (see _checkForNew).
    if (!_seeded) _checkForNew();
    final entry = _visible;
    if (entry == null) return const SizedBox.shrink();
    final isReveal = entry.kind == ChatEntryKind.declarationRevealed;
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 200),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: PilottaColors.felt900.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(isReveal ? 16 : 20),
                border: Border.all(color: PilottaColors.gold500, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chatEntryLabel(entry, widget.viewerSeat),
                    style: const TextStyle(
                      color: PilottaColors.gold500,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (isReveal) ...[
                    const SizedBox(height: 8),
                    DeclarationCardsRow(declarations: entry.declarations!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
