import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:habit_builder/models/habit.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'daily_habits_channel';
  static const String _channelName = 'Daily Habit Reminders';
  static const String _channelDescription = 'Reminders for your habits';

  static Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings settings = InitializationSettings(
      android: android,
    );

    await _notifications.initialize(settings);

    if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await androidImplementation?.createNotificationChannel(channel);
    }
  }

  /// Schedules 3 notifications for a single habit:
  /// 1. 5 minutes before start
  /// 2. Exactly at start
  /// 3. 5 minutes after start (if not already in app)
  static Future<void> scheduleDailyReminder(Habit habit) async {
    // Use hashCode of the unique ID as the base for notification IDs
    final int baseId = habit.id.hashCode;

    // Always clear existing ones first
    await cancelAllHabitReminders(habit.id);

    if (!habit.reminderEnabled || habit.isArchived) return;

    final now = DateTime.now();
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      habit.startTime.hour,
      habit.startTime.minute,
    );

    // Notification 1: 5 Minutes Before
    await _zonedSchedule(
      baseId + 1,
      'Almost time!',
      '${habit.name} starts in 5 minutes. Get ready!',
      startTime.subtract(const Duration(minutes: 5)),
    );

    // Notification 2: At Start Time
    await _zonedSchedule(
      baseId,
      'Time for ${habit.name}!',
      'Start your ${habit.durationMinutes}-minute session now.',
      startTime,
    );

    // Notification 3: 5 Minutes After (The "Missed" reminder)
    await _zonedSchedule(
      baseId + 2,
      'Are you there?',
      'You haven\'t started your ${habit.name} session yet!',
      startTime.add(const Duration(minutes: 5)),
    );
  }

  static Future<void> _zonedSchedule(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    var finalTime = scheduledTime;
    // If the calculated time has already passed today, schedule for tomorrow
    if (finalTime.isBefore(DateTime.now())) {
      finalTime = finalTime.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(finalTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelAllHabitReminders(String habitId) async {
    final int baseId = habitId.hashCode;
    await _notifications.cancel(baseId); // Exact start
    await _notifications.cancel(baseId + 1); // 5 min before
    await _notifications.cancel(baseId + 2); // 5 min after
  }

  /// Called when user enters the focus timer to stop the "Late" reminder
  static Future<void> cancelLateReminder(String habitId) async {
    await _notifications.cancel(habitId.hashCode + 2);
  }

  static Future<void> testAlarm() async {
    await _notifications.show(
      999,
      'Test Alarm',
      'Sound and notifications are working!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
