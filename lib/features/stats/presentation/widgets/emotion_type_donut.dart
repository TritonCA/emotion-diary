import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/mood_stats.dart';

/// Donut of positive/neutral/negative share + legend (mockup "Emotion Type").
class EmotionTypeDonut extends StatelessWidget {
  const EmotionTypeDonut({super.key, required this.stats});
  final MoodStats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final focus = stats.positivePercent >= stats.negativePercent &&
            stats.positivePercent >= stats.neutralPercent
        ? 'Positive'
        : (stats.negativePercent >= stats.neutralPercent ? 'Negative' : 'Neutral');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.outlineVariant, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _DonutPainter(
                positive: stats.positivePercent.toDouble(),
                neutral: stats.neutralPercent.toDouble(),
                negative: stats.negativePercent.toDouble(),
                positiveColor: c.primary,
                neutralColor: c.secondary,
                negativeColor: c.onSurfaceVariant,
                track: c.outlineVariant,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(focus, style: AppTypography.headlineMd(c.primary)),
                    Text('Focus', style: AppTypography.labelSm(c.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _legend(c, 'Positive', stats.positivePercent, c.primary),
          _legend(c, 'Neutral', stats.neutralPercent, c.secondary),
          _legend(c, 'Negative', stats.negativePercent, c.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _legend(AppColors c, String label, int pct, Color dot) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 12, height: 12,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 16),
          Text(label, style: AppTypography.bodyMd(c.onSurface)),
          const Spacer(),
          Text('$pct%',
              style: AppTypography.labelSm(c.onSurface)
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.positive,
    required this.neutral,
    required this.negative,
    required this.positiveColor,
    required this.neutralColor,
    required this.negativeColor,
    required this.track,
  });

  final double positive, neutral, negative;
  final Color positiveColor, neutralColor, negativeColor, track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
        center: size.center(Offset.zero), radius: size.width / 2 - 8);
    const stroke = 14.0;
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 6.28318, false, base);

    var start = -1.5708; // -90deg
    void arc(double pct, Color color) {
      if (pct <= 0) return;
      final sweep = (pct / 100) * 6.28318;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }

    arc(positive, positiveColor);
    arc(neutral, neutralColor);
    arc(negative, negativeColor);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.positive != positive ||
      old.neutral != neutral ||
      old.negative != negative;
}
