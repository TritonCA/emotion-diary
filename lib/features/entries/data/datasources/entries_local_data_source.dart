import 'dart:convert';
import '../../../../core/storage/key_value_store.dart';
import '../dto/mood_entry_dto.dart';

/// Reads/writes the entry list as a JSON array in the key-value store.
class EntriesLocalDataSource {
  EntriesLocalDataSource(this._store);
  final KeyValueStore _store;

  static const _key = 'entries.v1';

  Future<List<MoodEntryDto>> readAll() async {
    final raw = await _store.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(MoodEntryDto.fromJson).toList();
  }

  Future<void> writeAll(List<MoodEntryDto> dtos) async {
    final raw = jsonEncode(dtos.map((d) => d.toJson()).toList());
    await _store.setString(_key, raw);
  }

  Future<void> clear() => _store.remove(_key);
}
