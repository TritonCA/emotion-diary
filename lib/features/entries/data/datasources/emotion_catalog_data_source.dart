import 'dart:convert';
import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/emotion_category.dart';

/// Static emotion taxonomy matching the bottom-sheet grid in the mockups,
/// merged with any user-added custom emotions persisted in storage.
class EmotionCatalogDataSource {
  EmotionCatalogDataSource(this._store);
  final KeyValueStore _store;

  static const _customKey = 'custom_emotions.v1';

  static const List<EmotionCategory> _base = [
    EmotionCategory(id: 'joy', name: 'Joy', iconName: 'joy', valence: Valence.positive,
        emotions: ['Happy', 'Excited', 'Grateful', 'Content', 'Proud', 'Hopeful']),
    EmotionCategory(id: 'calm', name: 'Calm', iconName: 'calm', valence: Valence.positive,
        emotions: ['Relaxed', 'Peaceful', 'Steady', 'Safe', 'Relieved']),
    EmotionCategory(id: 'love', name: 'Love', iconName: 'love', valence: Valence.positive,
        emotions: ['Tender', 'Affectionate', 'Warm', 'Trusting', 'Close']),
    EmotionCategory(id: 'interest', name: 'Interest', iconName: 'interest', valence: Valence.positive,
        emotions: ['Curious', 'Engaged', 'Inspired', 'Focused', 'Intrigued']),
    EmotionCategory(id: 'sadness', name: 'Sadness', iconName: 'sadness', valence: Valence.negative,
        emotions: ['Down', 'Lonely', 'Disappointed', 'Hopeless', 'Empty', 'Regretful']),
    EmotionCategory(id: 'anger', name: 'Anger', iconName: 'anger', valence: Valence.negative,
        emotions: ['Annoyed', 'Furious', 'Bitter', 'Frustrated', 'Resentful']),
    EmotionCategory(id: 'fear', name: 'Fear', iconName: 'fear', valence: Valence.negative,
        emotions: ['Anxious', 'Worried', 'Scared', 'Nervous', 'Insecure', 'Panicked']),
    EmotionCategory(id: 'surprise', name: 'Surprise', iconName: 'surprise', valence: Valence.neutral,
        emotions: ['Amazed', 'Confused', 'Startled', 'Shocked']),
    EmotionCategory(id: 'tiredness', name: 'Tiredness', iconName: 'tiredness', valence: Valence.negative,
        emotions: ['Exhausted', 'Bored', 'Apathetic', 'Drained', 'Burned out']),
  ];

  Future<List<EmotionCategory>> getCategories() async {
    final raw = await _store.getString(_customKey);
    final custom = <String, List<String>>{};
    if (raw != null && raw.isNotEmpty) {
      (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) {
        custom[k] = (v as List).cast<String>();
      });
    }
    return _base.map((cat) {
      final extra = custom[cat.id] ?? const [];
      return extra.isEmpty ? cat : cat.copyWith(emotions: [...cat.emotions, ...extra]);
    }).toList();
  }

  Future<void> addCustom(String categoryId, String emotion) async {
    final raw = await _store.getString(_customKey);
    final map = <String, List<String>>{};
    if (raw != null && raw.isNotEmpty) {
      (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) {
        map[k] = (v as List).cast<String>();
      });
    }
    final list = map[categoryId] ?? <String>[];
    if (!list.contains(emotion)) list.add(emotion);
    map[categoryId] = list;
    await _store.setString(_customKey, jsonEncode(map));
  }
}
