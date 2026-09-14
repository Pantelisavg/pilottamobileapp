import 'package:flutter/material.dart';

import 'leave_table_scope.dart';

/// Explicit AppBar affordance for leaving the table, routed through the
/// same confirmation as the back gesture (see [LeaveTableScope]).
class LeaveTableButton extends StatelessWidget {
  const LeaveTableButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.exit_to_app),
      tooltip: 'Αποχώρηση',
      onPressed: () => LeaveTableScope.leave(context),
    );
  }
}
