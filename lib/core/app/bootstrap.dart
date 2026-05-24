import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import '../di/injector.dart';
import '../notifications/notification_service.dart';
import '../../features/entries/application/entries_cubit.dart';
import '../../features/reminders/application/reminders_cubit.dart';
import '../../features/settings/application/settings_cubit.dart';

/// Single composition root. Every step is independent — a single failure
/// (corrupt prefs, missing tz data, denied notification permission, …) must
/// never leave the user staring at a black screen.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _guard('configureDependencies', configureDependencies);

  await _guard('initializeDateFormatting', () async {
    await initializeDateFormatting('ru', null);
    await initializeDateFormatting('en', null);
  });

  await _guard('NotificationService.init', () async {
    await NotificationService.instance.init();
  });

  await _guard('SettingsCubit.load', () => sl<SettingsCubit>().load());
  await _guard('EntriesCubit.load', () => sl<EntriesCubit>().load());
  await _guard('RemindersCubit.load', () => sl<RemindersCubit>().load());

  runApp(const MoodTrackerApp());
}

Future<void> _guard(String label, Future<void> Function() body) async {
  try {
    await body();
  } catch (e, st) {
    if (kDebugMode) debugPrint('bootstrap step "$label" failed: $e\n$st');
  }
}
