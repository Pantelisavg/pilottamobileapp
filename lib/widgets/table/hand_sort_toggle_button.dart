import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/app_settings.dart';

/// Lets the viewer flip their hand's sort order right from the table,
/// instead of needing to leave the game and dig into Settings — the same
/// [AppSettings.handAscending] flag, surfaced where it's actually used.
class HandSortToggleButton extends StatelessWidget {
  const HandSortToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    return IconButton(
      icon: Icon(
        settings.handAscending ? Icons.arrow_upward : Icons.arrow_downward,
        size: 18,
      ),
      tooltip: settings.handAscending
          ? 'Σειρά φύλλων: χαμηλό προς υψηλό (πάτα για αλλαγή)'
          : 'Σειρά φύλλων: υψηλό προς χαμηλό (πάτα για αλλαγή)',
      visualDensity: VisualDensity.compact,
      onPressed: () => settings.setHandAscending(!settings.handAscending),
    );
  }
}
