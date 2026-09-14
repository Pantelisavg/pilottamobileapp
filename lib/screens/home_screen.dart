import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../persistence/local_game_save.dart';
import '../settings/app_settings.dart';
import '../theme/game_mode_accent.dart';
import '../theme/pilotta_colors.dart';
import '../theme/pilotta_spacing.dart';
import '../theme/pilotta_typography.dart';
import '../widgets/felt_background.dart';
import '../widgets/felt_panel.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/target_score_selector.dart';
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
  int _targetScore = _TargetScoreSelector.presets.first;
  bool _hasSave = false;

  @override
  void initState() {
    super.initState();
    _refreshSaveState();
  }

  Future<void> _refreshSaveState() async {
    final hasSave = await LocalGameSave.exists();
    if (mounted) setState(() => _hasSave = hasSave);
  }

  Future<void> _continueGame() async {
    final saved = await LocalGameSave.load();
    if (saved == null) {
      await _refreshSaveState();
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LocalGameScreen.resume(resumeFrom: saved),
    ));
    _refreshSaveState();
  }

  Future<void> _startFreshLocalGame() async {
    if (_hasSave) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: PilottaColors.felt800,
          title: const Text('Παιχνίδι σε εξέλιξη',
              style: TextStyle(color: PilottaColors.ink50)),
          content: const Text(
            'Έχεις ένα αποθηκευμένο παιχνίδι με bots. Αν ξεκινήσεις νέο, η πρόοδός του θα χαθεί.',
            style: TextStyle(color: PilottaColors.ink200),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Άκυρο')),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Νέο παιχνίδι'),
            ),
          ],
        ),
      );
      if (discard != true) return;
      await LocalGameSave.clear();
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LocalGameScreen(targetScore: _targetScore),
    ));
    _refreshSaveState();
  }

  @override
  Widget build(BuildContext context) {
    // The app is landscape-locked, so a phone's short dimension is height,
    // not width — stacking everything (wordmark, name field, target score,
    // every mode tile) in one column is what forced scrolling before. A
    // side-by-side split uses the width landscape actually has to spare;
    // the outer SingleChildScrollView stays only as a safety net for
    // extreme accessibility text-scale settings, not the normal path.
    final compact = MediaQuery.sizeOf(context).height < 380;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FeltBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: PilottaSpacing.lg,
                      vertical:
                          compact ? PilottaSpacing.xs : PilottaSpacing.sm),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Wordmark(compact: compact),
                              SizedBox(
                                  height: compact
                                      ? PilottaSpacing.sm
                                      : PilottaSpacing.md),
                              const _PlayerNameField(),
                              SizedBox(
                                  height: compact
                                      ? PilottaSpacing.xs
                                      : PilottaSpacing.sm),
                              _TargetScoreSelector(
                                value: _targetScore,
                                onChanged: (v) =>
                                    setState(() => _targetScore = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: PilottaSpacing.lg),
                        Expanded(
                          flex: 5,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_hasSave) ...[
                                _ModeMenuTile(
                                  mode: GameModeAccent.localBots,
                                  title: 'Συνέχεια παιχνιδιού',
                                  subtitle: 'Συνέχισε το παιχνίδι με bots',
                                  onTap: _continueGame,
                                  compact: compact,
                                ),
                                SizedBox(
                                    height: compact
                                        ? PilottaSpacing.xxs
                                        : PilottaSpacing.xs),
                              ],
                              _ModeMenuTile(
                                mode: GameModeAccent.localBots,
                                title: 'Παιχνίδι με Bots',
                                subtitle: 'Τοπικά, χωρίς σύνδεση',
                                onTap: _startFreshLocalGame,
                                compact: compact,
                              ),
                              SizedBox(
                                  height: compact
                                      ? PilottaSpacing.xxs
                                      : PilottaSpacing.xs),
                              _ModeMenuTile(
                                mode: GameModeAccent.online,
                                title: 'Online Παιχνίδι',
                                subtitle: 'Δωμάτιο με κωδικό',
                                onTap: () => Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  builder: (_) => const OnlineLobbyScreen(),
                                )),
                                compact: compact,
                              ),
                              // Nearby Connections (the Bluetooth/local-network
                              // backend) is an Android-only plugin.
                              if (!kIsWeb && Platform.isAndroid) ...[
                                SizedBox(
                                    height: compact
                                        ? PilottaSpacing.xxs
                                        : PilottaSpacing.xs),
                                _ModeMenuTile(
                                  mode: GameModeAccent.bluetooth,
                                  title: 'Bluetooth / Τοπικό',
                                  subtitle: 'Χωρίς internet',
                                  onTap: () => Navigator.of(context)
                                      .push(MaterialPageRoute(
                                    builder: (_) =>
                                        const BluetoothLobbyScreen(),
                                  )),
                                  compact: compact,
                                ),
                              ],
                            ],
                          ),
                        ),
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
                  icon: const Icon(Icons.settings_outlined,
                      color: PilottaColors.ink200),
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
  final bool compact;
  const _Wordmark({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('ΠΙΛΟΤΤΑ',
            style: PilottaTypography.display
                .copyWith(fontSize: compact ? 30 : 38)),
        SizedBox(height: compact ? 2 : PilottaSpacing.xxs),
        Container(
          width: 44,
          height: 3,
          decoration: BoxDecoration(
            color: PilottaColors.gold500,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(height: compact ? 2 : PilottaSpacing.xxs),
        Text(
          'ΠΑΛΑΡΙΣΤΗ',
          style: PilottaTypography.caption
              .copyWith(color: PilottaColors.ink200, letterSpacing: 3),
        ),
      ],
    );
  }
}

/// Lets the player type their own name for local (hotseat) play — the same
/// name is offered as the default when joining an online/Bluetooth room.
class _PlayerNameField extends StatefulWidget {
  const _PlayerNameField();

  @override
  State<_PlayerNameField> createState() => _PlayerNameFieldState();
}

class _PlayerNameFieldState extends State<_PlayerNameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: context.read<AppSettings>().playerName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textAlign: TextAlign.center,
      maxLength: 20,
      style: const TextStyle(color: PilottaColors.ink50),
      decoration: InputDecoration(
        isDense: true,
        labelText: 'Το όνομά σου',
        labelStyle: const TextStyle(color: PilottaColors.ink400),
        counterText: '',
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: PilottaColors.ink400),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: PilottaColors.gold500),
        ),
      ),
      onChanged: (v) => context.read<AppSettings>().setPlayerName(v),
    );
  }
}

class _TargetScoreSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _TargetScoreSelector({required this.value, required this.onChanged});

  static const presets = kTargetScorePresets;

  @override
  Widget build(BuildContext context) {
    final isCustom = !presets.contains(value);
    return Column(
      children: [
        Text('ΠΟΝΤΟΙ ΝΙΚΗΣ', style: PilottaTypography.caption),
        const SizedBox(height: PilottaSpacing.xxs),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: PilottaSpacing.xs,
          runSpacing: PilottaSpacing.xxs,
          children: [
            SegmentedButton<int>(
              segments: [
                for (final option in presets)
                  ButtonSegment(value: option, label: Text('$option')),
              ],
              selected: {value},
              onSelectionChanged: (s) => onChanged(s.first),
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            OutlinedButton(
              onPressed: () async {
                final result = await showCustomTargetScoreDialog(
                  context,
                  current: value,
                  backgroundColor: PilottaColors.felt800,
                  textColor: PilottaColors.ink50,
                  hintColor: PilottaColors.ink400,
                );
                if (result != null) onChanged(result);
              },
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor:
                    isCustom ? PilottaColors.ink900 : PilottaColors.ink200,
                backgroundColor: isCustom ? PilottaColors.gold500 : null,
                side: BorderSide(
                    color: isCustom
                        ? PilottaColors.gold500
                        : PilottaColors.ink400),
              ),
              child: Text(isCustom ? 'Προσαρμογή: $value' : 'Προσαρμογή'),
            ),
          ],
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
  final bool compact;

  const _ModeMenuTile({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 30.0 : 36.0;
    return PressableScale(
      child: FeltPanel(
        onTap: onTap,
        padding: EdgeInsets.symmetric(
            horizontal: PilottaSpacing.sm,
            vertical: compact ? PilottaSpacing.xxs : PilottaSpacing.xs),
        radius: 14,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: mode.color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(mode.icon, color: mode.color, size: iconSize * 0.52),
            ),
            const SizedBox(width: PilottaSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: PilottaTypography.title
                          .copyWith(fontSize: compact ? 14 : 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(subtitle,
                      style: PilottaTypography.bodyMuted
                          .copyWith(fontSize: compact ? 11 : 12, height: 1.1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            ModeBadge(mode: mode, dense: true),
            const SizedBox(width: PilottaSpacing.xxs),
            Icon(Icons.chevron_right,
                color: PilottaColors.ink400, size: compact ? 18 : 20),
          ],
        ),
      ),
    );
  }
}
