import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide, persisted preferences: the configurable house rule, sound,
/// and card size. Loaded once at startup and provided down the widget tree
/// so any screen can read or change it.
class AppSettings extends ChangeNotifier {
  static const _kOvertrump = 'mustOvertrumpAllSuits';
  static const _kSound = 'soundEnabled';
  static const _kCardScale = 'cardScale';

  static const double minCardScale = 0.8;
  static const double maxCardScale = 1.3;

  final SharedPreferences _prefs;

  bool _mustOvertrumpAllSuits;
  bool _soundEnabled;
  double _cardScale;

  AppSettings._(
    this._prefs, {
    required bool mustOvertrumpAllSuits,
    required bool soundEnabled,
    required double cardScale,
  })  : _mustOvertrumpAllSuits = mustOvertrumpAllSuits,
        _soundEnabled = soundEnabled,
        _cardScale = cardScale;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(
      prefs,
      mustOvertrumpAllSuits: prefs.getBool(_kOvertrump) ?? false,
      soundEnabled: prefs.getBool(_kSound) ?? true,
      cardScale: prefs.getDouble(_kCardScale) ?? 1.0,
    );
  }

  bool get mustOvertrumpAllSuits => _mustOvertrumpAllSuits;
  bool get soundEnabled => _soundEnabled;
  double get cardScale => _cardScale;

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
}
