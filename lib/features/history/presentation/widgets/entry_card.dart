import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../entries/domain/entities/emotion_category.dart';
import '../../../entries/domain/entities/mood_entry.dart';

/// History list card: time, emotion pills, intensity bar, trigger quote.
class EntryCard extends StatelessWidget {
  const EntryCard({super.key, required this.entry});
  final MoodEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isNegative = entry.valence == Valence.negative;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.outlineVariant, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormatter.time(entry.timestamp),
                        style: AppTypography.labelSm(c.outline)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in entry.emotions) _pill(c, e.name, e.valence),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Intensity ${entry.intensity}',
                      style: AppTypography.labelSm(c.outline)),
                  const SizedBox(height: 6),
                  _intensityBar(c, entry.intensity),
                ],
              ),
            ],
          ),
          if (entry.trigger.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isNegative ? c.outlineVariant : c.primary.withOpacity(0.4),
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                '"${entry.trigger}"',
                style: AppTypography.bodyMd(c.onSurfaceVariant)
                    .copyWith(fontStyle: isNegative ? FontStyle.normal : FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(AppColors c, String name, Valence v) {
    final accent = v == Valence.negative ? c.outline : c.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        border: Border.all(color: accent.withOpacity(0.4), width: 0.5),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(name, style: AppTypography.labelSm(accent)),
    );
  }

  Widget _intensityBar(AppColors c, int intensity) {
    return Container(
      width: 64,
      height: 4,
      decoration: BoxDecoration(
        color: c.outlineVariant,
        borderRadius: BorderRadius.circular(99),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (intensity / 10).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}
