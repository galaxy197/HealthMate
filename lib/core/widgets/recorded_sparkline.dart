import 'package:flutter/material.dart';

/// A small view of recorded observations in chronological order.
/// Missing observations remain gaps; no decorative example points are added.
class RecordedSparkline extends StatelessWidget {
  const RecordedSparkline({
    required this.values,
    required this.color,
    this.bars = false,
    super.key,
  });
  final List<double?> values;
  final Color color;
  final bool bars;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 42,
      width: double.infinity,
      child: CustomPaint(painter: _SparkPainter(values, color, bars)),
    ),
  );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color, this.bars);
  final List<double?> values;
  final Color color;
  final bool bars;
  @override
  void paint(Canvas canvas, Size size) {
    final known = values.whereType<double>().toList();
    if (known.isEmpty) return;
    final high = known.reduce((a, b) => a > b ? a : b);
    final low = bars ? 0.0 : known.reduce((a, b) => a < b ? a : b);
    final range = high == low ? 1.0 : high - low;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    Offset point(int i) => Offset(
      values.length <= 1
          ? size.width / 2
          : i * size.width / (values.length - 1),
      size.height - 4 - (values[i]! - low) / range * (size.height - 10),
    );
    if (bars) {
      paint.strokeWidth = 3;
      for (var i = 0; i < values.length; i++) {
        if (values[i] != null) {
          canvas.drawLine(
            Offset(point(i).dx, size.height - 2),
            point(i),
            paint,
          );
        }
      }
      return;
    }
    var i = 0;
    while (i < values.length) {
      if (values[i] == null) {
        i++;
        continue;
      }
      final first = i;
      final line = Path()..moveTo(point(i).dx, point(i).dy);
      while (i + 1 < values.length && values[i + 1] != null) {
        final a = point(i), b = point(i + 1);
        line.cubicTo(
          (a.dx + b.dx) / 2,
          a.dy,
          (a.dx + b.dx) / 2,
          b.dy,
          b.dx,
          b.dy,
        );
        i++;
      }
      if (first == i) {
        canvas.drawCircle(point(i), 2, Paint()..color = color);
      } else {
        final area = Path.from(line)
          ..lineTo(point(i).dx, size.height)
          ..lineTo(point(first).dx, size.height)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withValues(alpha: .2), color.withValues(alpha: 0)],
            ).createShader(Offset.zero & size),
        );
        canvas.drawPath(line, paint);
      }
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.values != values || old.color != color || old.bars != bars;
}
