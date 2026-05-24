import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injector.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/emotion_icons.dart';
import '../application/stats_cubit.dart';
import '../application/stats_state.dart';
import '../domain/entities/mood_stats.dart';
import 'widgets/emotion_type_donut.dart';
import 'widgets/intensity_trend_chart.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StatsCubit>(
      create: (_) => sl<StatsCubit>(),
      child: const _StatsView(),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView();

  String _catLabel(String id) =>
      id.isEmpty ? '—' : '${id[0].toUpperCase()}${id.substring(1)}';

  IconData _contextIcon(String keyword) {
    final k = keyword.toLowerCase();
    if (k.contains('work')) return Icons.work_outline;
    if (k.contains('sleep') || k.contains('bed')) return Icons.bedtime_outlined;
    if (k.contains('exercise') || k.contains('gym')) return Icons.fitness_center;
    if (k.contains('meal') || k.contains('food') || k.contains('coffee')) {
      return Icons.restaurant;
    }
    return Icons.label_outline;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: const AppTopBar(title: 'Statistics'),
      body: BlocBuilder<StatsCubit, StatsState>(
        builder: (context, state) {
          final cubit = context.read<StatsCubit>();
          final s = state.stats;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              _periodSelector(c, state, cubit),
              const SizedBox(height: 40),
              _metricGrid(context, s),
              const SizedBox(height: 40),
              _sectionTitle(c, 'Intensity Trend', trailing: 'Last 7 days'),
              const SizedBox(height: 16),
              IntensityTrendChart(trend: s.trend),
              const SizedBox(height: 40),
              _sectionTitle(c, 'Frequency'),
              const SizedBox(height: 16),
              _frequency(c, s),
              const SizedBox(height: 40),
              _sectionTitle(c, 'Context'),
              const SizedBox(height: 16),
              _context(c, s),
              const SizedBox(height: 40),
              _sectionTitle(c, 'Emotion Type'),
              const SizedBox(height: 16),
              EmotionTypeDonut(stats: s),
            ],
          );
        },
      ),
    );
  }

  Widget _periodSelector(AppColors c, StatsState state, StatsCubit cubit) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final p in StatsPeriod.values) ...[
            _periodChip(c, p.label, p == state.period, () => cubit.setPeriod(p)),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _periodChip(AppColors c, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? c.primary.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: active ? c.primary : c.outline, width: active ? 1 : 0.5),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label,
            style: AppTypography.labelSm(active ? c.primary : c.onSurfaceVariant)),
      ),
    );
  }

  Widget _metricGrid(BuildContext context, MoodStats s) {
    final c = context.colors;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _metric(c, 'Total entries',
                    Text('${s.totalEntries}', style: AppTypography.headlineLg(c.primary)))),
            const SizedBox(width: 16),
            Expanded(
              child: _metric(
                c,
                'Avg Intensity',
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${s.avgIntensity}', style: AppTypography.headlineLg(c.primary)),
                    const SizedBox(width: 4),
                    Text('/10', style: AppTypography.labelSm(c.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _metric(
          c,
          'Top Emotion',
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: c.surfaceContainer, shape: BoxShape.circle),
                child: Icon(
                  s.topCategoryId == null
                      ? Icons.sentiment_neutral
                      : EmotionIcons.forCategory(s.topCategoryId!),
                  color: c.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(s.topCategoryId == null ? '—' : _catLabel(s.topCategoryId!),
                  style: AppTypography.headlineMd(c.onSurface)),
            ],
          ),
          full: true,
        ),
      ],
    );
  }

  Widget _metric(AppColors c, String label, Widget value, {bool full = false}) {
    return Container(
      height: 110,
      width: full ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.outlineVariant, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.labelSm(c.onSurfaceVariant)),
          value,
        ],
      ),
    );
  }

  Widget _sectionTitle(AppColors c, String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.headlineMd(c.onSurface)),
        if (trailing != null)
          Text(trailing, style: AppTypography.labelSm(c.onSurfaceVariant)),
      ],
    );
  }

  Widget _frequency(AppColors c, MoodStats s) {
    if (s.frequency.isEmpty) {
      return Text('No data yet', style: AppTypography.bodyMd(c.onSurfaceVariant));
    }
    final colors = [c.primary, c.secondary, c.tertiary, c.onSurfaceVariant];
    return Column(
      children: [
        for (var i = 0; i < s.frequency.length; i++) ...[
          _freqRow(c, _catLabel(s.frequency[i].categoryId),
              s.frequency[i].percent, colors[i % colors.length]),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _freqRow(AppColors c, String label, int pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.labelSm(c.onSurface)),
            Text('$pct%', style: AppTypography.labelSm(c.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            backgroundColor: c.surfaceContainer,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _context(AppColors c, MoodStats s) {
    if (s.context.isEmpty) {
      return Text('No recurring context found',
          style: AppTypography.bodyMd(c.onSurfaceVariant));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in s.context)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.outlineVariant, width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_contextIcon(item.keyword), size: 18, color: c.primary),
                const SizedBox(width: 8),
                Text('${item.keyword} (${item.count})',
                    style: AppTypography.labelSm(c.onSurface)),
              ],
            ),
          ),
      ],
    );
  }
}
