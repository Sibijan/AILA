import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleTaskReminder({
    required int id,
    required String taskName,
    required DateTime scheduledDateTime,
  }) async {
    final reminderTime = scheduledDateTime.subtract(const Duration(hours: 2));

    print('Reminder time (local): $reminderTime');
    print('Current time (local): ${DateTime.now()}');

    if (reminderTime.isBefore(DateTime.now())) {
      print('Reminder time is in the past, skipping');
      return;
    }

    final tzReminderTime = tz.TZDateTime(
      tz.UTC,
      reminderTime.year,
      reminderTime.month,
      reminderTime.day,
      reminderTime.hour,
      reminderTime.minute,
    ).subtract(DateTime.now().timeZoneOffset);

    print('TZ reminder time: $tzReminderTime');

    await _plugin.zonedSchedule(
      id,
      '⏰ Task Reminder',
      '$taskName is due in 2 hours!',
      tzReminderTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Reminders 2 hours before tasks',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print('Notification successfully scheduled!');
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}