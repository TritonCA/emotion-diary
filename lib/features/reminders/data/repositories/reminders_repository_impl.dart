import 'dart:convert';
import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminders_repository.dart';

/// Stores the list as a JSON array in the shared key-value store (persists on
/// Android via SharedPreferences-backed storage).
class RemindersRepositoryImpl implements RemindersRepository {
  RemindersRepositoryImpl(this._store);
  final KeyValueStore _store;

  static const _key = 'reminders.v1';

  @override
  Future<List<Reminder>> getAll() async {
    final raw = await _store.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(_fromJson).toList();
  }

  @override
  Future<void> saveAll(List<Reminder> reminders) async {
    final raw = jsonEncode(reminders.map(_toJson).toList());
    await _store.setString(_key, raw);
  }

  Reminder _fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] as int,
        text: j['text'] as String,
        hour: j['hour'] as int,
        minute: j['minute'] as int,
        recurrence: ReminderRecurrence.values.firstWhere(
          (r) => r.name == j['recurrence'],
          orElse: () => ReminderRecurrence.daily,
        ),
        every: (j['every'] as int?) ?? 1,
        enabled: (j['enabled'] as bool?) ?? true,
        anchor: j['anchor'] == null
            ? null
            : DateTime.tryParse(j['anchor'] as String),
      );

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
