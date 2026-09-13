import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

import 'seat_layout.dart';

/// A short Greek line describing [entry] from [viewer]'s point of view —
/// used both in the scrollable chat log and the brief on-screen flash.
///
/// For [ChatEntryKind.declarationRevealed] this is only the lead-in text
/// ("X αποκαλύπτει:") — the actual cards render separately, as real card
/// widgets, via [entry.declarations] (see `DeclarationCardsRow`).
String chatEntryLabel(ChatEntry entry, Seat viewer) {
  final who = seatLabelRelativeTo(entry.seat, viewer);
  return switch (entry.kind) {
    ChatEntryKind.chat => '$who: ${entry.text}',
    // Only the point value is ever spoken out loud on announce — the
    // actual cards/suit stay hidden until reveal.
    ChatEntryKind.declarationAnnounced =>
      '$who δηλώνει: ${entry.announcedValue}!',
    ChatEntryKind.declarationRevealed => '$who αποκαλύπτει:',
    ChatEntryKind.pilotta => '$who: Πιλόττα!',
    ChatEntryKind.repilotta => '$who: Ρεπιλόττα!',
  };
}

/// Whether [entry] is a system event worth flashing on screen for every
/// player for a few seconds — as opposed to plain chat, which only needs
/// to show up in the log itself.
bool chatEntryIsFlashWorthy(ChatEntry entry) =>
    entry.kind != ChatEntryKind.chat;
