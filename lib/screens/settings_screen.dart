import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:provider/provider.dart';

import '../settings/app_settings.dart';
import '../theme/pilotta_colors.dart';
import '../theme/pilotta_spacing.dart';
import '../theme/pilotta_typography.dart';
import '../widgets/felt_background.dart';
import '../widgets/felt_panel.dart';
import '../widgets/playing_card_widget.dart';
import 'how_to_play_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FeltBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: PilottaSpacing.md, vertical: PilottaSpacing.sm),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back,
                          color: PilottaColors.ink50),
                    ),
                    const SizedBox(width: PilottaSpacing.xs),
                    Text('Ρυθμίσεις', style: PilottaTypography.title),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: PilottaSpacing.lg,
                      vertical: PilottaSpacing.md),
                  children: [
                    _SectionLabel('Κανόνες'),
                    FeltPanel(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                            'Υποχρεωτικό ανέβασμα σε όλα τα χρώματα',
                            style: TextStyle(color: PilottaColors.ink50)),
                        subtitle: const Text(
                          'Παραλλαγή κανόνα: όποιος ακολουθεί χρώμα (όχι μόνο ατού) '
                          'πρέπει να ανέβει αν μπορεί. Ο βασικός κανόνας απαιτεί '
                          'ανέβασμα μόνο στο ατού.',
                          style: TextStyle(
                              color: PilottaColors.ink400, fontSize: 12),
                        ),
                        value: settings.mustOvertrumpAllSuits,
                        activeThumbColor: PilottaColors.gold500,
                        onChanged: (v) => settings.setMustOvertrumpAllSuits(v),
                      ),
                    ),
                    const SizedBox(height: PilottaSpacing.lg),
                    _SectionLabel('Ήχος & δόνηση'),
                    FeltPanel(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ήχος κινήσεων',
                            style: TextStyle(color: PilottaColors.ink50)),
                        subtitle: const Text(
                          'Ένα σύντομο ηχητικό/δόνηση σε κάθε φύλλο ή δήλωση.',
                          style: TextStyle(
                              color: PilottaColors.ink400, fontSize: 12),
                        ),
                        value: settings.soundEnabled,
                        activeThumbColor: PilottaColors.gold500,
                        onChanged: (v) => settings.setSoundEnabled(v),
                      ),
                    ),
                    const SizedBox(height: PilottaSpacing.lg),
                    _SectionLabel('Μέγεθος φύλλων'),
                    FeltPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Slider(
                            value: settings.cardScale,
                            min: AppSettings.minCardScale,
                            max: AppSettings.maxCardScale,
                            divisions: 5,
                            activeColor: PilottaColors.gold500,
                            label: '${(settings.cardScale * 100).round()}%',
                            onChanged: (v) => settings.setCardScale(v),
                          ),
                          Center(
                            child: PlayingCardWidget(
                              card: const PlayingCard(Suit.spades, Rank.ace),
                              width: 64 * settings.cardScale,
                            ),
                          ),
                          const SizedBox(height: PilottaSpacing.xs),
                        ],
                      ),
                    ),
                    const SizedBox(height: PilottaSpacing.lg),
                    _SectionLabel('Σειρά φύλλων στο χέρι'),
                    FeltPanel(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Αντίστροφη σειρά',
                            style: TextStyle(color: PilottaColors.ink50)),
                        subtitle: Text(
                          settings.handAscending
                              ? 'Τώρα: 7, 8, 9, 10, Β, Ντ, Ρ, Α (χαμηλό προς υψηλό).'
                              : 'Τώρα: Α, Ρ, Ντ, Β, 10, 9, 8, 7 (υψηλό προς χαμηλό).',
                          style: const TextStyle(
                              color: PilottaColors.ink400, fontSize: 12),
                        ),
                        value: settings.handAscending,
                        activeThumbColor: PilottaColors.gold500,
                        onChanged: (v) => settings.setHandAscending(v),
                      ),
                    ),
                    const SizedBox(height: PilottaSpacing.lg),
                    _SectionLabel('Βοήθεια'),
                    FeltPanel(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const HowToPlayScreen()),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.menu_book_outlined,
                              color: PilottaColors.gold500),
                          SizedBox(width: PilottaSpacing.sm),
                          Expanded(
                            child: Text('Πώς παίζεται η Πιλόττα',
                                style: TextStyle(
                                    color: PilottaColors.ink50, fontSize: 15)),
                          ),
                          Icon(Icons.chevron_right,
                              color: PilottaColors.ink400),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PilottaSpacing.xs, left: 4),
      child: Text(text, style: PilottaTypography.caption),
    );
  }
}
