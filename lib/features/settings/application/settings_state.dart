import 'package:equatable/equatable.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/theme/app_accent.dart';

enum AppThemeMode { light, dark, system }

/// One-shot info emitted to the page; the page maps it to a localized string.
enum SettingsMessageKind {
  exportReady,
  exportFailed,
  importOk,
  importCancelled,
  importFailed,
  deleted,
}

class SettingsMessage extends Equatable {
  const SettingsMessage(this.kind, [this.count]);
  final SettingsMessageKind kind;
  final int? count;

  @override
  List<Object?> get props => [kind, count];
}

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = AppThemeMode.dark,
    this.locale = AppLocale.ru,
    this.accent = AppAccent.indigo,
    this.busy = false,
    this.message,
    this.messageVersion = 0,
  });

  final AppThemeMode themeMode;
  final AppLocale locale;
  final AppAccent accent;
  final bool busy;
  final SettingsMessage? message;
  /// Bumped on every new message so identical-kind messages still trigger
  /// `listenWhen` (which compares by Equatable identity).
  final int messageVersion;

  SettingsState copyWith({
    AppThemeMode? themeMode,
    AppLocale? locale,
    AppAccent? accent,
    bool? busy,
    SettingsMessage? message,
    bool clearMessage = false,
    bool bumpMessage = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      accent: accent ?? this.accent,
      busy: busy ?? this.busy,
      message: clearMessage ? null : (message ?? this.message),
      messageVersion:
          bumpMessage ? messageVersion + 1 : messageVersion,
    );
  }

  @override
  List<Object?> get props =>
      [themeMode, locale, accent, busy, message, messageVersion];
}
