import 'package:equatable/equatable.dart';

/// How often a reminder repeats. Interval N is interpreted relative to [unit].
enum ReminderRecurrence { once, hourly, daily, weekly }

/// A user-defined reminder. `hour`/`minute` are the local-time anchor; `every`
/// is the count of [unit]s between firings (ignored for [ReminderRecurrence.once]).
class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.text,
    required this.hour,
    required this.minute,
    required this.recurrence,
    required this.every,
    required this.enabled,
    this.anchor,
  });

  final int id;
  final String text;
  final int hour;
  final int minute;
  final ReminderRecurrence recurrence;
  final int every;
  final bool enabled;
  /// Optional fixed anchor date for once-shot or interval-based repeats.
  final DateTime? anchor;

  Reminder copyWith({
    String? text,
    int? hour,
    int? minute,
    ReminderRecurrence? recurrence,
    int? every,
    bool? enabled,
    DateTime? anchor,
    bool clearAnchor = false,
  }) {
    return Reminder(
      id: id,
      text: text ?? this.text,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      recurrence: recurrence ?? this.recurrence,
      every: every ?? this.every,
      enabled: enabled ?? this.enabled,
      anchor: clearAnchor ? null : (anchor ?? this.anchor),
    );
  }

  @override
  List<Object?> get props =>
      [id, text, hour, minute, recurrence, every, enabled, anchor];
}
