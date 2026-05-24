import 'package:equatable/equatable.dart';
import '../domain/entities/mood_stats.dart';

extension StatsPeriodKey on StatsPeriod {
  String get tKey => switch (this) {
        StatsPeriod.week => 'stats.period.week',
        StatsPeriod.month => 'stats.period.month',
        StatsPeriod.year => 'stats.period.year',
        StatsPeriod.all => 'stats.period.all',
      };
}

class StatsState extends Equatable {
  const StatsState({
    this.period = StatsPeriod.week,
    this.categoryFilter,
    this.availableCategories = const [],
    this.stats = MoodStats.empty,
  });

  final StatsPeriod period;
  /// Active category filter (null = all categories).
  final String? categoryFilter;
  /// All category ids the user currently has data for — drives the picker.
  final List<String> availableCategories;
  final MoodStats stats;

  StatsState copyWith({
    StatsPeriod? period,
    String? categoryFilter,
    bool clearFilter = false,
    List<String>? availableCategories,
    MoodStats? stats,
  }) =>
      StatsState(
        period: period ?? this.period,
        categoryFilter:
            clearFilter ? null : (categoryFilter ?? this.categoryFilter),
        availableCategories: availableCategories ?? this.availableCategories,
        stats: stats ?? this.stats,
      );

  @override
  List<Object?> get props =>
      [period, categoryFilter, availableCategories, stats];
}
