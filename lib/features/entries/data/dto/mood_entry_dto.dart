/// Wire/storage shape of an entry. Kept separate from the domain [MoodEntry]
/// per ARCH rule "domain models != DTO".
class MoodEntryDto {
  MoodEntryDto({
    required this.id,
    required this.timestamp,
    required this.emotions,
    required this.intensity,
    required this.trigger,
  });

  final String id;
  final String timestamp; // ISO-8601
  final List<EmotionDto> emotions;
  final int intensity;
  final String trigger;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'intensity': intensity,
        'trigger': trigger,
        'emotions': emotions.map((e) => e.toJson()).toList(),
      };

  factory MoodEntryDto.fromJson(Map<String, dynamic> json) => MoodEntryDto(
        id: json['id'] as String,
        timestamp: json['timestamp'] as String,
        intensity: (json['intensity'] as num).toInt(),
        trigger: (json['trigger'] as String?) ?? '',
        emotions: ((json['emotions'] as List?) ?? const [])
            .map((e) => EmotionDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class EmotionDto {
  EmotionDto({required this.name, required this.categoryId, required this.valence});
  final String name;
  final String categoryId;
  final String valence; // 'positive' | 'neutral' | 'negative'

  Map<String, dynamic> toJson() =>
      {'name': name, 'categoryId': categoryId, 'valence': valence};

  factory EmotionDto.fromJson(Map<String, dynamic> json) => EmotionDto(
        name: json['name'] as String,
        categoryId: (json['categoryId'] as String?) ?? '',
        valence: (json['valence'] as String?) ?? 'neutral',
      );
}
