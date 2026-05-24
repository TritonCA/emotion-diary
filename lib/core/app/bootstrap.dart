import 'package:flutter/widgets.dart';

import 'app.dart';
import '../di/injector.dart';
import '../../features/entries/application/entries_cubit.dart';
import '../../features/settings/application/settings_cubit.dart';

/// Single composition root: init DI, hydrate persisted state, then run the app.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  // Hydrate app-scoped state before first frame.
  await sl<SettingsCubit>().load();
  await sl<EntriesCubit>().load();

  runApp(const MoodTrackerApp());
}
