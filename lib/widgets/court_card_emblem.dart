import 'package:flutter/material.dart';
import 'package:pilotta_engine/pilotta_engine.dart';

/// A small ornamental glyph distinguishing a face card's rank — a crown
/// for King, a rosette for Queen, a plume for Jack — drawn the same
/// CustomPainter way as [SuitIcon] rather than an image, so the "premium"
/// look stays asset-free. Returns nothing for a non-face rank; callers
/// only need to check [CourtCardEmblem.appliesTo] if they want to skip
/// laying out space for it.
class CourtCardEmblem extends StatelessWidget {
  final Rank rank;
  final double size;
  final Color color;

  const CourtCardEmblem(
      {super.key, required this.rank, required this.color, this.size = 16});

  static bool appliesTo(Rank rank) =>
      rank == Rank.jack || rank == Rank.queen || rank == Rank.king;

  @override
  Widget build(BuildContext context) {
    if (!appliesTo(rank)) return const SizedBox.shrink();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CourtEmblemPainter(rank, color)),
    );
  }
}

class _CourtEmblemPainter extends CustomPainter {
  final Rank rank;
  final Color color;
  _CourtEmblemPainter(this.rank, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    switch (rank) {
      case Rank.king:
        _paintCrown(canvas, size, paint);
      case Rank.queen:
        _paintRosette(canvas, size, paint);
      case Rank.jack:
        _paintPlume(canvas, size, paint);
      default:
        break;
    }
  }

  void _paintCrown(Canvas canvas, Size s, Paint paint) {
    final path = Path()
      ..moveTo(s.width * 0.08, s.height * 0.95)
      ..lineTo(s.width * 0.08, s.height * 0.45)
      ..lineTo(s.width * 0.28, s.height * 0.65)
      ..lineTo(s.width * 0.5, s.height * 0.15)
      ..lineTo(s.width * 0.72, s.height * 0.65)
      ..lineTo(s.width * 0.92, s.height * 0.45)
      ..lineTo(s.width * 0.92, s.height * 0.95)
      ..close();
    canvas.drawPath(path, paint);
    // Jewels along the base band.
    for (final cx in [0.28, 0.5, 0.72]) {
      canvas.drawCircle(
          Offset(s.width * cx, s.height * 0.8), s.width * 0.045, paint);
    }
  }

  void _paintRosette(Canvas canvas, Size s, Paint paint) {
    final center = Offset(s.width * 0.5, s.height * 0.5);
    final outerR = s.width * 0.46;
    final innerR = s.width * 0.2;
    const petals = 5;
    final path = Path();
    for (var i = 0; i < petals; i++) {
      final angle = (i / petals) * 2 * 3.14159 - 3.14159 / 2;
      final tip = center + Offset.fromDirection(angle, outerR);
      final leftAngle = angle - 3.14159 / petals;
      final rightAngle = angle + 3.14159 / petals;
      final left = center + Offset.fromDirection(leftAngle, innerR);
      final right = center + Offset.fromDirection(rightAngle, innerR);
      if (i == 0) {
        path.moveTo(left.dx, left.dy);
      } else {
        path.lineTo(left.dx, left.dy);
      }
      path.quadraticBezierTo(tip.dx, tip.dy, right.dx, right.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(center, innerR * 0.55, paint);
  }

  void _paintPlume(Canvas canvas, Size s, Paint paint) {
    canvas.save();
    canvas.translate(s.width * 0.5, s.height * 0.5);
    canvas.rotate(-0.55);
    canvas.translate(-s.width * 0.5, -s.height * 0.5);

    final spine = Path()
      ..moveTo(s.width * 0.5, s.height * 0.02)
      ..cubicTo(s.width * 0.75, s.height * 0.25, s.width * 0.65,
          s.height * 0.75, s.width * 0.5, s.height * 0.98)
      ..cubicTo(s.width * 0.35, s.height * 0.75, s.width * 0.25,
          s.height * 0.25, s.width * 0.5, s.height * 0.02)
      ..close();
    canvas.drawPath(spine, paint);

    final barbStroke = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * 0.035;
    for (final t in [0.3, 0.5, 0.7]) {
      final y = s.height * t;
      canvas.drawLine(Offset(s.width * 0.5, y),
          Offset(s.width * 0.28, y - s.height * 0.08), barbStroke);
      canvas.drawLine(Offset(s.width * 0.5, y),
          Offset(s.width * 0.72, y - s.height * 0.08), barbStroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CourtEmblemPainter oldDelegate) =>
      oldDelegate.rank != rank || oldDelegate.color != color;
}
