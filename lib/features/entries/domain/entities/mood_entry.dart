import 'package:equatable/equatable.dart';
import 'emotion.dart';
import 'emotion_category.dart';

/// The core business object: one logged moment.
class MoodEntry extends Equatable {
  const MoodEntry({
    required this.id,
    required this.timestamp,
    required this.emotions,
    required this.intensity,
    required this.trigger,
  });

  final String id;
  final DateTime timestamp;
  final List<Emotion> emotions;
  final int intensity; // 0..10
  final String trigger;

  /// Dominant valence of the entry (used by Stats "Emotion Type").
  Valence get valence {
    if (emotions.isEmpty) return Valence.neutral;
    var pos = 0, neg = 0;
    for (final e in emotions) {
      if (e.valence == Valence.positive) pos++;
      if (e.valence == Valence.negative) neg++;
    }
    if (pos > neg) return Valence.positive;
    if (neg > pos) return Valence.negative;
    return Valence.neutral;
  }

  @override
  List<Object?> get props => [id, timestamp, emotions, intensity, trigger];
}
