import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

import '../theme/pilotta_colors.dart';
import '../theme/pilotta_typography.dart';
import 'chat_entry_label.dart';

/// Opens the shared chat/event log as a bottom sheet. [listenable] is
/// whatever drives the room's state (a [LocalGameController] or
/// [RoomClientController]) — the sheet rebuilds live off it so messages
/// from other seats appear while it's open, not just when reopened.
Future<void> showChatPanel(
  BuildContext context, {
  required Listenable listenable,
  required List<ChatEntry> Function() chatLogOf,
  required Seat viewerSeat,
  required void Function(String text) onSend,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AnimatedBuilder(
      animation: listenable,
      builder: (context, _) => ChatPanel(
        chatLog: chatLogOf(),
        viewerSeat: viewerSeat,
        onSend: onSend,
      ),
    ),
  );
}

class ChatPanel extends StatefulWidget {
  final List<ChatEntry> chatLog;
  final Seat viewerSeat;
  final void Function(String text) onSend;

  const ChatPanel({
    super.key,
    required this.chatLog,
    required this.viewerSeat,
    required this.onSend,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(covariant ChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chatLog.length != oldWidget.chatLog.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _textController.clear();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: PilottaColors.felt800,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('Συνομιλία', style: PilottaTypography.title),
              ),
              const Divider(height: 1, color: Colors.white24),
              Expanded(
                child: widget.chatLog.isEmpty
                    ? const Center(
                        child: Text('Δεν υπάρχουν μηνύματα ακόμα.',
                            style: TextStyle(color: PilottaColors.ink400)),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: widget.chatLog.length,
                        itemBuilder: (context, i) {
                          final entry = widget.chatLog[i];
                          final isSystem = entry.kind != ChatEntryKind.chat;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              chatEntryLabel(entry, widget.viewerSeat),
                              style: TextStyle(
                                color: isSystem ? PilottaColors.gold500 : PilottaColors.ink50,
                                fontStyle: isSystem ? FontStyle.italic : FontStyle.normal,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 1, color: Colors.white24),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLength: 200,
                        style: const TextStyle(color: PilottaColors.ink50),
                        decoration: const InputDecoration(
                          hintText: 'Γράψε ένα μήνυμα…',
                          hintStyle: TextStyle(color: PilottaColors.ink400),
                          counterText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: PilottaColors.gold500),
                      onPressed: _send,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
