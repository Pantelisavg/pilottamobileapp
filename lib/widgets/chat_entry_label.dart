import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

import 'declaration_label.dart';
import 'seat_layout.dart';

/// A short Greek line describing [entry] from [viewer]'s point of view —
/// used both in the scrollable chat log and the brief on-screen flash.
String chatEntryLabel(ChatEntry entry, Seat viewer) {
  final who = seatLabelRelativeTo(entry.seat, viewer);
  return switch (entry.kind) {
    ChatEntryKind.chat => '$who: ${entry.text}',
    ChatEntryKind.declarationAnnounced => '$who δηλώνει!',
    ChatEntryKind.declarationRevealed =>
      '$who αποκαλύπτει: ${declarationsLabelFromJsonList(entry.declarations!)}',
    ChatEntryKind.pilotta => '$who: Πιλόττα!',
    ChatEntryKind.repilotta => '$who: Ρεπιλόττα!',
  };
}

/// Whether [entry] is a system event worth flashing on screen for every
/// player for a few seconds — as opposed to plain chat, which only needs
/// to show up in the log itself.
bool chatEntryIsFlashWorthy(ChatEntry entry) =>
    entry.kind != ChatEntryKind.chat;
