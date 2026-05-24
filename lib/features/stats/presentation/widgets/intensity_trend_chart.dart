import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/mood_stats.dart';

/// Smooth line + gradient fill of average intensity over the last 7 days,
/// matching the SVG path in the mockup.
class IntensityTrendChart extends StatelessWidget {
  const IntensityTrendChart({super.key, required this.trend});
  final List<TrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 224,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.outlineVariant, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _TrendPainter(trend, c.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final p in trend)
                Text(p.label,
                    style: AppTypography.labelSm(c.onSurfaceVariant)
                        .copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.trend, this.color);
  final List<TrendPoint> trend;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final values = trend.map((p) => p.value).toList();
    final hasAny = values.any((v) => v != null);
    if (!hasAny || trend.length < 2) return;

    // Carry-forward to fill gaps so the line is continuous.
    double last = values.firstWhere((v) => v != null, orElse: () => 0.0)!;
    final pts = <Offset>[];
    for (var i = 0; i < trend.length; i++) {
      final v = values[i] ?? last;
      last = v;
      final x = size.width * (i / (trend.length - 1));
      final y = size.height * (1 - (v / 10).clamp(0.0, 1.0));
      pts.add(Offset(x, y));
    }

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.3), color.withOpacity(0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    final dot = Paint()..color = color;
    for (final p in [pts.first, pts[pts.length ~/ 2], pts.last]) {
      canvas.drawCircle(p, 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.trend != trend || old.color != color;
}
