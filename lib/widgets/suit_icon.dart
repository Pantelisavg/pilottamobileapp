import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

/// Draws a suit glyph (♠♥♦♣) as vector shapes rather than a Unicode text
/// character.
///
/// Card-suit symbols (U+2660–U+2667) are outside the glyph coverage of
/// many trimmed/subset fonts — including the Roboto build bundled with
/// this app (see pubspec.yaml) — and depending on a system font having
/// them is exactly the kind of "works on my machine" risk a card game
/// can't afford on its own suit symbols. Drawing them ourselves means
/// they render identically, at any size and color, on every platform,
/// with zero font dependency.
class SuitIcon extends StatelessWidget {
  final Suit suit;
  final double size;
  final Color? color;

  const SuitIcon(this.suit, {super.key, this.size = 16, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SuitPainter(suit, color ?? DefaultTextStyle.of(context).style.color ?? Colors.black),
      ),
    );
  }
}

class _SuitPainter extends CustomPainter {
  final Suit suit;
  final Color color;

  _SuitPainter(this.suit, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    switch (suit) {
      case Suit.diamonds:
        _paintDiamond(canvas, size, paint);
      case Suit.hearts:
        _paintHeart(canvas, size, paint);
      case Suit.spades:
        _paintSpade(canvas, size, paint);
      case Suit.clubs:
        _paintClub(canvas, size, paint);
    }
  }

  void _paintDiamond(Canvas canvas, Size s, Paint paint) {
    final path = Path()
      ..moveTo(s.width * 0.5, 0)
      ..lineTo(s.width, s.height * 0.5)
      ..lineTo(s.width * 0.5, s.height)
      ..lineTo(0, s.height * 0.5)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _heartLobes(Path path, Size s) {
    // Two rounded lobes meeting at a bottom point — drawn with cubic
    // Beziers rather than circles so it reads as a heart, not two dots.
    path.moveTo(s.width * 0.5, s.height * 0.92);
    path.cubicTo(
      -s.width * 0.15, s.height * 0.55,
      s.width * 0.08, -s.height * 0.05,
      s.width * 0.5, s.height * 0.28,
    );
    path.cubicTo(
      s.width * 0.92, -s.height * 0.05,
      s.width * 1.15, s.height * 0.55,
      s.width * 0.5, s.height * 0.92,
    );
    path.close();
  }

  void _paintHeart(Canvas canvas, Size s, Paint paint) {
    final path = Path();
    _heartLobes(path, s);
    canvas.drawPath(path, paint);
  }

  void _paintSpade(Canvas canvas, Size s, Paint paint) {
    canvas.save();
    // A spade is an upside-down heart with a triangular stem/base added.
    canvas.translate(0, s.height);
    canvas.scale(1, -1);
    final lobes = Path();
    _heartLobes(lobes, Size(s.width, s.height * 0.78));
    canvas.drawPath(lobes, paint);
    canvas.restore();

    final stem = Path()
      ..moveTo(s.width * 0.5, s.height * 0.52)
      ..lineTo(s.width * 0.72, s.height * 0.98)
      ..lineTo(s.width * 0.28, s.height * 0.98)
      ..close();
    canvas.drawPath(stem, paint);
  }

  void _paintClub(Canvas canvas, Size s, Paint paint) {
    final r = s.width * 0.28;
    canvas.drawCircle(Offset(s.width * 0.5, s.height * 0.32), r, paint);
    canvas.drawCircle(Offset(s.width * 0.26, s.height * 0.62), r, paint);
    canvas.drawCircle(Offset(s.width * 0.74, s.height * 0.62), r, paint);
    final stem = Path()
      ..moveTo(s.width * 0.5, s.height * 0.48)
      ..lineTo(s.width * 0.68, s.height * 0.98)
      ..lineTo(s.width * 0.32, s.height * 0.98)
      ..close();
    canvas.drawPath(stem, paint);
  }

  @override
  bool shouldRepaint(covariant _SuitPainter oldDelegate) =>
      oldDelegate.suit != suit || oldDelegate.color != color;
}
