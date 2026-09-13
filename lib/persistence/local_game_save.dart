import 'dart:convert';

import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists a single "continue later" slot for a local (vs bots) match, so
/// closing the app mid-hand and coming back picks up exactly where you
/// left off — saved on every room change, cleared once the match ends.
abstract final class LocalGameSave {
  static const _key = 'localGameSave';

  static Future<void> save(PilottaRoom room) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(room.toSaveJson()));
  }

  static Future<bool> exists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  /// The saved room state, or null if there's none (or it's unreadable —
  /// e.g. left over from an incompatible older app version).
  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
