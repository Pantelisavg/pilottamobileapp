import 'package:flutter/material.dart';

/// Opens [builder] with the app's shared dialog transition — a soft
/// scale-up + fade in place of [showDialog]'s abrupt default pop, so
/// opening one of the table's "ledger" dialogs (scoreboard replay, auction
/// history, last-trick recap) feels like a deliberate action rather than a
/// generic system dialog appearing. A thin wrapper around
/// [showGeneralDialog], since [showDialog] itself doesn't expose a
/// `transitionBuilder`.
Future<T?> showPilottaDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final scale =
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(scale),
          child: child,
        ),
      );
    },
  );
}
