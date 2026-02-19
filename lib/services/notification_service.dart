import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:habitit/models/habit.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'daily_habits_channel';
  static const String _channelName = 'Daily Habit Reminders';
  static const String _channelDescription = 'Reminders for your habits';

  static const String _notificationIcon = '@mipmap/ic_launcher';

  static Future<void> init() async {
    print('🔔 [NotificationService] init() called');

    tz.initializeTimeZones();

    const AndroidInitializationSettings android =
        AndroidInitializationSettings(_notificationIcon);

    const InitializationSettings settings = InitializationSettings(
      android: android,
    );

    await _notifications.initialize(settings);
    print('🔔 [NotificationService] notifications.initialize done');

    if (Platform.isAndroid) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final notifPermissionGranted =
          await androidImplementation?.requestNotificationsPermission();
      print(
          '🔔 [NotificationService] requestNotificationsPermission -> $notifPermissionGranted');

      final exactGranted =
          await androidImplementation?.requestExactAlarmsPermission();
      final canExact =
          await androidImplementation?.canScheduleExactNotifications() ?? false;
      print(
          '🔔 [NotificationService] requestExactAlarmsPermission -> $exactGranted, canScheduleExactNotifications -> $canExact');

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await androidImplementation?.createNotificationChannel(channel);
      print('🔔 [NotificationService] NotificationChannel created');
    }
  }

  static Future<void> scheduleDailyReminder(Habit habit) async {
    final int baseId = habit.id.hashCode;

    print(
        '🔔 [NotificationService] scheduleDailyReminder for "${habit.name}" '
        '(id=${habit.id}, baseId=$baseId, reminderEnabled=${habit.reminderEnabled}, archived=${habit.isArchived})');

    await cancelAllHabitReminders(habit.id);

    if (!habit.reminderEnabled || habit.isArchived) {
      print(
          '🔔 [NotificationService] Skipping schedule for "${habit.name}" because reminderEnabled=${habit.reminderEnabled}, isArchived=${habit.isArchived}');
      return;
    }

    final now = DateTime.now();
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      habit.startTime.hour,
      habit.startTime.minute,
    );

    print(
        '🔔 [NotificationService] Today\'s startTime for "${habit.name}" -> $startTime (now=$now)');

    await _zonedSchedule(
      baseId + 1,
      'Almost time!',
      '${habit.name} starts in 5 minutes.',
      startTime.subtract(const Duration(minutes: 5)),
    );

    await _zonedSchedule(
      baseId,
      'Time for ${habit.name}!',
      'Start your ${habit.durationMinutes}-minute session now.',
      startTime,
    );

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
    final now = DateTime.now();
    var finalTime = scheduledTime;

    if (finalTime.isBefore(now)) {
      finalTime = finalTime.add(const Duration(days: 1));
      print(
        '🔔 [NotificationService] _zonedSchedule(id=$id) '
        'scheduledTime=$scheduledTime is in the past (now=$now) – shifting to next day -> $finalTime',
      );
    } else {
      print(
        '🔔 [NotificationService] _zonedSchedule(id=$id) '
        'scheduledTime=$scheduledTime (now=$now)',
      );
    }

    const AndroidScheduleMode androidScheduleMode =
        AndroidScheduleMode.exactAllowWhileIdle;
    print(
        '🔔 [NotificationService] _zonedSchedule(id=$id) using mode=$androidScheduleMode');

    final tzScheduledDate = tz.TZDateTime.from(finalTime, tz.local);
    print(
        '🔔 [NotificationService] Calling plugin.zonedSchedule(id=$id, time=$tzScheduledDate)');

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
          icon: _notificationIcon,
        ),
      ),
      androidScheduleMode: androidScheduleMode,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    print(
        '🔔 [NotificationService] _zonedSchedule(id=$id) scheduled at $tzScheduledDate');
  }

  static Future<void> cancelAllHabitReminders(String habitId) async {
    final int baseId = habitId.hashCode;
    print(
        '🔔 [NotificationService] cancelAllHabitReminders for habitId=$habitId (baseId=$baseId)');
    await _notifications.cancel(baseId);
    await _notifications.cancel(baseId + 1);
    await _notifications.cancel(baseId + 2);
  }

  static Future<void> cancelLateReminder(String habitId) async {
    final int baseId = habitId.hashCode;
    final int lateId = baseId + 2;
    print(
        '🔔 [NotificationService] cancelLateReminder for habitId=$habitId (id=$lateId)');
    await _notifications.cancel(lateId);
  }

  static Future<void> testAlarm() async {
    print('🔔 [NotificationService] testAlarm() called');
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
          icon: _notificationIcon,
        ),
      ),
    );
    print('🔔 [NotificationService] testAlarm() notification.show() done');
  }

// Add this method inside the NotificationService class in lib/services/notification_service.dart

static Future<void> testScheduleNextMinute() async {
  final now = DateTime.now();
  // Set the time to the 00 second mark of the next minute
  final nextMinute = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute + 1,
  );
  
  print('🔔 [NotificationService] testScheduleNextMinute at $nextMinute');

  // Uses the existing _zonedSchedule function to handle timezone logic
  await _zonedSchedule(
    123456, // Unique ID for this test
    'Next Minute Test',
    'This notification was scheduled for the start of the next minute.',
    nextMinute,
  );
}

  static Future<void> testScheduleInOneMinute() async {
    final now = DateTime.now();
    final inOneMinute = now.add(const Duration(minutes: 1));
    print(
        '🔔 [NotificationService] testScheduleInOneMinute at (local) $inOneMinute');

    final tzDate = tz.TZDateTime.from(inOneMinute, tz.local);
    print('🔔 [NotificationService] testScheduleInOneMinute tzDate=$tzDate');

    await _notifications.zonedSchedule(
      987654,
      'Plain Schedule Test',
      'Testing scheduled notification in 1 minute (exact, one-shot)',
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: _notificationIcon,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime
    );

    print(
        '🔔 [NotificationService] testScheduleInOneMinute scheduled at $tzDate');
  }
}
