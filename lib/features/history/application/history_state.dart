import 'package:equatable/equatable.dart';
import '../../entries/domain/entities/mood_entry.dart';

enum HistoryPeriod { last7, last30, last365, all }

extension HistoryPeriodKey on HistoryPeriod {
  /// Translation key (no hard-coded English label here — let the UI translate).
  String get tKey => switch (this) {
        HistoryPeriod.last7 => 'history.period.last7',
        HistoryPeriod.last30 => 'history.period.last30',
        HistoryPeriod.last365 => 'history.period.last365',
        HistoryPeriod.all => 'history.period.all',
      };
}

/// UiModel: a day bucket ("Today"/"Yesterday"/date) with its entries.
/// `dateKey` is YYYYMMDD; the UI formats it with the current locale.
class HistoryGroup extends Equatable {
  const HistoryGroup({required this.date, required this.entries});
  final DateTime date;
  final List<MoodEntry> entries;
  @override
  List<Object?> get props => [date, entries];
}

class HistoryState extends Equatable {
  const HistoryState({
    this.groups = const [],
    this.categoryFilter,
    this.period = HistoryPeriod.last7,
    this.categories = const [],
    this.isEmpty = true,
  });

  final List<HistoryGroup> groups;
  final String? categoryFilter; // category id, null = all
  final HistoryPeriod period;
  final List<String> categories; // available category ids for the filter
  final bool isEmpty;

  HistoryState copyWith({
    List<HistoryGroup>? groups,
    String? categoryFilter,
    bool clearCategory = false,
    HistoryPeriod? period,
    List<String>? categories,
    bool? isEmpty,
  }) {
    return HistoryState(
      groups: groups ?? this.groups,
      categoryFilter: clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      period: period ?? this.period,
      categories: categories ?? this.categories,
      isEmpty: isEmpty ?? this.isEmpty,
    );
  }

  @override
  List<Object?> get props => [groups, categoryFilter, period, categories, isEmpty];
}
