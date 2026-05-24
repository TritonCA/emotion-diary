import 'package:equatable/equatable.dart';
import '../domain/entities/reminder.dart';

class RemindersState extends Equatable {
  const RemindersState({this.reminders = const [], this.loaded = false});

  final List<Reminder> reminders;
  final bool loaded;

  RemindersState copyWith({List<Reminder>? reminders, bool? loaded}) =>
      RemindersState(
        reminders: reminders ?? this.reminders,
        loaded: loaded ?? this.loaded,
      );

  @override
  List<Object?> get props => [reminders, loaded];
}
