import '../../../entries/domain/entities/emotion_category.dart';
import '../../../entries/domain/entities/mood_entry.dart';
import '../entities/mood_stats.dart';

/// Pure aggregation of entries into [MoodStats] for a period. No I/O.
class ComputeStats {
  const ComputeStats();

  MoodStats call(List<MoodEntry> all, StatsPeriod period) {
    final now = DateTime.now();
    final entries = switch (period) {
      StatsPeriod.week => _within(all, now, 7),
      StatsPeriod.month => _within(all, now, 30),
      StatsPeriod.year => _within(all, now, 365),
      StatsPeriod.all => all,
    };
    if (entries.isEmpty) return MoodStats.empty;

    final avg = entries.map((e) => e.intensity).reduce((a, b) => a + b) /
        entries.length;

    final catCount = <String, int>{};
    for (final e in entries) {
      for (final em in e.emotions) {
        catCount.update(em.categoryId, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final totalTags = catCount.values.fold<int>(0, (a, b) => a + b);
    final topCategoryId = catCount.isEmpty
        ? null
        : (catCount.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    final frequency = (catCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(4)
        .map((e) => FrequencyItem(
            e.key, totalTags == 0 ? 0 : ((e.value / totalTags) * 100).round()))
        .toList();

    var pos = 0, neu = 0, neg = 0;
    for (final e in entries) {
      switch (e.valence) {
        case Valence.positive:
          pos++;
        case Valence.neutral:
          neu++;
        case Valence.negative:
          neg++;
      }
    }
    final total = entries.length;
    int pct(int n) => total == 0 ? 0 : ((n / total) * 100).round();

    return MoodStats(
      totalEntries: entries.length,
      avgIntensity: double.parse(avg.toStringAsFixed(1)),
      topCategoryId: topCategoryId,
      trend: _trend(entries, now),
      frequency: frequency,
      context: _context(entries),
      positivePercent: pct(pos),
      neutralPercent: pct(neu),
      negativePercent: pct(neg),
    );
  }

  List<MoodEntry> _within(List<MoodEntry> all, DateTime now, int days) {
    final cutoff = now.subtract(Duration(days: days));
    return all.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  List<TrendPoint> _trend(List<MoodEntry> entries, DateTime now) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final points = <TrendPoint>[];
    for (var i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayEntries = entries.where((e) =>
          e.timestamp.year == day.year &&
          e.timestamp.month == day.month &&
          e.timestamp.day == day.day);
      final values = dayEntries.map((e) => e.intensity).toList();
      final avg = values.isEmpty
          ? null
          : values.reduce((a, b) => a + b) / values.length;
      points.add(TrendPoint(weekdays[day.weekday - 1], avg));
    }
    return points;
  }

  static const _stop = {
    'the', 'a', 'an', 'and', 'but', 'with', 'about', 'felt', 'feeling',
    'was', 'were', 'very', 'at', 'in', 'on', 'of', 'to', 'for', 'my', 'i',
  };

  List<ContextItem> _context(List<MoodEntry> entries) {
    final counts = <String, int>{};
    for (final e in entries) {
      final words = e.trigger
          .toLowerCase()
          .split(RegExp(r'[^a-zа-я0-9]+'))
          .where((w) => w.length > 2 && !_stop.contains(w));
      for (final w in words.toSet()) {
        counts.update(w, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final list = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list
        .take(4)
        .map((e) => ContextItem(
            '${e.key[0].toUpperCase()}${e.key.substring(1)}', e.value))
        .toList();
  }
}
