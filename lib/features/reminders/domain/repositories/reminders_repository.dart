import '../entities/reminder.dart';

/// Persistence contract for user-defined reminders.
abstract interface class RemindersRepository {
  Future<List<Reminder>> getAll();
  Future<void> saveAll(List<Reminder> reminders);
}
