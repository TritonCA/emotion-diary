import 'package:equatable/equatable.dart';
import '../../../core/l10n/app_locale.dart';

enum AppThemeMode { light, dark, system }

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = AppThemeMode.dark,
    this.locale = AppLocale.ru,
    this.busy = false,
    this.message,
  });

  final AppThemeMode themeMode;
  final AppLocale locale;
  final bool busy;
  final String? message; // one-shot info for a snackbar

  SettingsState copyWith({
    AppThemeMode? themeMode,
    AppLocale? locale,
    bool? busy,
    String? message,
    bool clearMessage = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      busy: busy ?? this.busy,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [themeMode, locale, busy, message];
}
