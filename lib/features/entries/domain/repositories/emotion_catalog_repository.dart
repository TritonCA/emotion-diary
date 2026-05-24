import '../entities/emotion_category.dart';

/// Contract for the emotion taxonomy (categories + sub-emotions),
/// including user-added custom emotions.
abstract interface class EmotionCatalogRepository {
  Future<List<EmotionCategory>> getCategories();
  Future<void> addCustomEmotion(String categoryId, String emotion);
}
