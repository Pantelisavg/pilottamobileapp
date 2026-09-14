import 'package:flutter/material.dart';

/// A small vector portrait glyph for [PlayerAvatar] — a plain card-table
/// patron silhouette for a human seat, a three-pointed jester cap (bells
/// and all) for a bot seat — drawn the same [CustomPainter] way as
/// [SuitIcon]/[CourtCardEmblem] rather than a stock Material icon, so a
/// bot reads as "the table's jester" instead of a generic robot-head glyph
/// that doesn't fit a card-table mood at all.
class TavernAvatarGlyph extends StatelessWidget {
  final bool isBot;
  final double size;
  final Color color;

  const TavernAvatarGlyph(
      {super.key, required this.isBot, required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AvatarGlyphPainter(isBot, color)),
    );
  }
}

class _AvatarGlyphPainter extends CustomPainter {
  final bool isBot;
  final Color color;
  _AvatarGlyphPainter(this.isBot, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    if (isBot) {
      _paintJester(canvas, size, paint);
    } else {
      _paintPatron(canvas, size, paint);
    }
  }

  void _paintPatron(Canvas canvas, Size s, Paint paint) {
    // A round head over a simple shoulders arc — plain but warmer than a
    // literal person-outline glyph, matching the jester's silhouette
    // weight so the two read as a pair.
    canvas.drawCircle(
        Offset(s.width * 0.5, s.height * 0.34), s.width * 0.22, paint);
    final shoulders = Path()
      ..moveTo(s.width * 0.14, s.height * 0.98)
      ..quadraticBezierTo(
          s.width * 0.14, s.height * 0.6, s.width * 0.5, s.height * 0.58)
      ..quadraticBezierTo(
          s.width * 0.86, s.height * 0.6, s.width * 0.86, s.height * 0.98)
      ..close();
    canvas.drawPath(shoulders, paint);
  }

  void _paintJester(Canvas canvas, Size s, Paint paint) {
    // A three-point jester cap over the same round head/shoulders base —
    // the cap is what makes the silhouette read as "the table's fool"
    // rather than a machine.
    canvas.drawCircle(
        Offset(s.width * 0.5, s.height * 0.4), s.width * 0.2, paint);
    final shoulders = Path()
      ..moveTo(s.width * 0.16, s.height * 0.98)
      ..quadraticBezierTo(
          s.width * 0.16, s.height * 0.66, s.width * 0.5, s.height * 0.64)
      ..quadraticBezierTo(
          s.width * 0.84, s.height * 0.66, s.width * 0.84, s.height * 0.98)
      ..close();
    canvas.drawPath(shoulders, paint);

    final cap = Path()
      ..moveTo(s.width * 0.22, s.height * 0.28)
      ..lineTo(s.width * 0.08, s.height * 0.02)
      ..lineTo(s.width * 0.34, s.height * 0.14)
      ..lineTo(s.width * 0.5, s.height * -0.02)
      ..lineTo(s.width * 0.66, s.height * 0.14)
      ..lineTo(s.width * 0.92, s.height * 0.02)
      ..lineTo(s.width * 0.78, s.height * 0.28)
      ..close();
    canvas.drawPath(cap, paint);
    for (final cx in [0.08, 0.5, 0.92]) {
      canvas.drawCircle(
          Offset(s.width * cx, s.height * 0.02), s.width * 0.045, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarGlyphPainter oldDelegate) =>
      oldDelegate.isBot != isBot || oldDelegate.color != color;
}
