import 'package:flutter/material.dart';

import 'leave_table_dialog.dart';

/// Wraps a game table screen so every way of leaving it — the system back
/// gesture/button, the AppBar's back arrow, or an explicit leave button —
/// goes through the same [confirmLeaveTable] dialog and the same "back to
/// the menu" destination, instead of each trigger doing its own thing.
class LeaveTableScope extends StatelessWidget {
  final Widget child;
  const LeaveTableScope({super.key, required this.child});

  static Future<void> leave(BuildContext context) async {
    if (await confirmLeaveTable(context) && context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        leave(context);
      },
      child: child,
    );
  }
}
