import 'package:flutter_bloc/flutter_bloc.dart';
import '../../entries/application/entries_cubit.dart';
import '../../entries/domain/entities/emotion.dart';
import '../../entries/domain/entities/mood_entry.dart';
import '../../entries/domain/repositories/emotion_catalog_repository.dart';
import '../../entries/domain/use_cases/save_entry.dart';
import 'record_state.dart';

/// ViewModel for the Record screen. Owns the draft entry; persists via
/// [SaveEntry] then asks the shared [EntriesCubit] to refresh.
class RecordCubit extends Cubit<RecordState> {
  RecordCubit({
    required SaveEntry saveEntry,
    required EmotionCatalogRepository catalogRepo,
    required EntriesCubit entriesCubit,
  })  : _saveEntry = saveEntry,
        _catalogRepo = catalogRepo,
        _entriesCubit = entriesCubit,
        super(const RecordState());

  final SaveEntry _saveEntry;
  final EmotionCatalogRepository _catalogRepo;
  final EntriesCubit _entriesCubit;

  Future<void> init() async {
    final catalog = await _catalogRepo.getCategories();
    emit(state.copyWith(catalog: catalog));
  }

  void confirmEmotions(List<Emotion> emotions) =>
      emit(state.copyWith(selected: emotions));

  void removeEmotion(Emotion e) => emit(
      state.copyWith(selected: state.selected.where((x) => x != e).toList()));

  void setIntensity(int value) => emit(state.copyWith(intensity: value));

  void setTrigger(String value) => emit(state.copyWith(trigger: value));

  void setTimestamp(DateTime value) => emit(state.copyWith(timestamp: value));

  Future<void> save() async {
    if (state.saving) return;
    emit(state.copyWith(saving: true));
    final entry = MoodEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: state.timestamp,
      emotions: state.selected,
      intensity: state.intensity,
      trigger: state.trigger.trim(),
    );
    await _saveEntry(entry);
    await _entriesCubit.refresh();
    emit(RecordState(
      catalog: state.catalog,
      savedTick: state.savedTick + 1,
    ));
  }
}
