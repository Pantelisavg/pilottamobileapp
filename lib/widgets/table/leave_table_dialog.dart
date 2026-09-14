import 'package:flutter/material.dart';

import '../../theme/pilotta_colors.dart';

/// Shared "are you sure" confirmation for leaving the table — used by both
/// the explicit leave button and by intercepting the back gesture/button
/// (see [LeaveTableScope]), so every way of trying to leave a match in
/// progress goes through the same one dialog.
Future<bool> confirmLeaveTable(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: PilottaColors.felt800,
      title: const Text('Αποχώρηση από το τραπέζι',
          style: TextStyle(color: PilottaColors.ink50)),
      content: const Text(
        'Είσαι σίγουρος/η ότι θέλεις να φύγεις από το παιχνίδι;',
        style: TextStyle(color: PilottaColors.ink200),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Άκυρο'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Αποχώρηση'),
        ),
      ],
    ),
  );
  return result ?? false;
}
