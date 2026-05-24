import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injector.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/emotion_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../record/presentation/record_page.dart';
import '../../settings/application/settings_cubit.dart';
import '../application/history_cubit.dart';
import '../application/history_state.dart';
import 'widgets/entry_card.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryCubit>(
      create: (_) => sl<HistoryCubit>(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final locale = context.watch<SettingsCubit>().state.locale;
    return Scaffold(
      appBar: AppTopBar(title: s.t('history.title')),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          final cubit = context.read<HistoryCubit>();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
            children: [
              Row(
                children: [
                  _categoryChip(context, state, cubit),
                  const SizedBox(width: 8),
                  _periodChip(context, state, cubit),
                ],
              ),
              const SizedBox(height: 40),
              if (state.isEmpty)
                _emptyState(c, s)
              else
                for (final group in state.groups) ...[
                  Text(
                      DateFormatter.dayLabel(group.date,
                              locale: locale,
                              todayLabel: s.t('history.day.today'),
                              yesterdayLabel: s.t('history.day.yesterday'))
                          .toUpperCase(),
                      style: AppTypography.labelCaps(c.outline)
                          .copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  for (final entry in group.entries) ...[
                    EntryCard(
                      entry: entry,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RecordPage(existing: entry),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 24),
                ],
            ],
          );
        },
      ),
    );
  }

  Widget _categoryChip(BuildContext context, HistoryState state, HistoryCubit cubit) {
    final c = context.colors;
    final s = context.s;
    final locale = context.watch<SettingsCubit>().state.locale;
    final selected = state.categoryFilter != null;
    String label(String? id) {
      if (id == null) return s.t('history.all_categories');
      if (id.isEmpty) return s.t('history.uncategorized');
      return EmotionTranslations.category(locale, id);
    }

    return PopupMenuButton<String?>(
      onSelected: (v) => cubit.setCategory(v == '__all__' ? null : v),
      color: c.surfaceContainer,
      itemBuilder: (_) => [
        PopupMenuItem(value: '__all__', child: Text(label(null))),
        for (final id in state.categories)
          PopupMenuItem(value: id, child: Text(label(id))),
      ],
      child: _chip(c, label: label(state.categoryFilter), active: selected),
    );
  }

  Widget _periodChip(BuildContext context, HistoryState state, HistoryCubit cubit) {
    final c = context.colors;
    final s = context.s;
    return PopupMenuButton<HistoryPeriod>(
      onSelected: cubit.setPeriod,
      color: c.surfaceContainer,
      itemBuilder: (_) => [
        for (final p in HistoryPeriod.values)
          PopupMenuItem(value: p, child: Text(s.t(p.tKey))),
      ],
      child: _chip(c, label: s.t(state.period.tKey), active: false),
    );
  }

  Widget _chip(AppColors c, {required String label, required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? c.primary : c.surface,
        border: Border.all(color: active ? c.primary : c.outlineVariant, width: 0.5),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: AppTypography.labelSm(active ? c.onPrimary : c.onSurfaceVariant)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down,
              size: 16, color: active ? c.onPrimary : c.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _emptyState(AppColors c, AppStrings s) {
    return Opacity(
      opacity: 0.4,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.surfaceContainer,
              border: Border.all(color: c.outlineVariant, width: 0.5),
            ),
            child: Icon(Icons.edit_note, size: 48, color: c.primary),
          ),
          const SizedBox(height: 16),
          Text(s.t('history.empty'), style: AppTypography.bodyLg(c.outline)),
        ],
      ),
    );
  }
}
