import 'package:equatable/equatable.dart';
import '../domain/entities/mood_entry.dart';

enum EntriesStatus { initial, loading, ready }

class EntriesState extends Equatable {
  const EntriesState({
    this.status = EntriesStatus.initial,
    this.entries = const [],
  });

  final EntriesStatus status;
  final List<MoodEntry> entries;

  EntriesState copyWith({EntriesStatus? status, List<MoodEntry>? entries}) =>
      EntriesState(
        status: status ?? this.status,
        entries: entries ?? this.entries,
      );

  @override
  List<Object?> get props => [status, entries];
}
