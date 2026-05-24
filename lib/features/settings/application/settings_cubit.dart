import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/storage/key_value_store.dart';
import '../../entries/application/entries_cubit.dart';
import '../../entries/domain/use_cases/delete_all_entries.dart';
import '../../entries/domain/use_cases/export_entries_csv.dart';
import '../../entries/domain/use_cases/import_entries_csv.dart';
import 'settings_state.dart';

/// One-shot status emitted to the page; the page maps it to a localized string.
enum SettingsMessageKind {
  exportReady,
  exportFailed,
  importOk,
  importCancelled,
  importFailed,
  deleted,
}

class SettingsMessage {
  const SettingsMessage(this.kind, [this.count]);
  final SettingsMessageKind kind;
  final int? count;

  @override
  bool operator ==(Object other) =>
      other is SettingsMessage && other.kind == kind && other.count == count;

  @override
  int get hashCode => Object.hash(kind, count);
}

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

  SettingsMessage? _msg;
  SettingsMessage? get pendingMessage => _msg;

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
    _msg = null;
    emit(state.copyWith(busy: true, clearMessage: true));
    try {
      await _export();
      _msg = const SettingsMessage(SettingsMessageKind.exportReady);
    } catch (_) {
      _msg = const SettingsMessage(SettingsMessageKind.exportFailed);
    }
    emit(state.copyWith(busy: false, message: 'tick:${DateTime.now().microsecondsSinceEpoch}'));
  }

  Future<void> importCsv() async {
    _msg = null;
    emit(state.copyWith(busy: true, clearMessage: true));
    try {
      final count = await _import();
      await _entries.refresh();
      _msg = count == null
          ? const SettingsMessage(SettingsMessageKind.importCancelled)
          : SettingsMessage(SettingsMessageKind.importOk, count);
    } catch (_) {
      _msg = const SettingsMessage(SettingsMessageKind.importFailed);
    }
    emit(state.copyWith(busy: false, message: 'tick:${DateTime.now().microsecondsSinceEpoch}'));
  }

  Future<void> deleteAllData() async {
    _msg = null;
    emit(state.copyWith(busy: true, clearMessage: true));
    await _deleteAll();
    await _entries.refresh();
    _msg = const SettingsMessage(SettingsMessageKind.deleted);
    emit(state.copyWith(busy: false, message: 'tick:${DateTime.now().microsecondsSinceEpoch}'));
  }

  void consumeMessage() {
    _msg = null;
    emit(state.copyWith(clearMessage: true));
  }
}
