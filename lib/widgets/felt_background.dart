import 'package:flutter/material.dart';

import '../theme/pilotta_colors.dart';

/// The base "table" backdrop: a subtle radial gradient, lighter at the
/// center than the edges, like a table lit from above. Flat single-color
/// backgrounds read as generic app chrome; this small amount of depth is
/// what makes a screen feel like a table rather than a form.
class FeltBackground extends StatelessWidget {
  final Widget child;

  const FeltBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.2,
          colors: [PilottaColors.felt800, PilottaColors.felt900],
        ),
      ),
      child: child,
    );
  }
}
