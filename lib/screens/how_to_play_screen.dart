import 'package:flutter/material.dart';

import '../theme/pilotta_colors.dart';
import '../theme/pilotta_spacing.dart';
import '../theme/pilotta_typography.dart';
import '../widgets/felt_background.dart';
import '../widgets/felt_panel.dart';

/// A static "how to play" reference: rules summary, scoring cheatsheet, and
/// a declarations table. Reachable from the home screen and from Settings,
/// meant as something a player can dip into mid-match to check a rule
/// rather than a one-time onboarding flow.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      icon: const Icon(Icons.arrow_back, color: PilottaColors.ink50),
                    ),
                    const SizedBox(width: PilottaSpacing.xs),
                    Text('Πώς παίζεται', style: PilottaTypography.title),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: PilottaSpacing.lg, vertical: PilottaSpacing.md),
                  children: const [
                    _Section(
                      title: 'Η μοιρασιά & η δημοπρασία',
                      bullets: [
                        '4 παίκτες, 2 ομάδες (απέναντι συμπαίκτες). 32 φύλλα (7 έως Άσος), 8 ο καθένας.',
                        'Οι δηλώσεις ξεκινούν από τον παίκτη μετά τον μοιραστή. Κάθε δήλωση '
                            'πρέπει να είναι μεγαλύτερη από την προηγούμενη, πολλαπλάσιο του 10, '
                            'ξεκινώντας από 80.',
                        'Μπορείς να "κοντράρεις" τη δήλωση του αντιπάλου (x2) ή να "ξανακοντράρεις" '
                            'τη δική σου κοντραρισμένη δήλωση (x4).',
                        'Το "Καπότο" είναι μια ειδική δήλωση: υπόσχεσαι να πάρεις όλες τις 8 μπάζες.',
                        'Αν όλοι περάσουν χωρίς δήλωση, μοιράζει ξανά ο επόμενος.',
                      ],
                    ),
                    SizedBox(height: PilottaSpacing.lg),
                    _Section(
                      title: 'Αξία φύλλων',
                      bullets: [
                        'Στο ατού: Βαλές (20) > 9 (14) > Άσος (11) > 10 (10) > Ρήγας (4) > Ντάμα (3) > 8,7 (0).',
                        'Στα άλλα χρώματα: Άσος (11) > 10 (10) > Ρήγας (4) > Ντάμα (3) > Βαλές (2) > 9,8,7 (0).',
                        'Σύνολο 152 πόντοι στα φύλλα + 10 μπόνους για την τελευταία μπάζα = 162.',
                      ],
                    ),
                    SizedBox(height: PilottaSpacing.lg),
                    _Section(
                      title: 'Παίξιμο',
                      bullets: [
                        'Πρέπει να ακολουθήσεις το χρώμα που παίχτηκε αν έχεις.',
                        'Αν δεν έχεις το χρώμα, πρέπει να κόψεις με ατού αν έχεις.',
                        'Αν παίζεις ατού (είτε ακολουθώντας είτε κόβοντας) και κάποιος έχει ήδη '
                            'παίξει ατού στη μπάζα, πρέπει να ανέβεις αν μπορείς.',
                      ],
                    ),
                    SizedBox(height: PilottaSpacing.lg),
                    _Section(
                      title: 'Δηλώσεις (σκάλες & καρέ)',
                      bullets: [
                        'Σκάλα 3 φύλλων ίδιου χρώματος = 20, σκάλα 4 = 50, σκάλα 5+ = 100.',
                        'Καρέ βαλέδων = 200, καρέ εννιάρια = 150, κάθε άλλο καρέ = 100 (τα 7 και 8 δεν μετράνε).',
                        'Πρέπει να δηλώσεις στην 1η μπάζα και να αποκαλύψεις πριν παίξεις το '
                            'φύλλο σου στη 2η μπάζα — αλλιώς χάνεται.',
                        'Αν έχουν δηλώσει και οι δύο ομάδες, μετράει μόνο η πιο ψηλή — και μαζί '
                            'της όλες οι δηλώσεις της ίδιας ομάδας.',
                        'Μπελότ-Ρεμπελότ (Ρήγας+Ντάμα ατού στο ίδιο χέρι) = 20, μετράει πάντα, '
                            'δηλώνεται καθώς παίζεις τα δύο φύλλα.',
                      ],
                    ),
                    SizedBox(height: PilottaSpacing.lg),
                    _Section(
                      title: 'Σκοράρισμα',
                      bullets: [
                        'Πέτυχε η δήλωση: η ομάδα που δήλωσε κρατά τους πόντους της + την αξία της δήλωσης.',
                        'Απέτυχε η δήλωση: η αντίπαλη ομάδα παίρνει την αξία της δήλωσης + όλους '
                            'τους πόντους του χεριού (162 + δηλώσεις).',
                        'Κοντραρισμένη δήλωση: όποια ομάδα δικαιώθηκε παίρνει ΟΛΟΥΣ τους πόντους '
                            'του χεριού + την (πολλαπλασιασμένη) αξία της δήλωσης, η άλλη τίποτα.',
                        'Καπότο (όλες οι μπάζες): 250 πόντοι αντί για το κανονικό άθροισμα.',
                        'Οι τελικοί πόντοι στρογγυλοποιούνται στο 10άρι — στην ισοπαλία στο 6 '
                            'κερδίζει η ομάδα που δήλωσε.',
                      ],
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

class _Section extends StatelessWidget {
  final String title;
  final List<String> bullets;
  const _Section({required this.title, required this.bullets});

  @override
  Widget build(BuildContext context) {
    return FeltPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: PilottaTypography.title.copyWith(fontSize: 16)),
          const SizedBox(height: PilottaSpacing.xs),
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(color: PilottaColors.gold500)),
                  Expanded(
                    child: Text(b, style: const TextStyle(color: PilottaColors.ink200, fontSize: 13, height: 1.35)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
