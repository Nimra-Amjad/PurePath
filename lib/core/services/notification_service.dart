import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
//
// Wraps `flutter_local_notifications` and exposes habit-aware helpers:
//   • initializePlatformNotifications() — sets up plugin + channels + tz
//   • requestNotificationPermission()   — asks the OS once on app start
//   • scheduleHabitNotifications(...)   — schedules reminders for every habit
//                                         that has a non-empty reminderTime
//   • cancelAllHabitNotifications()     — wipes every scheduled habit reminder
//
// Notification ids are derived from the habit id so reschedules upsert
// rather than producing duplicates.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const String _habitChannelId = 'habit_reminders';
  static const String _habitChannelName = 'Habit Reminders';
  static const String _habitChannelDescription =
      'Notifications for your daily and weekly habits';

  bool isInitialized = false;

  // ── Setup ──────────────────────────────────────────────────────────────────

  Future<void> initializePlatformNotifications() async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      tz.initializeTimeZones();
      tz.setLocalLocation(tz.local);

      await _createHabitChannel();

      final result = await _localNotifications.initialize(initSettings);

      isInitialized = result ?? false;
      debugPrint('NotificationService initialized: $isInitialized');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  Future<void> _createHabitChannel() async {
    try {
      const channel = AndroidNotificationChannel(
        _habitChannelId,
        _habitChannelName,
        description: _habitChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('Error creating habit channel: $e');
    }
  }

  // ── Permissions ────────────────────────────────────────────────────────────

  Future<bool> requestNotificationPermission() async {
    try {
      if (Platform.isIOS) {
        final ios = _localNotifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      } else if (Platform.isAndroid) {
        final android = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await android?.requestNotificationsPermission();
        // Also ask for exact alarm permission on Android 12+, best-effort.
        await android?.requestExactAlarmsPermission();
        return granted ?? true;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  // ── Scheduling ─────────────────────────────────────────────────────────────

  /// Schedules a recurring reminder for every habit with a non-empty
  /// [HabitDefinition.reminderTime]. Daily habits fire every day at the
  /// reminder time; weekly habits fire on each selected weekday.
  ///
  /// Cancels any previously scheduled habit reminders first so callers can
  /// safely call this whenever the habit list changes.
  Future<void> scheduleHabitNotifications(List<HabitDefinition> habits) async {
    if (!isInitialized) {
      await initializePlatformNotifications();
    }

    await cancelAllHabitNotifications();

    for (final habit in habits) {
      if (habit.reminderTime.trim().isEmpty) continue;
      final time = _parseReminderTime(habit.reminderTime);
      if (time == null) continue;

      try {
        if (habit.isDaily) {
          await _scheduleDailyHabit(habit: habit, time: time);
        } else {
          await _scheduleWeeklyHabit(habit: habit, time: time);
        }
      } catch (e) {
        debugPrint('Error scheduling notification for ${habit.title}: $e');
      }
    }
  }

  Future<void> _scheduleDailyHabit({
    required HabitDefinition habit,
    required TimeOfDay time,
  }) async {
    final scheduled = _nextInstanceOfTime(time);
    final id = _baseIdForHabit(habit.id);

    await _localNotifications.zonedSchedule(
      id,
      'Time for ${habit.title}',
      _bodyForHabit(habit),
      scheduled,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'habit:${habit.id}',
    );
  }

  Future<void> _scheduleWeeklyHabit({
    required HabitDefinition habit,
    required TimeOfDay time,
  }) async {
    // weekDays uses 0=Mon … 6=Sun; DateTime.weekday uses 1=Mon … 7=Sun.
    for (final dayIndex in habit.weekDays) {
      final weekday = dayIndex + 1;
      final scheduled = _nextInstanceOfWeekday(weekday, time);
      final id = _baseIdForHabit(habit.id) + dayIndex;

      await _localNotifications.zonedSchedule(
        id,
        'Time for ${habit.title}',
        _bodyForHabit(habit),
        scheduled,
        _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'habit:${habit.id}',
      );
    }
  }

  // ── Cancellation ───────────────────────────────────────────────────────────

  Future<void> cancelAllHabitNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling habit notifications: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      _habitChannelId,
      _habitChannelName,
      channelDescription: _habitChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: Color(0xFF9B82E8),
    );
    const ios = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );
    return const NotificationDetails(android: android, iOS: ios);
  }

  String _bodyForHabit(HabitDefinition habit) {
    if (habit.goal.trim().isNotEmpty) {
      return 'Goal: ${habit.goal}';
    }
    return 'Tap to mark it as done.';
  }

  /// Maps an arbitrary habit doc id to a stable positive 31-bit int so the
  /// underlying scheduler can identify it for cancel/reschedule.
  /// Weekly habits add their weekday index (0..6) on top, so we leave a
  /// 7-slot gap by multiplying the base by 8.
  int _baseIdForHabit(String habitId) {
    final hash = habitId.hashCode & 0x0FFFFFFF; // keep it positive
    return hash * 8;
  }

  /// Parses strings produced by [TimeOfDay.format], e.g. "7:30 AM" or "19:30".
  TimeOfDay? _parseReminderTime(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    // 12-hour with AM/PM
    final ampm = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$',
    ).firstMatch(value);
    if (ampm != null) {
      var hour = int.tryParse(ampm.group(1) ?? '') ?? 0;
      final minute = int.tryParse(ampm.group(2) ?? '') ?? 0;
      final isPm = ampm.group(3)!.toUpperCase() == 'PM';
      if (hour == 12) hour = 0;
      if (isPm) hour += 12;
      return TimeOfDay(hour: hour, minute: minute);
    }

    // 24-hour
    final h24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (h24 != null) {
      final hour = int.tryParse(h24.group(1) ?? '') ?? 0;
      final minute = int.tryParse(h24.group(2) ?? '') ?? 0;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return TimeOfDay(hour: hour, minute: minute);
    }

    return null;
  }

  /// Builds the next absolute moment that matches [time] in the device's
  /// local clock.
  ///
  /// `tz.local` defaults to UTC unless [flutter_timezone] (or similar) sets
  /// the IANA name. Constructing the schedule directly with `tz.local`
  /// values would treat the user's "7:30 PM" as 7:30 PM UTC. Instead we
  /// build a *local* `DateTime` (which Dart anchors to the device's clock)
  /// and let `tz.TZDateTime.from` convert it to the right absolute instant.
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = DateTime.now();
    final localScheduled =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    var scheduled = tz.TZDateTime.from(localScheduled, tz.local);
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
}
