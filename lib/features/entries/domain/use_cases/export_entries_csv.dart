import '../repositories/entries_csv_gateway.dart';
import '../repositories/entries_repository.dart';

/// Builds a CSV from all entries and hands it to the gateway to share.
class ExportEntriesCsv {
  const ExportEntriesCsv(this._repo, this._csv);
  final EntriesRepository _repo;
  final EntriesCsvGateway _csv;

  Future<void> call() async {
    final entries = await _repo.getAll();
    await _csv.exportAndShare(entries);
  }
}
