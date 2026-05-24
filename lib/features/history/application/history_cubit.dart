import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/date_formatter.dart';
import '../../entries/application/entries_cubit.dart';
import '../../entries/application/entries_state.dart';
import '../../entries/domain/entities/mood_entry.dart';
import 'history_state.dart';

/// ViewModel for History. Observes the shared [EntriesCubit] and projects a
/// filtered + grouped UiModel. Owns only view concerns (filters).
class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._entries) : super(const HistoryState()) {
    _sub = _entries.stream.listen((_) => _rebuild());
    _rebuild();
  }

  final EntriesCubit _entries;
  late final StreamSubscription<EntriesState> _sub;

  void setCategory(String? id) {
    emit(id == null
        ? state.copyWith(clearCategory: true)
        : state.copyWith(categoryFilter: id));
    _rebuild();
  }

  void setPeriod(HistoryPeriod period) {
    emit(state.copyWith(period: period));
    _rebuild();
  }

  void _rebuild() {
    final all = _entries.state.entries;
    final now = DateTime.now();
    final cutoffDays = switch (state.period) {
      HistoryPeriod.last7 => 7,
      HistoryPeriod.last30 => 30,
      HistoryPeriod.last365 => 365,
      HistoryPeriod.all => null,
    };

    var filtered = all;
    if (cutoffDays != null) {
      final cutoff = now.subtract(Duration(days: cutoffDays));
      filtered = filtered.where((e) => e.timestamp.isAfter(cutoff)).toList();
    }
    if (state.categoryFilter != null) {
      filtered = filtered
          .where((e) => e.emotions.any((x) => x.categoryId == state.categoryFilter))
          .toList();
    }

    final categories = <String>{};
    for (final e in all) {
      for (final em in e.emotions) {
        categories.add(em.categoryId);
      }
    }

    emit(state.copyWith(
      groups: _group(filtered),
      categories: categories.toList()..sort(),
      isEmpty: filtered.isEmpty,
    ));
  }

  List<HistoryGroup> _group(List<MoodEntry> entries) {
    final map = <String, List<MoodEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(DateFormatter.dayLabel(e.timestamp), () => []).add(e);
    }
    return map.entries
        .map((kv) => HistoryGroup(label: kv.key, entries: kv.value))
        .toList();
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
