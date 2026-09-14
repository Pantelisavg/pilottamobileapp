import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'card_deck_style.dart';

/// App-wide, persisted preferences: the configurable house rule, sound,
/// and card size. Loaded once at startup and provided down the widget tree
/// so any screen can read or change it.
class AppSettings extends ChangeNotifier {
  static const _kOvertrump = 'mustOvertrumpAllSuits';
  static const _kSound = 'soundEnabled';
  static const _kCardScale = 'cardScale';
  static const _kHandAscending = 'handAscending';
  static const _kPlayerName = 'playerName';
  static const _kDeckStyle = 'deckStyle';

  static const double minCardScale = 0.8;
  static const double maxCardScale = 1.3;
  static const String defaultPlayerName = 'Εσύ';

  final SharedPreferences _prefs;

  bool _mustOvertrumpAllSuits;
  bool _soundEnabled;
  double _cardScale;
  bool _handAscending;
  String _playerName;
  CardDeckStyle _deckStyle;

  AppSettings._(
    this._prefs, {
    required bool mustOvertrumpAllSuits,
    required bool soundEnabled,
    required double cardScale,
    required bool handAscending,
    required String playerName,
    required CardDeckStyle deckStyle,
  })  : _mustOvertrumpAllSuits = mustOvertrumpAllSuits,
        _soundEnabled = soundEnabled,
        _cardScale = cardScale,
        _handAscending = handAscending,
        _playerName = playerName,
        _deckStyle = deckStyle;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(
      prefs,
      mustOvertrumpAllSuits: prefs.getBool(_kOvertrump) ?? false,
      soundEnabled: prefs.getBool(_kSound) ?? true,
      cardScale: prefs.getDouble(_kCardScale) ?? 1.0,
      handAscending: prefs.getBool(_kHandAscending) ?? false,
      playerName: prefs.getString(_kPlayerName) ?? defaultPlayerName,
      deckStyle: CardDeckStyle.values.firstWhere(
        (s) => s.name == prefs.getString(_kDeckStyle),
        orElse: () => CardDeckStyle.classic,
      ),
    );
  }

  bool get mustOvertrumpAllSuits => _mustOvertrumpAllSuits;
  bool get soundEnabled => _soundEnabled;
  double get cardScale => _cardScale;

  /// Rank order within each suit group in a hand: false (default) shows
  /// A, K, Q, J, 10, 9, 8, 7 (highest first); true reverses it to
  /// 7, 8, 9, 10, J, Q, K, A.
  bool get handAscending => _handAscending;

  /// The name shown for the human seat in local play, and the default
  /// pre-filled when joining an online/Bluetooth room.
  String get playerName => _playerName;

  /// Which of the fully original CustomPainter-drawn card looks
  /// [PlayingCardWidget] renders with — applies everywhere a card is shown.
  CardDeckStyle get deckStyle => _deckStyle;

  Future<void> setMustOvertrumpAllSuits(bool value) async {
    if (value == _mustOvertrumpAllSuits) return;
    _mustOvertrumpAllSuits = value;
    notifyListeners();
    await _prefs.setBool(_kOvertrump, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    if (value == _soundEnabled) return;
    _soundEnabled = value;
    notifyListeners();
    await _prefs.setBool(_kSound, value);
  }

  Future<void> setCardScale(double value) async {
    final clamped = value.clamp(minCardScale, maxCardScale);
    if (clamped == _cardScale) return;
    _cardScale = clamped;
    notifyListeners();
    await _prefs.setDouble(_kCardScale, clamped);
  }

  Future<void> setHandAscending(bool value) async {
    if (value == _handAscending) return;
    _handAscending = value;
    notifyListeners();
    await _prefs.setBool(_kHandAscending, value);
  }

  Future<void> setPlayerName(String value) async {
    final trimmed = value.trim();
    final effective = trimmed.isEmpty ? defaultPlayerName : trimmed;
    if (effective == _playerName) return;
    _playerName = effective;
    notifyListeners();
    await _prefs.setString(_kPlayerName, effective);
  }

  Future<void> setDeckStyle(CardDeckStyle value) async {
    if (value == _deckStyle) return;
    _deckStyle = value;
    notifyListeners();
    await _prefs.setString(_kDeckStyle, value.name);
  }
}
