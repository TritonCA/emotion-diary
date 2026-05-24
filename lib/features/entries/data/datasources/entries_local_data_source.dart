import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/storage/key_value_store.dart';
import '../dto/mood_entry_dto.dart';

/// Reads/writes the entry list as a JSON array in the key-value store. A
/// corrupted blob never crashes startup — we treat it as an empty list and
/// let the next save overwrite it.
class EntriesLocalDataSource {
  EntriesLocalDataSource(this._store);
  final KeyValueStore _store;

  static const _key = 'entries.v1';

  Future<List<MoodEntryDto>> readAll() async {
    final raw = await _store.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final out = <MoodEntryDto>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          out.add(MoodEntryDto.fromJson(item.cast<String, dynamic>()));
        } catch (e) {
          if (kDebugMode) debugPrint('entry skipped: $e');
        }
      }
      return out;
    } catch (e) {
      if (kDebugMode) debugPrint('entries parse failed: $e');
      return [];
    }
  }

  Future<void> writeAll(List<MoodEntryDto> dtos) async {
    final raw = jsonEncode(dtos.map((d) => d.toJson()).toList());
    await _store.setString(_key, raw);
  }

  Future<void> clear() => _store.remove(_key);
}
