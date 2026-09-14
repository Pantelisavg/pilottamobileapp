import 'package:flutter/material.dart';

import 'pilotta_colors.dart';

/// The app's one screen-transition style, applied to every platform via
/// [ThemeData.pageTransitionsTheme] — a soft fade + slight upward slide on
/// the incoming page, with the page being covered dimmed under a faint
/// gold scrim rather than Material's default platform-specific transition
/// (a horizontal slide on Android, a full Cupertino push on iOS). One
/// definition here covers every existing `Navigator.push` in the app with
/// no call-site changes.
class PilottaPageTransitionsBuilder extends PageTransitionsBuilder {
  const PilottaPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final cover =
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic);

    return FadeTransition(
      opacity: enter,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero)
            .animate(enter),
        child: Stack(
          children: [
            child,
            // A faint gold scrim that fades in as this page is covered by a
            // new one pushed on top, instead of just sitting there unchanged
            // underneath.
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: cover,
                  child: Container(
                      color: PilottaColors.gold700.withValues(alpha: 0.18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
