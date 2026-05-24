import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injector.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/emotion_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/emotion_icons.dart';
import '../../settings/application/settings_cubit.dart';
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

  IconData _contextIcon(String keyword) {
    final k = keyword.toLowerCase();
    if (k.contains('work') || k.contains('работ')) return Icons.work_outline;
    if (k.contains('sleep') || k.contains('bed') || k.contains('сон')) {
      return Icons.bedtime_outlined;
    }
    if (k.contains('exercise') || k.contains('gym') || k.contains('спорт')) {
      return Icons.fitness_center;
    }
    if (k.contains('meal') ||
        k.contains('food') ||
        k.contains('coffee') ||
        k.contains('еда') ||
        k.contains('кофе')) {
      return Icons.restaurant;
    }
    return Icons.label_outline;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Scaffold(
      appBar: AppTopBar(title: s.t('stats.title')),
      body: BlocBuilder<StatsCubit, StatsState>(
        builder: (context, state) {
          final cubit = context.read<StatsCubit>();
          final st = state.stats;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              _periodSelector(context, c, state, cubit),
              const SizedBox(height: 12),
              _categoryFilter(context, c, state, cubit),
              const SizedBox(height: 32),
              _metricGrid(context, st),
              const SizedBox(height: 40),
              _sectionTitle(c, s.t('stats.intensity_trend'),
                  trailing: s.t('stats.last_7_days')),
              const SizedBox(height: 16),
              IntensityTrendChart(trend: st.trend),
              const SizedBox(height: 40),
              _sectionTitle(c, s.t('stats.frequency')),
              const SizedBox(height: 16),
              _frequency(context, c, st),
              const SizedBox(height: 40),
              _sectionTitle(c, s.t('stats.context')),
              const SizedBox(height: 16),
              _context(c, s, st),
              const SizedBox(height: 40),
              _sectionTitle(c, s.t('stats.emotion_type')),
              const SizedBox(height: 16),
              EmotionTypeDonut(stats: st),
            ],
          );
        },
      ),
    );
  }

  Widget _periodSelector(
      BuildContext context, AppColors c, StatsState state, StatsCubit cubit) {
    final s = context.s;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final p in StatsPeriod.values) ...[
            _periodChip(c, s.t(p.tKey), p == state.period, () => cubit.setPeriod(p)),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _categoryFilter(
      BuildContext context, AppColors c, StatsState state, StatsCubit cubit) {
    final s = context.s;
    final locale = context.watch<SettingsCubit>().state.locale;
    String label(String? id) {
      if (id == null) return s.t('history.all_categories');
      return EmotionTranslations.category(locale, id);
    }

    if (state.availableCategories.isEmpty) return const SizedBox.shrink();
    final selected = state.categoryFilter != null;
    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<String?>(
        onSelected: (v) => cubit.setCategoryFilter(v == '__all__' ? null : v),
        color: c.surfaceContainer,
        itemBuilder: (_) => [
          PopupMenuItem(value: '__all__', child: Text(label(null))),
          for (final id in state.availableCategories)
            PopupMenuItem(value: id, child: Text(label(id))),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? c.primary.withOpacity(0.10) : c.surface,
            border: Border.all(
                color: selected ? c.primary : c.outlineVariant,
                width: selected ? 1 : 0.5),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list,
                  size: 16, color: selected ? c.primary : c.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(label(state.categoryFilter),
                  style: AppTypography.labelSm(
                      selected ? c.primary : c.onSurfaceVariant)),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down,
                  size: 16, color: selected ? c.primary : c.onSurfaceVariant),
            ],
          ),
        ),
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

  Widget _metricGrid(BuildContext context, MoodStats st) {
    final c = context.colors;
    final s = context.s;
    final locale = context.watch<SettingsCubit>().state.locale;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _metric(c, s.t('stats.total_entries'),
                    Text('${st.totalEntries}', style: AppTypography.headlineLg(c.primary)))),
            const SizedBox(width: 16),
            Expanded(
              child: _metric(
                c,
                s.t('stats.avg_intensity'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${st.avgIntensity}', style: AppTypography.headlineLg(c.primary)),
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
          s.t('stats.top_emotion'),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: c.surfaceContainer, shape: BoxShape.circle),
                child: Icon(
                  st.topCategoryId == null
                      ? Icons.sentiment_neutral
                      : EmotionIcons.forCategory(st.topCategoryId!),
                  color: c.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                  st.topCategoryId == null
                      ? '—'
                      : EmotionTranslations.category(locale, st.topCategoryId!),
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

  Widget _frequency(BuildContext context, AppColors c, MoodStats st) {
    final s = context.s;
    final locale = context.watch<SettingsCubit>().state.locale;
    if (st.frequency.isEmpty) {
      return Text(s.t('stats.no_data'),
          style: AppTypography.bodyMd(c.onSurfaceVariant));
    }
    final colors = [c.primary, c.secondary, c.tertiary, c.onSurfaceVariant];
    return Column(
      children: [
        for (var i = 0; i < st.frequency.length; i++) ...[
          _freqRow(
              c,
              EmotionTranslations.category(locale, st.frequency[i].categoryId),
              st.frequency[i].percent,
              colors[i % colors.length]),
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

  Widget _context(AppColors c, AppStrings s, MoodStats st) {
    if (st.context.isEmpty) {
      return Text(s.t('stats.no_context'),
          style: AppTypography.bodyMd(c.onSurfaceVariant));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in st.context)
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
