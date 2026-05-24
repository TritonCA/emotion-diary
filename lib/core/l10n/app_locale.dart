/// Supported UI languages. Mirrors `Locale` but stays in a domain-agnostic enum
/// so settings can persist a stable key.
enum AppLocale {
  ru('ru'),
  en('en');

  const AppLocale(this.code);
  final String code;

  static AppLocale fromCode(String? code) =>
      AppLocale.values.firstWhere((l) => l.code == code, orElse: () => AppLocale.ru);
}

extension AppLocaleLabel on AppLocale {
  String get nativeLabel => switch (this) {
        AppLocale.ru => 'Русский',
        AppLocale.en => 'English',
      };
}
