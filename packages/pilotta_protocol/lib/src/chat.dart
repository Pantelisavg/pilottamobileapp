import 'package:pilotta_engine/pilotta_engine.dart';

/// What kind of thing happened at [ChatEntry.seat]'s end of the table.
enum ChatEntryKind {
  /// A free-text message the seat actually typed.
  chat,

  /// The seat announced a (non-Pilotta) declaration during trick 1 — the
  /// content isn't public yet, only the fact that they announced one.
  declarationAnnounced,

  /// The seat revealed a previously-announced declaration — [declaration]
  /// carries what it actually was.
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

  /// Set only for [ChatEntryKind.declarationRevealed] — the shape
  /// `declarationToJson` produces (see `declarationLabelFromJson` in the
  /// app for rendering it without a pilotta_protocol dependency).
  final Map<String, dynamic>? declaration;

  const ChatEntry({
    required this.id,
    required this.seat,
    required this.kind,
    this.text,
    this.declaration,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'seat': seat.name,
        'kind': kind.name,
        if (text != null) 'text': text,
        if (declaration != null) 'declaration': declaration,
      };

  static ChatEntry fromJson(Map<String, dynamic> json) => ChatEntry(
        id: json['id'] as int,
        seat: Seat.values.byName(json['seat'] as String),
        kind: ChatEntryKind.values.byName(json['kind'] as String),
        text: json['text'] as String?,
        declaration: json['declaration'] as Map<String, dynamic>?,
      );
}
