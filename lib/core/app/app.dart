import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../di/injector.dart';
import '../navigation/app_shell.dart';
import '../theme/app_theme.dart';
import '../../features/entries/application/entries_cubit.dart';
import '../../features/settings/application/settings_cubit.dart';
import '../../features/settings/application/settings_state.dart';

/// Root widget. Provides the app-scoped state owners and drives MaterialApp's
/// themeMode from the single-source-of-truth SettingsCubit.
class MoodTrackerApp extends StatelessWidget {
  const MoodTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EntriesCubit>.value(value: sl<EntriesCubit>()),
        BlocProvider<SettingsCubit>.value(value: sl<SettingsCubit>()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (a, b) => a.themeMode != b.themeMode,
        builder: (context, state) {
          return MaterialApp(
            title: 'Mood Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: switch (state.themeMode) {
              AppThemeMode.light => ThemeMode.light,
              AppThemeMode.dark => ThemeMode.dark,
              AppThemeMode.system => ThemeMode.system,
            },
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
