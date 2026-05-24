import '../../domain/entities/emotion.dart';
import '../../domain/entities/emotion_category.dart';
import '../../domain/entities/mood_entry.dart';
import '../dto/mood_entry_dto.dart';

/// DTO <-> Entity translation. The only place that knows both shapes.
class MoodEntryMapper {
  const MoodEntryMapper._();

  static Valence _valence(String s) => switch (s) {
        'positive' => Valence.positive,
        'negative' => Valence.negative,
        _ => Valence.neutral,
      };

  static String _valenceStr(Valence v) => v.name;

  static MoodEntry toEntity(MoodEntryDto dto) {
    final emotions = dto.emotions
        .map((e) => Emotion(
              name: e.name,
              categoryId: e.categoryId,
              valence: _valence(e.valence),
            ))
        .toList();
    // Backward compat: when storage doesn't have a per-emotion intensities
    // array, replicate the overall intensity across all emotions so domain
    // code can rely on the parallel list always being present.
    final intensities = (dto.intensities != null &&
            dto.intensities!.length == emotions.length)
        ? List<int>.from(dto.intensities!)
        : List<int>.filled(emotions.length, dto.intensity);
    return MoodEntry(
      id: dto.id,
      timestamp: DateTime.tryParse(dto.timestamp) ?? DateTime.now(),
      intensity: dto.intensity,
      intensities: intensities,
      trigger: dto.trigger,
      emotions: emotions,
    );
  }

  static MoodEntryDto toDto(MoodEntry e) => MoodEntryDto(
        id: e.id,
        timestamp: e.timestamp.toIso8601String(),
        intensity: e.intensity,
        intensities: e.intensities.isEmpty ? null : List<int>.from(e.intensities),
        trigger: e.trigger,
        emotions: e.emotions
            .map((x) => EmotionDto(
                  name: x.name,
                  categoryId: x.categoryId,
                  valence: _valenceStr(x.valence),
                ))
            .toList(),
      );
}
