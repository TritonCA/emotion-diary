import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
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
  // Concurrent-safe one-shot init: every caller awaits the same future.
  Future<bool>? _initFuture;
  bool _initialized = false;

  static const _channelId = 'reminders';
  static const _channelName = 'Reminders';
  static const _channelDesc = 'Custom mood-tracker reminders';

  /// Returns true if the plugin is ready (channel created, tz set).
  /// Safe to call multiple times concurrently — only one real init runs.
  Future<bool> init() => _initFuture ??= _doInit();

  Future<bool> _doInit() async {
    try {
      tz_data.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (e) {
        // Fine — tz.local stays UTC. Scheduling uses absolute instants via
        // TZDateTime.from(), so wall-clock firing time is preserved even when
        // tz.local doesn't match the device. matchDateTimeComponents repeats
        // also stay consistent because they re-match against the same Location.
        if (kDebugMode) debugPrint('local tz lookup failed: $e');
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      final ok = await _plugin.initialize(settings);
      if (ok == false) {
        if (kDebugMode) debugPrint('plugin.initialize returned false');
      }

      if (Platform.isAndroid) {
        try {
          final androidImpl = _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          await androidImpl?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDesc,
              importance: Importance.high,
            ),
          );
          // Best-effort permission requests; user may still deny.
          await androidImpl?.requestNotificationsPermission();
          try {
            await androidImpl?.requestExactAlarmsPermission();
          } catch (_) {
            // OS may refuse to even open the screen on some devices.
          }
        } catch (e) {
          if (kDebugMode) debugPrint('channel/perm setup failed: $e');
        }
      }

      _initialized = true;
      return true;
    } catch (e, st) {
      if (kDebugMode) debugPrint('NotificationService.init failed: $e\n$st');
      _initialized = false;
      return false;
    }
  }

  /// Are notifications currently enabled at OS level? Returns true on
  /// non-Android or when we can't tell (treat as "no warning").
  Future<bool> isNotificationsEnabled() async {
    if (!_initialized || !Platform.isAndroid) return true;
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> cancel(int id) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id);
    } catch (e) {
      if (kDebugMode) debugPrint('cancel $id failed: $e');
    }
  }

  /// Cancels every pending notification owned by this app. Safe to call even
  /// when only some reminders changed — the next [rescheduleAll] re-creates
  /// the rest.
  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      if (kDebugMode) debugPrint('cancelAll failed: $e');
    }
  }

  /// (Re)schedule every enabled reminder. A failure for one reminder doesn't
  /// stop the rest.
  Future<void> rescheduleAll(List<Reminder> reminders) async {
    if (!_initialized) return;
    await cancelAll();
    for (final r in reminders) {
      if (!r.enabled) continue;
      try {
        await _schedule(r);
      } catch (e, st) {
        if (kDebugMode) debugPrint('schedule reminder ${r.id} failed: $e\n$st');
      }
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
    } on PlatformException catch (e) {
      // Exact alarms not permitted on Android 12+ → retry inexact.
      if (kDebugMode) debugPrint('exact schedule failed (${e.code}): $e');
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

  /// Computes the next firing moment >= now for a reminder. Returns null when
  /// it cannot fire at all (one-shot in the past).
  static DateTime? nextFire(Reminder r) => _nextFire(r);

  static DateTime? _nextFire(Reminder r) {
    final now = DateTime.now();
    // Legacy reminders stored without an anchor still work via today-HH:MM.
    final DateTime anchor = r.anchor ?? _atTimeToday(now, r.hour, r.minute);

    switch (r.recurrence) {
      case ReminderRecurrence.once:
        return anchor.isAfter(now) ? anchor : null;
      case ReminderRecurrence.hourly:
        return _nextAfter(anchor, now, Duration(hours: r.every.clamp(1, 24 * 30)));
      case ReminderRecurrence.daily:
        return _nextAfter(anchor, now, Duration(days: r.every.clamp(1, 365)));
      case ReminderRecurrence.weekly:
        return _nextAfter(anchor, now, Duration(days: 7 * r.every.clamp(1, 52)));
    }
  }

  static DateTime _atTimeToday(DateTime now, int h, int m) =>
      DateTime(now.year, now.month, now.day, h, m);

  static DateTime _nextAfter(DateTime anchor, DateTime now, Duration step) {
    if (step.inMicroseconds <= 0) return anchor;
    if (anchor.isAfter(now)) return anchor;
    // Jump in O(1) instead of looping for far-past anchors.
    final delta = now.difference(anchor).inMicroseconds;
    final steps = (delta ~/ step.inMicroseconds) + 1;
    return anchor.add(step * steps);
  }
}
