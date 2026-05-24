import '../repositories/entries_repository.dart';

/// Removes a single entry by id.
class DeleteEntry {
  const DeleteEntry(this._repo);
  final EntriesRepository _repo;

  Future<void> call(String id) => _repo.delete(id);
}
