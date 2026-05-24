import '../entities/mood_entry.dart';
import '../repositories/entries_repository.dart';

/// Persists changes to an existing entry. Same shape as [SaveEntry] but
/// addresses an existing id (insert-or-update via the repository).
class UpdateEntry {
  const UpdateEntry(this._repo);
  final EntriesRepository _repo;

  Future<void> call(MoodEntry entry) => _repo.update(entry);
}
