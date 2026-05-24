import 'package:equatable/equatable.dart';
import '../../entries/domain/entities/emotion.dart';
import '../../entries/domain/entities/emotion_category.dart';

class RecordState extends Equatable {
  const RecordState({
    this.catalog = const [],
    this.selected = const [],
    this.intensities = const {},
    this.intensity = 5,
    this.trigger = '',
    DateTime? timestamp,
    this.editingId,
    this.saving = false,
    this.savedTick = 0,
    this.deletedTick = 0,
  }) : _timestamp = timestamp;

  final List<EmotionCategory> catalog;
  final List<Emotion> selected;
  /// Per-emotion intensities keyed by `emotion.name`. When [selected] is
  /// empty, this is empty too and [intensity] is used as the lone default.
  final Map<String, int> intensities;
  /// Fallback intensity for the empty-selection case + canonical value
  /// shown by the visualization. Computed as the average of [intensities]
  /// whenever the map is non-empty.
  final int intensity;
  final String trigger;
  final DateTime? _timestamp;
  /// When non-null, the screen is editing an existing entry — `save()` will
  /// update by this id instead of inserting a new entry.
  final String? editingId;
  final bool saving;
  final int savedTick;
  final int deletedTick;

  DateTime get timestamp => _timestamp ?? DateTime.now();
  bool get isNow => _timestamp == null;
  bool get isEditing => editingId != null;

  RecordState copyWith({
    List<EmotionCategory>? catalog,
    List<Emotion>? selected,
    Map<String, int>? intensities,
    int? intensity,
    String? trigger,
    DateTime? timestamp,
    bool resetTimestamp = false,
    String? editingId,
    bool clearEditingId = false,
    bool? saving,
    int? savedTick,
    int? deletedTick,
  }) {
    return RecordState(
      catalog: catalog ?? this.catalog,
      selected: selected ?? this.selected,
      intensities: intensities ?? this.intensities,
      intensity: intensity ?? this.intensity,
      trigger: trigger ?? this.trigger,
      timestamp: resetTimestamp ? null : (timestamp ?? _timestamp),
      editingId: clearEditingId ? null : (editingId ?? this.editingId),
      saving: saving ?? this.saving,
      savedTick: savedTick ?? this.savedTick,
      deletedTick: deletedTick ?? this.deletedTick,
    );
  }

  @override
  List<Object?> get props => [
        catalog,
        selected,
        intensities,
        intensity,
        trigger,
        _timestamp,
        editingId,
        saving,
        savedTick,
        deletedTick,
      ];
}
