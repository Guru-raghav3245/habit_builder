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

  static Future<void> init() async {
    // Initialize timezone database, but we will use the default local location
    tz.initializeTimeZones();
    // No external package lookup - just use the environment's default
    tz.setLocalLocation(tz.local);

    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings settings = InitializationSettings(
      android: android,
    );

    await _notifications.initialize(settings);

    // Request necessary permissions for Android 12+ and 13+
    if (Platform.isAndroid) {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  static Future<void> scheduleDailyReminder(
    Habit habit,
    int notificationId,
  ) async {
    if (!habit.reminderEnabled) {
      await cancelReminder(notificationId);
      return;
    }

    // Get current device time
    final now = DateTime.now();
    
    // Create a DateTime for today at the habit's start time
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      habit.startTime.hour,
      habit.startTime.minute,
    );

    // If that time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Convert our local DateTime to TZDateTime for the notification plugin
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notifications.zonedSchedule(
      notificationId,
      'Time for ${habit.name}!',
      'Start your ${habit.durationMinutes}-minute session now.',
      tzScheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelReminder(int notificationId) async {
    await _notifications.cancel(notificationId);
  }

  static Future<void> testAlarm() async {
    await _notifications.show(
      999,
      'Test Alarm',
      'This is a test of your device time settings.',
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