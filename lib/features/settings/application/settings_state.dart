import 'package:equatable/equatable.dart';

enum AppThemeMode { light, dark, system }

extension AppThemeModeLabel on AppThemeMode {
  String get label => switch (this) {
        AppThemeMode.light => 'Light',
        AppThemeMode.dark => 'Dark',
        AppThemeMode.system => 'System',
      };
}

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = AppThemeMode.dark,
    this.dailyPrompt = true,
    this.busy = false,
    this.message,
  });

  final AppThemeMode themeMode;
  final bool dailyPrompt;
  final bool busy;
  final String? message; // one-shot info for a snackbar

  SettingsState copyWith({
    AppThemeMode? themeMode,
    bool? dailyPrompt,
    bool? busy,
    String? message,
    bool clearMessage = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      dailyPrompt: dailyPrompt ?? this.dailyPrompt,
      busy: busy ?? this.busy,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [themeMode, dailyPrompt, busy, message];
}
