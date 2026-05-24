import 'package:equatable/equatable.dart';

enum StatsPeriod { week, month, year, all }

class FrequencyItem extends Equatable {
  const FrequencyItem(this.categoryId, this.percent);
  final String categoryId;
  final int percent;
  @override
  List<Object?> get props => [categoryId, percent];
}

class ContextItem extends Equatable {
  const ContextItem(this.keyword, this.count);
  final String keyword;
  final int count;
  @override
  List<Object?> get props => [keyword, count];
}

class TrendPoint extends Equatable {
  const TrendPoint(this.label, this.value);
  final String label;
  final double? value; // null = no entries that day
  @override
  List<Object?> get props => [label, value];
}

class MoodStats extends Equatable {
  const MoodStats({
    required this.totalEntries,
    required this.avgIntensity,
    required this.topCategoryId,
    required this.trend,
    required this.frequency,
    required this.context,
    required this.positivePercent,
    required this.neutralPercent,
    required this.negativePercent,
  });

  final int totalEntries;
  final double avgIntensity;
  final String? topCategoryId;
  final List<TrendPoint> trend;
  final List<FrequencyItem> frequency;
  final List<ContextItem> context;
  final int positivePercent;
  final int neutralPercent;
  final int negativePercent;

  static const empty = MoodStats(
    totalEntries: 0,
    avgIntensity: 0,
    topCategoryId: null,
    trend: [],
    frequency: [],
    context: [],
    positivePercent: 0,
    neutralPercent: 0,
    negativePercent: 0,
  );

  @override
  List<Object?> get props => [
        totalEntries,
        avgIntensity,
        topCategoryId,
        trend,
        frequency,
        context,
        positivePercent,
        neutralPercent,
        negativePercent,
      ];
}
