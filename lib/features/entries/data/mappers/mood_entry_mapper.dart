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

  static MoodEntry toEntity(MoodEntryDto dto) => MoodEntry(
        id: dto.id,
        timestamp: DateTime.tryParse(dto.timestamp) ?? DateTime.now(),
        intensity: dto.intensity,
        trigger: dto.trigger,
        emotions: dto.emotions
            .map((e) => Emotion(
                  name: e.name,
                  categoryId: e.categoryId,
                  valence: _valence(e.valence),
                ))
            .toList(),
      );

  static MoodEntryDto toDto(MoodEntry e) => MoodEntryDto(
        id: e.id,
        timestamp: e.timestamp.toIso8601String(),
        intensity: e.intensity,
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
