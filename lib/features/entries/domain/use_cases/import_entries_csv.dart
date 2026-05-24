import '../repositories/entries_csv_gateway.dart';
import '../repositories/entries_repository.dart';

/// Lets the user pick a CSV and merges its rows into storage (dedup by id).
/// Returns the number of imported entries, or null if cancelled.
class ImportEntriesCsv {
  const ImportEntriesCsv(this._repo, this._csv);
  final EntriesRepository _repo;
  final EntriesCsvGateway _csv;

  Future<int?> call() async {
    final imported = await _csv.pickAndParse();
    if (imported == null) return null;
    final existing = await _repo.getAll();
    final ids = existing.map((e) => e.id).toSet();
    final merged = [...existing, ...imported.where((e) => !ids.contains(e.id))];
    await _repo.replaceAll(merged);
    return imported.length;
  }
}
