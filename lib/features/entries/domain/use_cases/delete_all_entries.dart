import '../repositories/entries_repository.dart';

class DeleteAllEntries {
  const DeleteAllEntries(this._repo);
  final EntriesRepository _repo;

  Future<void> call() => _repo.deleteAll();
}
