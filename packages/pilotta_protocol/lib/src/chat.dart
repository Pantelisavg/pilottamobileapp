import 'package:pilotta_engine/pilotta_engine.dart';

/// What kind of thing happened at [ChatEntry.seat]'s end of the table.
enum ChatEntryKind {
  /// A free-text message the seat actually typed.
  chat,

  /// The seat announced a (non-Pilotta) declaration during trick 1 — per
  /// the rules, the point value is said out loud right away ([announcedValue]),
  /// but which cards/suit it actually is stays hidden until reveal.
  declarationAnnounced,

  /// The seat revealed their previously-announced declaration(s) —
  /// [declarations] carries every one of them (a hand can hold more than
  /// one; only the best is announced out loud, but all are shown and score
  /// once revealed).
  declarationRevealed,

  /// The seat just played the first of their King+Queen of trump.
  pilotta,

  /// The seat just played the second of their King+Queen of trump.
  repilotta,
}

/// One entry in a room's shared chat/event log — free-text messages a
/// player typed, interleaved with system-generated entries for the things
/// every seat is meant to see live at the table (declarations, Pilotta
/// calls). Every viewer of a room sees the exact same log.
class ChatEntry {
  /// Monotonically increasing within a room — lets a UI tell a brand new
  /// entry apart from one it's already shown (e.g. to flash it once).
  final int id;
  final Seat seat;
  final ChatEntryKind kind;

  /// Set only for [ChatEntryKind.chat].
  final String? text;

  /// Set only for [ChatEntryKind.declarationAnnounced] — the point value
  /// (20/50/100/150/200) spoken out loud, per the rules; never the cards.
  final int? announcedValue;

  /// Set only for [ChatEntryKind.declarationRevealed] — one or more, each
  /// the shape `declarationToJson` produces (see `declarationsLabelFromJsonList`
  /// in the app for rendering them without a pilotta_protocol dependency).
  final List<Map<String, dynamic>>? declarations;

  const ChatEntry({
    required this.id,
    required this.seat,
    required this.kind,
    this.text,
    this.announcedValue,
    this.declarations,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'seat': seat.name,
        'kind': kind.name,
        if (text != null) 'text': text,
        if (announcedValue != null) 'announcedValue': announcedValue,
        if (declarations != null) 'declarations': declarations,
      };

  static ChatEntry fromJson(Map<String, dynamic> json) => ChatEntry(
        id: json['id'] as int,
        seat: Seat.values.byName(json['seat'] as String),
        kind: ChatEntryKind.values.byName(json['kind'] as String),
        text: json['text'] as String?,
        announcedValue: json['announcedValue'] as int?,
        declarations: (json['declarations'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>(),
      );
}
