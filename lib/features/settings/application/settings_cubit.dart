import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/storage/key_value_store.dart';
import '../../entries/application/entries_cubit.dart';
import '../../entries/domain/use_cases/delete_all_entries.dart';
import '../../entries/domain/use_cases/export_entries_csv.dart';
import '../../entries/domain/use_cases/import_entries_csv.dart';
import 'settings_state.dart';

/// App-scoped owner of appearance + data-management actions. Theme mode and
/// locale are the single sources of truth read by MaterialApp.
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
  static const _localeKey = 'settings.locale';
  static const _legacyDailyPromptKey = 'settings.dailyPrompt';

  Future<void> load() async {
    final theme = await _store.getString(_themeKey);
    final locale = await _store.getString(_localeKey);
    emit(state.copyWith(
      themeMode: AppThemeMode.values.firstWhere(
        (m) => m.name == theme,
        orElse: () => AppThemeMode.dark,
      ),
      locale: AppLocale.fromCode(locale),
    ));
    // One-time cleanup of an obsolete pref key. Best-effort.
    try {
      await _store.remove(_legacyDailyPromptKey);
    } catch (_) {}
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

  Future<void> setLocale(AppLocale locale) async {
    emit(state.copyWith(locale: locale));
    await _store.setString(_localeKey, locale.code);
  }

  Future<void> exportCsv() async {
    emit(state.copyWith(busy: true, clearMessage: true));
    SettingsMessage msg;
    try {
      await _export();
      msg = const SettingsMessage(SettingsMessageKind.exportReady);
    } catch (_) {
      msg = const SettingsMessage(SettingsMessageKind.exportFailed);
    }
    emit(state.copyWith(busy: false, message: msg, bumpMessage: true));
  }

  Future<void> importCsv() async {
    emit(state.copyWith(busy: true, clearMessage: true));
    SettingsMessage msg;
    try {
      final count = await _import();
      await _entries.refresh();
      msg = count == null
          ? const SettingsMessage(SettingsMessageKind.importCancelled)
          : SettingsMessage(SettingsMessageKind.importOk, count);
    } catch (_) {
      msg = const SettingsMessage(SettingsMessageKind.importFailed);
    }
    emit(state.copyWith(busy: false, message: msg, bumpMessage: true));
  }

  Future<void> deleteAllData() async {
    emit(state.copyWith(busy: true, clearMessage: true));
    try {
      await _deleteAll();
      await _entries.refresh();
    } catch (_) {/* surface as "deleted" anyway — pre-existing semantics */}
    emit(state.copyWith(
      busy: false,
      message: const SettingsMessage(SettingsMessageKind.deleted),
      bumpMessage: true,
    ));
  }

  void consumeMessage() => emit(state.copyWith(clearMessage: true));
}
