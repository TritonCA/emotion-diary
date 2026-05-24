import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminders_repository.dart';

/// Stores the list as a JSON array in the shared key-value store (persists on
/// Android via SharedPreferences-backed storage). Reads are best-effort — any
/// parse failure yields an empty list rather than crashing app startup.
class RemindersRepositoryImpl implements RemindersRepository {
  RemindersRepositoryImpl(this._store);
  final KeyValueStore _store;

  static const _key = 'reminders.v1';

  @override
  Future<List<Reminder>> getAll() async {
    final raw = await _store.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final out = <Reminder>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final parsed = _fromJson(item.cast<String, dynamic>());
        if (parsed != null) out.add(parsed);
      }
      return out;
    } catch (e) {
      if (kDebugMode) debugPrint('reminders parse failed: $e');
      return [];
    }
  }

  @override
  Future<void> saveAll(List<Reminder> reminders) async {
    final raw = jsonEncode(reminders.map(_toJson).toList());
    await _store.setString(_key, raw);
  }

  Reminder? _fromJson(Map<String, dynamic> j) {
    try {
      return Reminder(
        id: (j['id'] as num).toInt(),
        text: (j['text'] as String?) ?? '',
        hour: ((j['hour'] as num?) ?? 9).toInt().clamp(0, 23),
        minute: ((j['minute'] as num?) ?? 0).toInt().clamp(0, 59),
        recurrence: ReminderRecurrence.values.firstWhere(
          (r) => r.name == j['recurrence'],
          orElse: () => ReminderRecurrence.daily,
        ),
        every: ((j['every'] as num?) ?? 1).toInt().clamp(1, 999),
        enabled: (j['enabled'] as bool?) ?? true,
        anchor: j['anchor'] is String ? DateTime.tryParse(j['anchor'] as String) : null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('reminder entry skipped: $e');
      return null;
    }
  }

  Map<String, dynamic> _toJson(Reminder r) => {
        'id': r.id,
        'text': r.text,
        'hour': r.hour,
        'minute': r.minute,
        'recurrence': r.recurrence.name,
        'every': r.every,
        'enabled': r.enabled,
        'anchor': r.anchor?.toIso8601String(),
      };
}
