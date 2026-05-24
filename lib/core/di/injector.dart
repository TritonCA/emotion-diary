import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/key_value_store.dart';
import '../storage/shared_prefs_store.dart';

import '../../features/entries/application/entries_cubit.dart';
import '../../features/entries/data/datasources/emotion_catalog_data_source.dart';
import '../../features/entries/data/datasources/entries_local_data_source.dart';
import '../../features/entries/data/repositories/emotion_catalog_repository_impl.dart';
import '../../features/entries/data/repositories/entries_repository_impl.dart';
import '../../features/entries/data/services/csv_service.dart';
import '../../features/entries/domain/repositories/entries_csv_gateway.dart';
import '../../features/entries/domain/repositories/emotion_catalog_repository.dart';
import '../../features/entries/domain/repositories/entries_repository.dart';
import '../../features/entries/domain/use_cases/delete_all_entries.dart';
import '../../features/entries/domain/use_cases/export_entries_csv.dart';
import '../../features/entries/domain/use_cases/import_entries_csv.dart';
import '../../features/entries/domain/use_cases/save_entry.dart';

import '../../features/record/application/record_cubit.dart';
import '../../features/history/application/history_cubit.dart';
import '../../features/stats/application/stats_cubit.dart';
import '../../features/stats/domain/use_cases/compute_stats.dart';
import '../../features/settings/application/settings_cubit.dart';

final GetIt sl = GetIt.instance;

/// Wires the whole object graph. Called once during bootstrap.
Future<void> configureDependencies() async {
  // --- core / infrastructure ---
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<KeyValueStore>(SharedPrefsStore(prefs));

  // --- data sources ---
  sl.registerLazySingleton(() => EntriesLocalDataSource(sl()));
  sl.registerLazySingleton(() => EmotionCatalogDataSource(sl()));
  sl.registerLazySingleton<EntriesCsvGateway>(() => const CsvService());

  // --- repositories ---
  sl.registerLazySingleton<EntriesRepository>(() => EntriesRepositoryImpl(sl()));
  sl.registerLazySingleton<EmotionCatalogRepository>(
      () => EmotionCatalogRepositoryImpl(sl()));

  // --- use cases ---
  sl.registerLazySingleton(() => SaveEntry(sl()));
  sl.registerLazySingleton(() => DeleteAllEntries(sl()));
  sl.registerLazySingleton(() => ExportEntriesCsv(sl(), sl()));
  sl.registerLazySingleton(() => ImportEntriesCsv(sl(), sl()));
  sl.registerLazySingleton(() => const ComputeStats());

  // --- app-scoped state owners (single instances) ---
  sl.registerSingleton<EntriesCubit>(EntriesCubit(sl()));
  sl.registerSingleton<SettingsCubit>(SettingsCubit(
    store: sl(),
    entriesCubit: sl(),
    exportCsv: sl(),
    importCsv: sl(),
    deleteAll: sl(),
  ));

  // --- per-screen view models (factories; all share the EntriesCubit singleton) ---
  sl.registerFactory(() => RecordCubit(
        saveEntry: sl(),
        catalogRepo: sl(),
        entriesCubit: sl(),
      ));
  sl.registerFactory(() => HistoryCubit(sl()));
  sl.registerFactory(() => StatsCubit(sl(), sl()));
}
