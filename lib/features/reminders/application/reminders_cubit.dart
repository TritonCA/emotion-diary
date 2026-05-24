import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/notifications/notification_service.dart';
import '../domain/entities/reminder.dart';
import '../domain/repositories/reminders_repository.dart';
import 'reminders_state.dart';

/// App-scoped owner of user reminders. Persists changes via the repository
/// and (re)schedules notifications via [NotificationService].
class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit({
    required RemindersRepository repo,
    required NotificationService notifier,
  })  : _repo = repo,
        _notifier = notifier,
        super(const RemindersState());

  final RemindersRepository _repo;
  final NotificationService _notifier;

  Future<void> load() async {
    final stored = await _repo.getAll();
    // Sweep "once" reminders whose moment is already in the past: leaving
    // them enabled would surprise the user (UI shows ON but nothing fires).
    final now = DateTime.now();
    var dirty = false;
    final cleaned = <Reminder>[];
    for (final r in stored) {
      if (r.enabled &&
          r.recurrence == ReminderRecurrence.once &&
          r.anchor != null &&
          !r.anchor!.isAfter(now)) {
        cleaned.add(r.copyWith(enabled: false));
        dirty = true;
      } else {
        cleaned.add(r);
      }
    }
    if (dirty) {
      try {
        await _repo.saveAll(cleaned);
      } catch (_) {/* best-effort sweep */}
    }
    emit(state.copyWith(reminders: cleaned, loaded: true));
    await _notifier.rescheduleAll(cleaned);
  }

  Future<void> upsert(Reminder reminder) async {
    final list = [...state.reminders];
    final idx = list.indexWhere((r) => r.id == reminder.id);
    if (idx == -1) {
      list.add(reminder);
    } else {
      list[idx] = reminder;
    }
    await _persistAndReschedule(list);
  }

  Future<void> delete(int id) async {
    final list = state.reminders.where((r) => r.id != id).toList();
    await _persistAndReschedule(list);
  }

  Future<void> setEnabled(int id, bool enabled) async {
    final list = state.reminders
        .map((r) => r.id == id ? r.copyWith(enabled: enabled) : r)
        .toList();
    await _persistAndReschedule(list);
  }

  /// Persistence-first ordering: if the disk write fails we don't show a state
  /// that diverges from what survives a restart.
  Future<void> _persistAndReschedule(List<Reminder> list) async {
    await _repo.saveAll(list);
    emit(state.copyWith(reminders: list));
    await _notifier.rescheduleAll(list);
  }

  /// Drop every reminder (used by Settings → Delete all data when extended).
  Future<void> clear() async {
    await _repo.saveAll(const []);
    emit(state.copyWith(reminders: const []));
    await _notifier.cancelAll();
  }

  /// Generates a 31-bit numeric id (also used as the notification id).
  int nextId() {
    final used = state.reminders.map((r) => r.id).toSet();
    var id = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    while (used.contains(id)) {
      id = (id + 1) & 0x7fffffff;
    }
    return id;
  }
}
