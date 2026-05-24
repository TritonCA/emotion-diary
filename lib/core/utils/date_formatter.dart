import 'package:intl/intl.dart';
import '../l10n/app_locale.dart';

/// Date helpers shared across History/Stats. Pure, UI-agnostic. The current
/// locale is threaded explicitly so we don't depend on a global.
class DateFormatter {
  const DateFormatter._();

  static String time(DateTime d) => DateFormat('HH:mm').format(d);

  static String fullDate(DateTime d, {AppLocale locale = AppLocale.ru}) =>
      DateFormat('d MMM yyyy, HH:mm', locale.code).format(d);

  static String dayLabel(
    DateTime d, {
    AppLocale locale = AppLocale.ru,
    String? todayLabel,
    String? yesterdayLabel,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return todayLabel ?? 'Today';
    if (diff == 1) return yesterdayLabel ?? 'Yesterday';
    return DateFormat('EEEE, d MMM', locale.code).format(d);
  }

  static String weekdayShort(DateTime d, {AppLocale locale = AppLocale.ru}) =>
      DateFormat('EEE', locale.code).format(d);
}
