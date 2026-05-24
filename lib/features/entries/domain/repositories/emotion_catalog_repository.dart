import '../entities/emotion_category.dart';

/// Contract for the emotion taxonomy (categories + sub-emotions),
/// including user overrides (rename / hide) and additions.
abstract interface class EmotionCatalogRepository {
  Future<List<EmotionCategory>> getCategories();
  Future<void> addCustomEmotion(String categoryId, String emotion);
  Future<void> renameEmotion(String categoryId, String oldName, String newName);
  Future<void> removeEmotion(String categoryId, String emotion);
}
