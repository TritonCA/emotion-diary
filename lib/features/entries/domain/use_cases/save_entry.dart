import '../entities/mood_entry.dart';
import '../repositories/entries_repository.dart';

/// Persists a new entry. Single place where "save" business intent lives.
class SaveEntry {
  const SaveEntry(this._repo);
  final EntriesRepository _repo;

  Future<void> call(MoodEntry entry) => _repo.add(entry);
}
