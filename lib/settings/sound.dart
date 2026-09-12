import 'package:flutter/services.dart';

import 'app_settings.dart';

/// A light, dependency-free "tap" cue (system click sound + haptic) used
/// for card plays and bidding actions. There are no bundled sound assets in
/// this app, so this intentionally leans on the platform's own click sound
/// rather than pulling in an audio-asset pipeline.
void playTapSound(AppSettings settings) {
  if (!settings.soundEnabled) return;
  SystemSound.play(SystemSoundType.click);
  HapticFeedback.lightImpact();
}
