import 'package:equatable/equatable.dart';
import '../../entries/domain/entities/mood_entry.dart';

enum HistoryPeriod { last7, last30, last365, all }

extension HistoryPeriodLabel on HistoryPeriod {
  String get label => switch (this) {
        HistoryPeriod.last7 => 'Last 7 days',
        HistoryPeriod.last30 => 'Last 30 days',
        HistoryPeriod.last365 => 'Last year',
        HistoryPeriod.all => 'All time',
      };
}

/// UiModel: a day bucket ("Today"/"Yesterday"/date) with its entries.
class HistoryGroup extends Equatable {
  const HistoryGroup({required this.label, required this.entries});
  final String label;
  final List<MoodEntry> entries;
  @override
  List<Object?> get props => [label, entries];
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
