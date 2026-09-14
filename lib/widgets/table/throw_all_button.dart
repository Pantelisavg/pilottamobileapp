import 'package:flutter/material.dart';

import 'game_table_data.dart';
import 'throw_all.dart';

/// Shown only when the viewer's move is already forced (exactly one legal
/// card) — taps through the whole forced streak via [throwAll] instead of
/// making them tap the same obvious card trick after trick.
class ThrowAllButton extends StatefulWidget {
  final GameTableData controller;
  const ThrowAllButton({super.key, required this.controller});

  @override
  State<ThrowAllButton> createState() => _ThrowAllButtonState();
}

class _ThrowAllButtonState extends State<ThrowAllButton> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final canThrow = !_running &&
        controller.isViewerTurnToPlay &&
        controller.viewerLegalPlays.length == 1;
    if (!canThrow) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.amberAccent,
          side: const BorderSide(color: Colors.amberAccent),
          visualDensity: VisualDensity.compact,
        ),
        onPressed: () async {
          setState(() => _running = true);
          await throwAll(controller);
          if (mounted) setState(() => _running = false);
        },
        icon: const Icon(Icons.fast_forward, size: 16),
        label: const Text('Παίξ\' τα όλα'),
      ),
    );
  }
}
