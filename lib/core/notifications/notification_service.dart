import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/reminders/domain/entities/reminder.dart';

/// Wraps `flutter_local_notifications`. Owns: timezone init, channel creation,
/// scheduling, cancellation. UI/cubits depend on this — never on the plugin.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'reminders';
  static const _channelName = 'Reminders';
  static const _channelDesc = 'Custom mood-tracker reminders';

  Future<void> init() async {
    if (_ready) return;
    _ready = true;

    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fall back to UTC — schedule still works, just shifted.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    if (Platform.isAndroid) {
      final android =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ));
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    }
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  /// (Re)schedule every enabled reminder. Once-shot reminders whose moment has
  /// passed are skipped silently.
  Future<void> rescheduleAll(List<Reminder> reminders) async {
    if (!_ready) return;
    await cancelAll();
    for (final r in reminders) {
      if (!r.enabled) continue;
      await _schedule(r);
    }
  }

  Future<void> _schedule(Reminder r) async {
    final next = _nextFire(r);
    if (next == null) return;
    final tzNext = tz.TZDateTime.from(next, tz.local);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    final match = switch (r.recurrence) {
      ReminderRecurrence.daily when r.every == 1 => DateTimeComponents.time,
      ReminderRecurrence.weekly when r.every == 1 =>
        DateTimeComponents.dayOfWeekAndTime,
      _ => null,
    };

    try {
      await _plugin.zonedSchedule(
        r.id,
        null,
        r.text,
        tzNext,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: match,
      );
    } catch (e) {
      // Exact alarms may be denied; fall back to inexact.
      if (kDebugMode) debugPrint('schedule exact failed: $e');
      await _plugin.zonedSchedule(
        r.id,
        null,
        r.text,
        tzNext,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: match,
      );
    }
  }

  /// Computes the next firing moment >= now for a reminder. Returns null if
  /// it is a [ReminderRecurrence.once] whose anchor is already in the past.
  static DateTime? nextFire(Reminder r) => _nextFire(r);

  static DateTime? _nextFire(Reminder r) {
    final now = DateTime.now();
    switch (r.recurrence) {
      case ReminderRecurrence.once:
        final base = r.anchor ?? _atTimeToday(now, r.hour, r.minute);
        return base.isBefore(now) ? null : base;
      case ReminderRecurrence.hourly:
        final anchor = r.anchor ?? _atTimeToday(now, r.hour, r.minute);
        return _nextAfter(anchor, now, Duration(hours: r.every.clamp(1, 24 * 30)));
      case ReminderRecurrence.daily:
        final anchor = r.anchor ?? _atTimeToday(now, r.hour, r.minute);
        return _nextAfter(anchor, now, Duration(days: r.every.clamp(1, 365)));
      case ReminderRecurrence.weekly:
        final anchor = r.anchor ?? _atTimeToday(now, r.hour, r.minute);
        return _nextAfter(anchor, now, Duration(days: 7 * r.every.clamp(1, 52)));
    }
  }

  static DateTime _atTimeToday(DateTime now, int h, int m) =>
      DateTime(now.year, now.month, now.day, h, m);

  static DateTime _nextAfter(DateTime anchor, DateTime now, Duration step) {
    var t = anchor;
    if (step.inMicroseconds <= 0) return t;
    while (!t.isAfter(now)) {
      t = t.add(step);
    }
    return t;
  }
}
