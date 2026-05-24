import '../entities/mood_entry.dart';

/// Domain port for CSV side effects. The concrete implementation (file system,
/// share sheet, file picker) lives in data, so domain stays infra-free.
abstract interface class EntriesCsvGateway {
  Future<void> exportAndShare(List<MoodEntry> entries);

  /// Returns parsed entries, or null if the user cancelled.
  Future<List<MoodEntry>?> pickAndParse();
}
