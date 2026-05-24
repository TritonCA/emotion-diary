import '../../domain/entities/mood_entry.dart';
import '../../domain/repositories/entries_repository.dart';
import '../datasources/entries_local_data_source.dart';
import '../mappers/mood_entry_mapper.dart';

class EntriesRepositoryImpl implements EntriesRepository {
  EntriesRepositoryImpl(this._local);
  final EntriesLocalDataSource _local;

  @override
  Future<List<MoodEntry>> getAll() async {
    final dtos = await _local.readAll();
    final entries = dtos.map(MoodEntryMapper.toEntity).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  @override
  Future<void> add(MoodEntry entry) async {
    final dtos = await _local.readAll();
    dtos.add(MoodEntryMapper.toDto(entry));
    await _local.writeAll(dtos);
  }

  @override
  Future<void> deleteAll() => _local.clear();

  @override
  Future<void> replaceAll(List<MoodEntry> entries) =>
      _local.writeAll(entries.map(MoodEntryMapper.toDto).toList());
}
