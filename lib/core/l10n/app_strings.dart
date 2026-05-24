import 'package:flutter/widgets.dart';
import 'app_locale.dart';

/// Lightweight i18n: a Map per locale lookup with a typed accessor. We avoid
/// the full Flutter intl tool to keep the project free of generated files.
class AppStrings {
  const AppStrings(this.locale);
  final AppLocale locale;

  static AppStrings of(BuildContext context) => _AppStringsScope.of(context);

  String t(String key) {
    final table = _data[locale.code] ?? _data['ru']!;
    return table[key] ?? _data['en']?[key] ?? key;
  }

  static const _data = <String, Map<String, String>>{
    'ru': _ru,
    'en': _en,
  };
}

/// InheritedWidget driving rebuilds when the language changes.
class AppStringsScope extends StatelessWidget {
  const AppStringsScope({super.key, required this.locale, required this.child});
  final AppLocale locale;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      _AppStringsScope(strings: AppStrings(locale), child: child);
}

class _AppStringsScope extends InheritedWidget {
  const _AppStringsScope({required this.strings, required super.child});
  final AppStrings strings;

  static AppStrings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AppStringsScope>();
    return scope?.strings ?? const AppStrings(AppLocale.ru);
  }

  @override
  bool updateShouldNotify(_AppStringsScope old) => old.strings.locale != strings.locale;
}

extension AppStringsX on BuildContext {
  AppStrings get s => AppStrings.of(this);
}

const _ru = <String, String>{
  // Common
  'app.title': 'Дневник эмоций',
  'common.cancel': 'Отмена',
  'common.delete': 'Удалить',
  'common.add': 'Добавить',
  'common.save': 'Сохранить',
  'common.done': 'Готово',
  'common.now': 'Сейчас',
  'common.no_data': 'Пока нет данных',

  // Top bar
  'top.settings': 'Настройки',
  'top.toggle_theme': 'Сменить тему',

  // Bottom nav
  'nav.record': 'Запись',
  'nav.history': 'История',
  'nav.stats': 'Статистика',

  // Record
  'record.title': 'Чувства',
  'record.current_emotions': 'Текущие эмоции',
  'record.add_emotion': 'Добавить эмоцию',
  'record.intensity': 'Интенсивность',
  'record.mild': 'Слабо',
  'record.intense': 'Сильно',
  'record.what_happened': 'Что произошло?',
  'record.trigger_hint': 'Контекст или триггер...',
  'record.save_entry': 'Сохранить запись',
  'record.history_footer': 'История',
  'record.saved': 'Запись сохранена',

  // Emotion picker
  'picker.how_are_you': 'Что вы чувствуете?',
  'picker.search_hint': 'Поиск эмоций...',
  'picker.select_all': 'Выбрать все',

  // History
  'history.title': 'История',
  'history.all_categories': 'Все категории',
  'history.uncategorized': 'Без категории',
  'history.period.last7': 'Последние 7 дней',
  'history.period.last30': 'Последние 30 дней',
  'history.period.last365': 'Последний год',
  'history.period.all': 'Всё время',
  'history.empty': 'Ваши записи появятся здесь',
  'history.day.today': 'Сегодня',
  'history.day.yesterday': 'Вчера',
  'history.intensity_label': 'Интенсивность',

  // Stats
  'stats.title': 'Статистика',
  'stats.period.week': 'Неделя',
  'stats.period.month': 'Месяц',
  'stats.period.year': 'Год',
  'stats.period.all': 'Всё',
  'stats.total_entries': 'Всего записей',
  'stats.avg_intensity': 'Ср. интенсивность',
  'stats.top_emotion': 'Топ-эмоция',
  'stats.intensity_trend': 'Динамика интенсивности',
  'stats.last_7_days': 'Последние 7 дней',
  'stats.frequency': 'Частота',
  'stats.context': 'Контекст',
  'stats.emotion_type': 'Тип эмоций',
  'stats.no_data': 'Пока нет данных',
  'stats.no_context': 'Повторяющийся контекст не найден',
  'stats.positive': 'Позитив',
  'stats.neutral': 'Нейтрал',
  'stats.negative': 'Негатив',
  'stats.focus': 'Фокус',

  // Settings
  'settings.title': 'Настройки',
  'settings.appearance': 'Внешний вид',
  'settings.theme': 'Тема',
  'settings.theme.light': 'Светлая',
  'settings.theme.dark': 'Тёмная',
  'settings.theme.system': 'Системная',
  'settings.language': 'Язык',
  'settings.reminders': 'Напоминания',
  'settings.reminders.manage': 'Управление напоминаниями',
  'settings.reminders.hint':
      'Создавайте сколько угодно напоминаний с любым текстом, временем и периодичностью.',
  'settings.data': 'Данные',
  'settings.manage_emotions': 'Управление эмоциями',
  'settings.export_csv': 'Экспорт в CSV',
  'settings.import_csv': 'Импорт из CSV',
  'settings.delete_all': 'Удалить все данные',
  'settings.delete_confirm.title': 'Удалить все данные?',
  'settings.delete_confirm.body':
      'Это безвозвратно удалит все записи. Действие нельзя отменить.',
  'settings.msg.export_ready': 'Экспорт готов',
  'settings.msg.export_failed': 'Не удалось экспортировать',
  'settings.msg.import_cancelled': 'Импорт отменён',
  'settings.msg.import_ok': 'Импортировано записей: {n}',
  'settings.msg.import_failed': 'Не удалось импортировать',
  'settings.msg.deleted': 'Все данные удалены',
  'settings.built_for': 'Сделано для ясности',

  // Manage emotions
  'manage.title': 'Управление эмоциями',
  'manage.add_to': 'Добавить в «{n}»',
  'manage.emotion_name_hint': 'Название эмоции',

  // Reminders
  'reminders.title': 'Напоминания',
  'reminders.empty.title': 'Пока нет напоминаний',
  'reminders.empty.body':
      'Добавьте напоминание, чтобы регулярно отмечать своё состояние.',
  'reminders.add': 'Добавить напоминание',
  'reminders.edit.title.new': 'Новое напоминание',
  'reminders.edit.title.edit': 'Изменить напоминание',
  'reminders.text': 'Текст уведомления',
  'reminders.time': 'Время',
  'reminders.recurrence': 'Периодичность',
  'reminders.enabled': 'Включено',
  'reminders.recurrence.once': 'Один раз',
  'reminders.recurrence.hourly': 'Каждые N часов',
  'reminders.recurrence.daily': 'Каждые N дней',
  'reminders.recurrence.weekly': 'Каждые N недель',
  'reminders.every_n_hours': 'Каждые {n} ч',
  'reminders.every_n_days': 'Каждые {n} дн',
  'reminders.every_n_weeks': 'Каждые {n} нед',
  'reminders.once_at': 'Однократно',
  'reminders.interval': 'Интервал',
  'reminders.default_text': 'Как вы себя чувствуете? Отметьте эмоции в дневнике.',
  'reminders.next_fire': 'Ближайшее: {n}',
  'reminders.delete_confirm.title': 'Удалить напоминание?',
  'reminders.delete_confirm.body': 'Уведомление больше не будет приходить.',
  'reminders.permission_denied':
      'В системе выключены уведомления для приложения — напоминания не придут. '
      'Включите их в настройках Android.',
  'reminders.save_failed': 'Не удалось сохранить напоминание',
};

const _en = <String, String>{
  'app.title': 'Mood Tracker',
  'common.cancel': 'Cancel',
  'common.delete': 'Delete',
  'common.add': 'Add',
  'common.save': 'Save',
  'common.done': 'Done',
  'common.now': 'Now',
  'common.no_data': 'No data yet',

  'top.settings': 'Settings',
  'top.toggle_theme': 'Toggle theme',

  'nav.record': 'Record',
  'nav.history': 'History',
  'nav.stats': 'Stats',

  'record.title': 'Feelings',
  'record.current_emotions': 'Current Emotions',
  'record.add_emotion': 'Add emotion',
  'record.intensity': 'Intensity',
  'record.mild': 'Mild',
  'record.intense': 'Intense',
  'record.what_happened': 'What happened?',
  'record.trigger_hint': 'The context or trigger...',
  'record.save_entry': 'Save Entry',
  'record.history_footer': 'History',
  'record.saved': 'Entry saved',

  'picker.how_are_you': 'How are you feeling?',
  'picker.search_hint': 'Search emotions...',
  'picker.select_all': 'Select all',

  'history.title': 'History',
  'history.all_categories': 'All categories',
  'history.uncategorized': 'Uncategorized',
  'history.period.last7': 'Last 7 days',
  'history.period.last30': 'Last 30 days',
  'history.period.last365': 'Last year',
  'history.period.all': 'All time',
  'history.empty': 'Your entries will appear here',
  'history.day.today': 'Today',
  'history.day.yesterday': 'Yesterday',
  'history.intensity_label': 'Intensity',

  'stats.title': 'Statistics',
  'stats.period.week': 'Week',
  'stats.period.month': 'Month',
  'stats.period.year': 'Year',
  'stats.period.all': 'All',
  'stats.total_entries': 'Total entries',
  'stats.avg_intensity': 'Avg Intensity',
  'stats.top_emotion': 'Top Emotion',
  'stats.intensity_trend': 'Intensity Trend',
  'stats.last_7_days': 'Last 7 days',
  'stats.frequency': 'Frequency',
  'stats.context': 'Context',
  'stats.emotion_type': 'Emotion Type',
  'stats.no_data': 'No data yet',
  'stats.no_context': 'No recurring context found',
  'stats.positive': 'Positive',
  'stats.neutral': 'Neutral',
  'stats.negative': 'Negative',
  'stats.focus': 'Focus',

  'settings.title': 'Settings',
  'settings.appearance': 'Appearance',
  'settings.theme': 'Theme',
  'settings.theme.light': 'Light',
  'settings.theme.dark': 'Dark',
  'settings.theme.system': 'System',
  'settings.language': 'Language',
  'settings.reminders': 'Reminders',
  'settings.reminders.manage': 'Manage reminders',
  'settings.reminders.hint':
      'Create any number of reminders with custom text, time and recurrence.',
  'settings.data': 'Data',
  'settings.manage_emotions': 'Manage Emotions',
  'settings.export_csv': 'Export to CSV',
  'settings.import_csv': 'Import from CSV',
  'settings.delete_all': 'Delete all data',
  'settings.delete_confirm.title': 'Delete all data?',
  'settings.delete_confirm.body':
      'This permanently removes every entry. This cannot be undone.',
  'settings.msg.export_ready': 'Export ready',
  'settings.msg.export_failed': 'Export failed',
  'settings.msg.import_cancelled': 'Import cancelled',
  'settings.msg.import_ok': 'Imported {n} entries',
  'settings.msg.import_failed': 'Import failed',
  'settings.msg.deleted': 'All data deleted',
  'settings.built_for': 'Built for Clarity',

  'manage.title': 'Manage Emotions',
  'manage.add_to': 'Add to {n}',
  'manage.emotion_name_hint': 'Emotion name',

  'reminders.title': 'Reminders',
  'reminders.empty.title': 'No reminders yet',
  'reminders.empty.body':
      'Add a reminder to check in with your feelings regularly.',
  'reminders.add': 'Add reminder',
  'reminders.edit.title.new': 'New reminder',
  'reminders.edit.title.edit': 'Edit reminder',
  'reminders.text': 'Notification text',
  'reminders.time': 'Time',
  'reminders.recurrence': 'Recurrence',
  'reminders.enabled': 'Enabled',
  'reminders.recurrence.once': 'Once',
  'reminders.recurrence.hourly': 'Every N hours',
  'reminders.recurrence.daily': 'Every N days',
  'reminders.recurrence.weekly': 'Every N weeks',
  'reminders.every_n_hours': 'Every {n} h',
  'reminders.every_n_days': 'Every {n} d',
  'reminders.every_n_weeks': 'Every {n} w',
  'reminders.once_at': 'Once',
  'reminders.interval': 'Interval',
  'reminders.default_text': 'How are you feeling? Log your emotions.',
  'reminders.next_fire': 'Next: {n}',
  'reminders.delete_confirm.title': 'Delete reminder?',
  'reminders.delete_confirm.body': 'You will no longer receive this notification.',
  'reminders.permission_denied':
      'Notifications are disabled for this app at the OS level — reminders '
      "won't be delivered. Enable them in Android settings.",
  'reminders.save_failed': 'Failed to save reminder',
};
