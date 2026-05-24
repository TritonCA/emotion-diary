import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/storage/key_value_store.dart';
import '../../entries/application/entries_cubit.dart';
import '../../entries/domain/use_cases/delete_all_entries.dart';
import '../../entries/domain/use_cases/export_entries_csv.dart';
import '../../entries/domain/use_cases/import_entries_csv.dart';
import 'settings_state.dart';

/// App-scoped owner of appearance + data-management actions. Theme mode is the
/// single source of truth read by MaterialApp.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required KeyValueStore store,
    required EntriesCubit entriesCubit,
    required ExportEntriesCsv exportCsv,
    required ImportEntriesCsv importCsv,
    required DeleteAllEntries deleteAll,
  })  : _store = store,
        _entries = entriesCubit,
        _export = exportCsv,
        _import = importCsv,
        _deleteAll = deleteAll,
        super(const SettingsState());

  final KeyValueStore _store;
  final EntriesCubit _entries;
  final ExportEntriesCsv _export;
  final ImportEntriesCsv _import;
  final DeleteAllEntries _deleteAll;

  static const _themeKey = 'settings.theme';
  static const _promptKey = 'settings.dailyPrompt';

  Future<void> load() async {
    final theme = await _store.getString(_themeKey);
    final prompt = await _store.getBool(_promptKey);
    emit(state.copyWith(
      themeMode: AppThemeMode.values.firstWhere(
        (m) => m.name == theme,
        orElse: () => AppThemeMode.dark,
      ),
      dailyPrompt: prompt ?? true,
    ));
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _store.setString(_themeKey, mode.name);
  }

  /// Quick toggle from the top bar (cycles between light and dark).
  Future<void> toggleTheme() async {
    final next =
        state.themeMode == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    await setThemeMode(next);
  }

  Future<void> setDailyPrompt(bool value) async {
    emit(state.copyWith(dailyPrompt: value));
    await _store.setBool(_promptKey, value);
  }

  Future<void> exportCsv() async {
    emit(state.copyWith(busy: true, clearMessage: true));
    try {
      await _export();
      emit(state.copyWith(busy: false, message: 'Export ready'));
    } catch (_) {
      emit(state.copyWith(busy: false, message: 'Export failed'));
    }
  }

  Future<void> importCsv() async {
    emit(state.copyWith(busy: true, clearMessage: true));
    try {
      final count = await _import();
      await _entries.refresh();
      emit(state.copyWith(
        busy: false,
        message: count == null ? 'Import cancelled' : 'Imported $count entries',
      ));
    } catch (_) {
      emit(state.copyWith(busy: false, message: 'Import failed'));
    }
  }

  Future<void> deleteAllData() async {
    emit(state.copyWith(busy: true, clearMessage: true));
    await _deleteAll();
    await _entries.refresh();
    emit(state.copyWith(busy: false, message: 'All data deleted'));
  }

  void consumeMessage() => emit(state.copyWith(clearMessage: true));
}
