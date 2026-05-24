import 'package:equatable/equatable.dart';
import '../../entries/domain/entities/emotion.dart';
import '../../entries/domain/entities/emotion_category.dart';

class RecordState extends Equatable {
  const RecordState({
    this.catalog = const [],
    this.selected = const [],
    this.intensity = 5,
    this.trigger = '',
    DateTime? timestamp,
    this.saving = false,
    this.savedTick = 0,
  }) : _timestamp = timestamp;

  final List<EmotionCategory> catalog;
  final List<Emotion> selected;
  final int intensity;
  final String trigger;
  final DateTime? _timestamp;
  final bool saving;
  final int savedTick;

  DateTime get timestamp => _timestamp ?? DateTime.now();
  bool get isNow => _timestamp == null;

  RecordState copyWith({
    List<EmotionCategory>? catalog,
    List<Emotion>? selected,
    int? intensity,
    String? trigger,
    DateTime? timestamp,
    bool resetTimestamp = false,
    bool? saving,
    int? savedTick,
  }) {
    return RecordState(
      catalog: catalog ?? this.catalog,
      selected: selected ?? this.selected,
      intensity: intensity ?? this.intensity,
      trigger: trigger ?? this.trigger,
      timestamp: resetTimestamp ? null : (timestamp ?? _timestamp),
      saving: saving ?? this.saving,
      savedTick: savedTick ?? this.savedTick,
    );
  }

  @override
  List<Object?> get props =>
      [catalog, selected, intensity, trigger, _timestamp, saving, savedTick];
}
