import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../entries/application/entries_cubit.dart';
import '../../entries/application/entries_state.dart';
import '../domain/entities/mood_stats.dart';
import '../domain/use_cases/compute_stats.dart';
import 'stats_state.dart';

/// ViewModel for Statistics. Observes the shared [EntriesCubit] and recomputes
/// [MoodStats] via the pure [ComputeStats] use case. Supports an optional
/// category filter that narrows the input entries before aggregation.
class StatsCubit extends Cubit<StatsState> {
  StatsCubit(this._entries, this._compute) : super(const StatsState()) {
    _sub = _entries.stream.listen((_) => _recompute());
    _recompute();
  }

  final EntriesCubit _entries;
  final ComputeStats _compute;
  late final StreamSubscription<EntriesState> _sub;

  void setPeriod(StatsPeriod period) {
    emit(state.copyWith(period: period));
    _recompute();
  }

  void setCategoryFilter(String? id) {
    emit(id == null
        ? state.copyWith(clearFilter: true)
        : state.copyWith(categoryFilter: id));
    _recompute();
  }

  void _recompute() {
    final all = _entries.state.entries;
    final categories = <String>{
      for (final e in all) ...e.emotions.map((x) => x.categoryId),
    }..removeWhere((id) => id.isEmpty);
    final available = categories.toList()..sort();

    final filter = state.categoryFilter;
    final filtered = filter == null
        ? all
        : all
            .where((e) => e.emotions.any((x) => x.categoryId == filter))
            .toList();

    final stats = _compute(filtered, state.period);
    emit(state.copyWith(
      stats: stats,
      availableCategories: available,
      // If the active filter no longer matches anything (e.g. user deleted
      // all entries of that category) reset it so the page isn't stuck.
      clearFilter: filter != null && !categories.contains(filter),
    ));
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
