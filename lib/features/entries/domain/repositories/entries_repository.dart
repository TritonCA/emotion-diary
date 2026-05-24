import '../entities/mood_entry.dart';

/// Contract for reading/writing mood entries. Implemented in data layer.
abstract interface class EntriesRepository {
  Future<List<MoodEntry>> getAll();
  Future<void> add(MoodEntry entry);
  Future<void> deleteAll();
  Future<void> replaceAll(List<MoodEntry> entries);
}
