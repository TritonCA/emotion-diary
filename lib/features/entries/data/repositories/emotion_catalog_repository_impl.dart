import '../../domain/entities/emotion_category.dart';
import '../../domain/repositories/emotion_catalog_repository.dart';
import '../datasources/emotion_catalog_data_source.dart';

class EmotionCatalogRepositoryImpl implements EmotionCatalogRepository {
  EmotionCatalogRepositoryImpl(this._ds);
  final EmotionCatalogDataSource _ds;

  @override
  Future<List<EmotionCategory>> getCategories() => _ds.getCategories();

  @override
  Future<void> addCustomEmotion(String categoryId, String emotion) =>
      _ds.addCustom(categoryId, emotion);
}
