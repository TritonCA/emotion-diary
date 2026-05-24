import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import '../di/injector.dart';
import '../notifications/notification_service.dart';
import '../../features/entries/application/entries_cubit.dart';
import '../../features/reminders/application/reminders_cubit.dart';
import '../../features/settings/application/settings_cubit.dart';

/// Single composition root: init DI, hydrate persisted state, then run the app.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  // Make intl ready for both supported locales before any DateFormat call.
  await initializeDateFormatting('ru', null);
  await initializeDateFormatting('en', null);

  // Notifications: init plugin (timezone, channels, permissions) before
  // reminders load — RemindersCubit reschedules on load().
  await NotificationService.instance.init();

  // Hydrate app-scoped state before first frame.
  await sl<SettingsCubit>().load();
  await sl<EntriesCubit>().load();
  await sl<RemindersCubit>().load();

  runApp(const MoodTrackerApp());
}
