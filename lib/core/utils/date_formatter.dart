import 'package:intl/intl.dart';

/// Date helpers shared across History/Stats. Pure, UI-agnostic.
class DateFormatter {
  const DateFormatter._();

  static String time(DateTime d) => DateFormat('HH:mm').format(d);

  static String fullDate(DateTime d) => DateFormat('d MMM yyyy, HH:mm').format(d);

  static String dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEEE, d MMM').format(d);
  }

  static String weekdayShort(DateTime d) => DateFormat('EEE').format(d);
}
