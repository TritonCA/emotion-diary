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
    final list = await _repo.getAll();
    emit(state.copyWith(reminders: list, loaded: true));
    await _notifier.rescheduleAll(list);
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

  Future<void> _persistAndReschedule(List<Reminder> list) async {
    emit(state.copyWith(reminders: list));
    await _repo.saveAll(list);
    await _notifier.rescheduleAll(list);
  }

  /// Generates a stable-ish numeric id (used as the notification id too).
  int nextId() {
    final used = state.reminders.map((r) => r.id).toSet();
    final base = DateTime.now().millisecondsSinceEpoch % 0x7fffffff;
    var id = base;
    while (used.contains(id)) {
      id = (id + 1) & 0x7fffffff;
    }
    return id;
  }
}
