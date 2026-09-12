import 'package:flutter/material.dart';

import '../theme/pilotta_colors.dart';
import '../theme/pilotta_spacing.dart';

/// A surface that reads as "resting on the felt": rounded corners, a soft
/// warm-tinted shadow (see [PilottaColors.shadowRaised]) instead of
/// Material's default cool-gray elevation, and an optional accent border
/// for emphasis (e.g. the active/selected state of a menu tile).
///
/// This is the one building block every raised panel in the app should use
/// — home menu tiles, lobby cards, dialogs — so changing the "felt panel"
/// look later means editing one widget, not every screen.
class FeltPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? accentBorder;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;
  final double radius;

  const FeltPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PilottaSpacing.md),
    this.color,
    this.accentBorder,
    this.onTap,
    this.shadow,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final content = Padding(padding: padding, child: child);

    // The shadow lives on a transparent outer container, and the actual
    // fill color lives on the Material inside it — Material has to own the
    // opaque background for InkWell's tap ripple to be visible at all; an
    // opaque Container painted on top of InkWell would hide the ripple.
    final surface = Material(
      color: color ?? PilottaColors.felt700,
      borderRadius: borderRadius,
      child: onTap == null
          ? content
          : InkWell(borderRadius: borderRadius, onTap: onTap, child: content),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: accentBorder != null ? Border.all(color: accentBorder!, width: 1.5) : null,
        boxShadow: shadow ?? PilottaColors.shadowRaised,
      ),
      child: surface,
    );
  }
}
