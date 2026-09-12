import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/game_mode_accent.dart';
import '../theme/pilotta_colors.dart';
import '../theme/pilotta_spacing.dart';
import '../theme/pilotta_typography.dart';
import '../widgets/felt_background.dart';
import '../widgets/felt_panel.dart';
import 'bluetooth_lobby_screen.dart';
import 'local_game_screen.dart';
import 'online_lobby_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _targetScore = 101;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FeltBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: PilottaSpacing.lg, vertical: PilottaSpacing.xl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Wordmark(),
                        const SizedBox(height: PilottaSpacing.xxl),
                        _TargetScoreSelector(
                          value: _targetScore,
                          onChanged: (v) => setState(() => _targetScore = v),
                        ),
                        const SizedBox(height: PilottaSpacing.xl),
                        _ModeMenuTile(
                          mode: GameModeAccent.localBots,
                          title: 'Παιχνίδι με Bots',
                          subtitle: 'Τοπικά, χωρίς σύνδεση — παίζεις αμέσως',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => LocalGameScreen(targetScore: _targetScore),
                          )),
                        ),
                        const SizedBox(height: PilottaSpacing.sm),
                        _ModeMenuTile(
                          mode: GameModeAccent.online,
                          title: 'Online Παιχνίδι',
                          subtitle: 'Δωμάτιο με κωδικό, παίκτες από παντού',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const OnlineLobbyScreen(),
                          )),
                        ),
                        // Nearby Connections (the Bluetooth/local-network
                        // backend) is an Android-only plugin.
                        if (!kIsWeb && Platform.isAndroid) ...[
                          const SizedBox(height: PilottaSpacing.sm),
                          _ModeMenuTile(
                            mode: GameModeAccent.bluetooth,
                            title: 'Bluetooth / Τοπικό δίκτυο',
                            subtitle: 'Χωρίς internet — παίκτες κοντά σου',
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const BluetoothLobbyScreen(),
                            )),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  icon: const Icon(Icons.settings_outlined, color: PilottaColors.ink200),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('ΠΙΛΟΤΤΑ', style: PilottaTypography.display),
        const SizedBox(height: PilottaSpacing.xs),
        Container(
          width: 56,
          height: 3,
          decoration: BoxDecoration(
            color: PilottaColors.gold500,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: PilottaSpacing.xs),
        Text(
          'ΠΑΛΑΡΙΣΤΗ',
          style: PilottaTypography.caption.copyWith(color: PilottaColors.ink200, letterSpacing: 3),
        ),
      ],
    );
  }
}

class _TargetScoreSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _TargetScoreSelector({required this.value, required this.onChanged});

  static const options = [101, 151, 201];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('ΠΟΝΤΟΙ ΝΙΚΗΣ', style: PilottaTypography.caption),
        const SizedBox(height: PilottaSpacing.xs),
        SegmentedButton<int>(
          segments: [
            for (final option in options) ButtonSegment(value: option, label: Text('$option')),
          ],
          selected: {value},
          onSelectionChanged: (s) => onChanged(s.first),
          showSelectedIcon: false,
        ),
      ],
    );
  }
}

/// One entry in the mode menu: an icon badge tinted with the mode's accent
/// color, title/subtitle, a small [ModeBadge] naming the mode explicitly,
/// and a trailing chevron affording "tap to enter." The accent color +
/// icon + text label together (color alone is never the only signal) keep
/// the three modes visually distinct at a glance, including for
/// color-blind users.
class _ModeMenuTile extends StatelessWidget {
  final GameModeAccent mode;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeMenuTile({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FeltPanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: PilottaSpacing.md, vertical: PilottaSpacing.sm + 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: mode.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(mode.icon, color: mode.color, size: 22),
          ),
          const SizedBox(width: PilottaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ModeBadge(mode: mode, dense: true),
                const SizedBox(height: PilottaSpacing.xxs),
                Text(title, style: PilottaTypography.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: PilottaTypography.bodyMuted, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: PilottaSpacing.xs),
          const Icon(Icons.chevron_right, color: PilottaColors.ink400),
        ],
      ),
    );
  }
}
