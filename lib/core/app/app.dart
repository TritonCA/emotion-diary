import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../di/injector.dart';
import '../l10n/app_strings.dart';
import '../navigation/app_shell.dart';
import '../theme/app_theme.dart';
import '../../features/entries/application/entries_cubit.dart';
import '../../features/reminders/application/reminders_cubit.dart';
import '../../features/settings/application/settings_cubit.dart';
import '../../features/settings/application/settings_state.dart';

/// Root widget. Provides the app-scoped state owners and drives MaterialApp's
/// themeMode + locale from the single-source-of-truth SettingsCubit.
class MoodTrackerApp extends StatelessWidget {
  const MoodTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EntriesCubit>.value(value: sl<EntriesCubit>()),
        BlocProvider<SettingsCubit>.value(value: sl<SettingsCubit>()),
        BlocProvider<RemindersCubit>.value(value: sl<RemindersCubit>()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (a, b) => a.themeMode != b.themeMode || a.locale != b.locale,
        builder: (context, state) {
          return AppStringsScope(
            locale: state.locale,
            child: MaterialApp(
              title: 'Mood Tracker',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: switch (state.themeMode) {
                AppThemeMode.light => ThemeMode.light,
                AppThemeMode.dark => ThemeMode.dark,
                AppThemeMode.system => ThemeMode.system,
              },
              locale: Locale(state.locale.code),
              supportedLocales: const [Locale('ru'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const AppShell(),
            ),
          );
        },
      ),
    );
  }
}
