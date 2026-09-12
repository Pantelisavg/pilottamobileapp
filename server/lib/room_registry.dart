import 'dart:math';

import 'package:pilotta_protocol/pilotta_protocol.dart';

/// Letters/digits with visually ambiguous characters (0/O, 1/I/L) removed,
/// since room codes get read aloud and typed on a phone keyboard.
const _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

/// Tracks every in-progress room on the server, keyed by its short join
/// code. A single process is assumed to run one registry; there's no
/// persistence, so a server restart drops all rooms (an acceptable
/// trade-off for a card game — a dropped match is only a few minutes lost).
class RoomRegistry {
  final Map<String, PilottaRoom> _rooms = {};
  final Random _random;

  RoomRegistry([Random? random]) : _random = random ?? Random();

  String _generateCode() {
    String code;
    do {
      code = List.generate(4, (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)])
          .join();
    } while (_rooms.containsKey(code));
    return code;
  }

  PilottaRoom createRoom({required int targetScore, bool mustOvertrumpAllSuits = false}) {
    final code = _generateCode();
    final room = PilottaRoom(
      roomCode: code,
      targetScore: targetScore,
      mustOvertrumpAllSuits: mustOvertrumpAllSuits,
    );
    _rooms[code] = room;
    return room;
  }

  PilottaRoom? find(String code) => _rooms[code.trim().toUpperCase()];

  void remove(String code) {
    _rooms[code]?.dispose();
    _rooms.remove(code);
  }

  int get roomCount => _rooms.length;
}
