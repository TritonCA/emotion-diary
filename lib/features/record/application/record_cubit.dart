import 'package:flutter_bloc/flutter_bloc.dart';
import '../../entries/application/entries_cubit.dart';
import '../../entries/domain/entities/emotion.dart';
import '../../entries/domain/entities/mood_entry.dart';
import '../../entries/domain/repositories/emotion_catalog_repository.dart';
import '../../entries/domain/use_cases/delete_entry.dart';
import '../../entries/domain/use_cases/save_entry.dart';
import '../../entries/domain/use_cases/update_entry.dart';
import 'record_state.dart';

/// ViewModel for the Record screen. Owns the draft entry; persists via
/// [SaveEntry] / [UpdateEntry] / [DeleteEntry] then asks the shared
/// [EntriesCubit] to refresh. The same cubit + view powers both "new entry"
/// and "edit existing entry" — distinguished by [RecordState.editingId].
class RecordCubit extends Cubit<RecordState> {
  RecordCubit({
    required SaveEntry saveEntry,
    required UpdateEntry updateEntry,
    required DeleteEntry deleteEntry,
    required EmotionCatalogRepository catalogRepo,
    required EntriesCubit entriesCubit,
  })  : _saveEntry = saveEntry,
        _updateEntry = updateEntry,
        _deleteEntry = deleteEntry,
        _catalogRepo = catalogRepo,
        _entriesCubit = entriesCubit,
        super(const RecordState());

  final SaveEntry _saveEntry;
  final UpdateEntry _updateEntry;
  final DeleteEntry _deleteEntry;
  final EmotionCatalogRepository _catalogRepo;
  final EntriesCubit _entriesCubit;

  /// Fresh-draft path: load catalog only.
  Future<void> init() async {
    final catalog = await _catalogRepo.getCategories();
    emit(state.copyWith(catalog: catalog));
  }

  /// Edit path: prefill every field from an existing entry, then load the
  /// catalog. Emits a synchronous prefill so the very first build of the
  /// view already shows the right values (the trigger text controller relies
  /// on this).
  Future<void> loadExisting(MoodEntry entry) async {
    final intensities = <String, int>{
      for (var i = 0; i < entry.emotions.length; i++)
        entry.emotions[i].name: entry.intensityFor(i),
    };
    emit(state.copyWith(
      editingId: entry.id,
      selected: List<Emotion>.from(entry.emotions),
      intensities: intensities,
      intensity: entry.intensity,
      trigger: entry.trigger,
      timestamp: entry.timestamp,
    ));
    final catalog = await _catalogRepo.getCategories();
    emit(state.copyWith(catalog: catalog));
  }

  /// Refresh the catalog after the user edits it on Manage Emotions, and
  /// prune any selected emotions that no longer exist in the taxonomy.
  Future<void> reloadCatalog() async {
    final catalog = await _catalogRepo.getCategories();
    final available = <String>{
      for (final cat in catalog) ...cat.emotions,
    };
    final kept = state.selected.where((e) => available.contains(e.name)).toList();
    final keptIntensities = <String, int>{
      for (final e in kept) e.name: state.intensities[e.name] ?? state.intensity,
    };
    emit(state.copyWith(
      catalog: catalog,
      selected: kept,
      intensities: keptIntensities,
      intensity: _avg(keptIntensities, state.intensity),
    ));
  }

  void confirmEmotions(List<Emotion> emotions) {
    final next = <String, int>{
      for (final e in emotions)
        e.name: state.intensities[e.name] ?? state.intensity,
    };
    emit(state.copyWith(
      selected: emotions,
      intensities: next,
      intensity: _avg(next, state.intensity),
    ));
  }

  void removeEmotion(Emotion e) {
    final selected = state.selected.where((x) => x != e).toList();
    final next = Map<String, int>.from(state.intensities)..remove(e.name);
    emit(state.copyWith(
      selected: selected,
      intensities: next,
      intensity: _avg(next, state.intensity),
    ));
  }

  void setIntensity(int value) {
    final v = value.clamp(0, 10);
    if (state.selected.isEmpty) {
      emit(state.copyWith(intensity: v));
      return;
    }
    if (state.selected.length == 1) {
      final name = state.selected.first.name;
      final next = <String, int>{name: v};
      emit(state.copyWith(intensities: next, intensity: v));
    }
    // Multi-emotion mode: per-emotion sliders are authoritative.
  }

  void setEmotionIntensity(String emotionName, int value) {
    final v = value.clamp(0, 10);
    final next = Map<String, int>.from(state.intensities);
    next[emotionName] = v;
    emit(state.copyWith(
      intensities: next,
      intensity: _avg(next, state.intensity),
    ));
  }

  void setTrigger(String value) => emit(state.copyWith(trigger: value));

  void setTimestamp(DateTime value) => emit(state.copyWith(timestamp: value));

  Future<void> save() async {
    if (state.saving) return;
    emit(state.copyWith(saving: true));
    final intensities = [
      for (final e in state.selected) state.intensities[e.name] ?? state.intensity,
    ];
    final overall = intensities.isEmpty
        ? state.intensity
        : (intensities.reduce((a, b) => a + b) / intensities.length).round();
    final id = state.editingId ??
        DateTime.now().microsecondsSinceEpoch.toString();
    final entry = MoodEntry(
      id: id,
      timestamp: state.timestamp,
      emotions: state.selected,
      intensities: intensities,
      intensity: overall,
      trigger: state.trigger.trim(),
    );
    try {
      if (state.editingId != null) {
        await _updateEntry(entry);
      } else {
        await _saveEntry(entry);
      }
      await _entriesCubit.refresh();
    } catch (_) {
      emit(state.copyWith(saving: false));
      return;
    }
    if (state.editingId != null) {
      // Edit mode: keep state populated so the screen still shows the edited
      // entry and bump savedTick so the listener can react.
      emit(state.copyWith(saving: false, savedTick: state.savedTick + 1));
    } else {
      // Fresh-draft mode: reset to an empty draft for the next entry.
      emit(RecordState(
        catalog: state.catalog,
        savedTick: state.savedTick + 1,
      ));
    }
  }

  /// Deletes the entry currently being edited. No-op when creating a new
  /// one. Sets [RecordState.deletedTick] so the page can dismiss itself.
  Future<void> deleteCurrent() async {
    final id = state.editingId;
    if (id == null) return;
    emit(state.copyWith(saving: true));
    try {
      await _deleteEntry(id);
      await _entriesCubit.refresh();
    } catch (_) {
      emit(state.copyWith(saving: false));
      return;
    }
    emit(state.copyWith(
      saving: false,
      deletedTick: state.deletedTick + 1,
      clearEditingId: true,
    ));
  }

  static int _avg(Map<String, int> map, int fallback) {
    if (map.isEmpty) return fallback;
    final values = map.values.toList();
    return (values.reduce((a, b) => a + b) / values.length).round();
  }
}
