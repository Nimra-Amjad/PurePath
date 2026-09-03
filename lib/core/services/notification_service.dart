import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
//
// Thin wrapper around `flutter_local_notifications` that exposes the only
// three things the rest of the app needs:
//
//   1. initialize()          — set up the plugin, channel, and timezone
//   2. requestPermission()   — ask the OS once at app start
//   3. scheduleHabits(...)   — replace every scheduled habit reminder with
//                              the latest list (cancel-then-schedule)
//   4. cancelAll()           — wipe everything (logout, master toggle off)
//
// Everything below those four entry points is private.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  static const String _channelId = 'habit_reminders';
  static const String _channelName = 'Habit Reminders';
  static const String _channelDescription =
      'Notifications for your daily and weekly habits';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ── Setup ──────────────────────────────────────────────────────────────────

  /// Initializes the plugin once. Subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.local);

      await _plugin.initialize(_initSettings());
      await _createChannel();

      _isInitialized = true;
      debugPrint('NotificationService initialized');
    } catch (e) {
      debugPrint('NotificationService.initialize error: $e');
    }
  }

  /// Asks the OS for permission to post notifications. Safe to call multiple
  /// times — the OS dialog is shown the first time and the cached answer is
  /// returned thereafter.
  Future<bool> requestPermission() async {
    try {
      if (Platform.isIOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await android?.requestNotificationsPermission();
        return granted ?? true;
      }

      return true;
    } catch (e) {
      debugPrint('NotificationService.requestPermission error: $e');
      return false;
    }
  }

  // ── Scheduling ─────────────────────────────────────────────────────────────

  /// Replaces every scheduled habit reminder with one entry per habit that has
  /// its reminder turned on and a valid `reminderTime`. Fires every day for
  /// [HabitSchedule.everyDay], on each selected weekday for
  /// [HabitSchedule.weekDays], and on each selected day of the month for
  /// [HabitSchedule.monthDays]. Habits with the reminder toggle off are skipped.
  Future<void> scheduleHabits(List<HabitDefinition> habits) async {
    if (!_isInitialized) await initialize();

    await cancelAll();

    for (final habit in habits) {
      if (!habit.reminderEnabled) continue;
      final time = _parseTime(habit.reminderTime);
      if (time == null) continue;

      try {
        switch (habit.schedule) {
          case HabitSchedule.everyDay:
            await _scheduleDaily(habit, time);
            break;
          case HabitSchedule.weekDays:
            await _scheduleWeekly(habit, time);
            break;
          case HabitSchedule.monthDays:
            await _scheduleMonthly(habit, time);
            break;
        }
      } catch (e) {
        debugPrint('Failed to schedule "${habit.title}": $e');
      }
    }
  }

  /// Cancels every scheduled notification this app owns.
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService.cancelAll error: $e');
    }
  }

  // ── Internals: scheduling ──────────────────────────────────────────────────

  Future<void> _scheduleDaily(HabitDefinition habit, TimeOfDay time) {
    return _plugin.zonedSchedule(
      _idFor(habit.id),
      'Time for ${habit.title}',
      _bodyFor(habit),
      _nextInstanceOfTime(time),
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'habit:${habit.id}',
    );
  }

  Future<void> _scheduleWeekly(HabitDefinition habit, TimeOfDay time) async {
    // weekDays: 0 = Mon … 6 = Sun. DateTime.weekday: 1 = Mon … 7 = Sun.
    for (final dayIndex in habit.weekDays) {
      final weekday = dayIndex + 1;
      await _plugin.zonedSchedule(
        _idFor(habit.id, dayIndex),
        'Time for ${habit.title}',
        _bodyFor(habit),
        _nextInstanceOfWeekday(weekday, time),
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'habit:${habit.id}',
      );
    }
  }

  Future<void> _scheduleMonthly(HabitDefinition habit, TimeOfDay time) async {
    // monthDays: 1 … 31 (calendar date of the month).
    for (final monthDay in habit.monthDays) {
      await _plugin.zonedSchedule(
        _idFor(habit.id, monthDay),
        'Time for ${habit.title}',
        _bodyFor(habit),
        _nextInstanceOfMonthDay(monthDay, time),
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        payload: 'habit:${habit.id}',
      );
    }
  }

  // ── Internals: configuration ───────────────────────────────────────────────

  InitializationSettings _initSettings() {
    return const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(
        // We request permission explicitly via [requestPermission] so the
        // user-facing prompt fires at a deliberate moment, not on plugin init.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
  }

  Future<void> _createChannel() async {
    const habitChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(habitChannel);
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: Color(0xFF9B82E8),
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
      ),
    );
  }

  String _bodyFor(HabitDefinition habit) {
    return 'Tap to mark it as done.';
  }

  // ── Internals: helpers ─────────────────────────────────────────────────────

  /// Maps a Firestore habit id to a stable positive 31-bit int used by the
  /// platform scheduler. Weekly habits add their weekday index (0..6) and
  /// monthly habits add their day-of-month (1..31) on top; the base is
  /// multiplied by 40 to leave room for either offset without overflowing
  /// a signed 32-bit int.
  int _idFor(String habitId, [int dayOffset = 0]) {
    final base = (habitId.hashCode & 0x01FFFFFF) * 40;
    return base + dayOffset;
  }

  /// Parses strings produced by [TimeOfDay.format], which may be 12-hour
  /// ("7:30 AM") or 24-hour ("19:30") depending on the device locale.
  TimeOfDay? _parseTime(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final ampm = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$',
    ).firstMatch(value);
    if (ampm != null) {
      var hour = int.tryParse(ampm.group(1)!) ?? 0;
      final minute = int.tryParse(ampm.group(2)!) ?? 0;
      final isPm = ampm.group(3)!.toUpperCase() == 'PM';
      if (hour == 12) hour = 0;
      if (isPm) hour += 12;
      return TimeOfDay(hour: hour, minute: minute);
    }

    final h24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (h24 != null) {
      final hour = int.tryParse(h24.group(1)!) ?? 0;
      final minute = int.tryParse(h24.group(2)!) ?? 0;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return TimeOfDay(hour: hour, minute: minute);
    }

    return null;
  }

  /// Builds the next absolute moment that matches [time] in the device's
  /// local clock.
  ///
  /// `tz.local` defaults to UTC unless the IANA name is set externally.
  /// Constructing the schedule directly from `tz.local` values would treat
  /// "7:30 PM" as UTC. Building a local `DateTime` first and converting via
  /// `tz.TZDateTime.from` produces the correct absolute instant for the
  /// device's wall clock regardless of what `tz.local` is.
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = DateTime.now();
    final local =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    var scheduled = tz.TZDateTime.from(local, tz.local);
    final nowTz = tz.TZDateTime.now(tz.local);
    if (!scheduled.isAfter(nowTz)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, TimeOfDay time) {
    var scheduled = _nextInstanceOfTime(time);
    while (scheduled.toLocal().weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// The next absolute moment matching [monthDay] (1..31) at [time]. Walks
  /// forward a day at a time so months without that date (e.g. day 31 in
  /// February) are simply skipped to the next month that has it.
  tz.TZDateTime _nextInstanceOfMonthDay(int monthDay, TimeOfDay time) {
    var scheduled = _nextInstanceOfTime(time);
    while (scheduled.toLocal().day != monthDay) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
