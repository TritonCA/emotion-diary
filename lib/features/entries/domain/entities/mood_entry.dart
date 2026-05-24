import 'package:equatable/equatable.dart';
import 'emotion.dart';
import 'emotion_category.dart';

/// The core business object: one logged moment.
///
/// [intensities] is parallel to [emotions] and gives each emotion its own
/// 0..10 intensity. For backward compatibility it is always populated by
/// the mapper — legacy entries with a single overall [intensity] are
/// expanded so every emotion shares that value.
class MoodEntry extends Equatable {
  const MoodEntry({
    required this.id,
    required this.timestamp,
    required this.emotions,
    required this.intensity,
    required this.trigger,
    this.intensities = const [],
  });

  final String id;
  final DateTime timestamp;
  final List<Emotion> emotions;
  /// Overall intensity 0..10 (average of [intensities] for new entries,
  /// original single-slider value for legacy ones). Kept as the canonical
  /// number for stats trend lines and CSV interoperability.
  final int intensity;
  /// Per-emotion intensities, same length as [emotions]. Always present
  /// after going through the mapper.
  final List<int> intensities;
  final String trigger;

  /// Looks up the intensity for a specific emotion in this entry. Falls back
  /// to the overall intensity when the parallel list is empty / mismatched.
  int intensityFor(int index) {
    if (index < 0 || index >= intensities.length) return intensity;
    return intensities[index];
  }

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
  List<Object?> get props =>
      [id, timestamp, emotions, intensity, intensities, trigger];
}
