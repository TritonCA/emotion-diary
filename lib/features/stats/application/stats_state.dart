import 'package:equatable/equatable.dart';
import '../domain/entities/mood_stats.dart';

class StatsState extends Equatable {
  const StatsState({
    this.period = StatsPeriod.week,
    this.stats = MoodStats.empty,
  });

  final StatsPeriod period;
  final MoodStats stats;

  StatsState copyWith({StatsPeriod? period, MoodStats? stats}) =>
      StatsState(period: period ?? this.period, stats: stats ?? this.stats);

  @override
  List<Object?> get props => [period, stats];
}
