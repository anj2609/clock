import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/alarm.dart';
import '../utils/constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      tz_data.initializeTimeZones();
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName.identifier));
    } catch (e) {
      developer.log('Failed to initialize timezone: $e', name: 'NotificationService');
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    await _createNotificationChannel();
  }

  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
  }

  static Future<void> scheduleAlarm(Alarm alarm) async {
    if (!alarm.isEnabled) return;

    final parts = alarm.time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final notificationId = alarm.id.hashCode;

    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    const details = NotificationDetails(android: androidDetails);

    if (alarm.repeatDays.isNotEmpty) {
      for (final day in alarm.repeatDays) {
        final scheduledDate = _nextDayOfWeek(day + 1, hour, minute);
        final dayNotificationId = '${alarm.id}_$day'.hashCode;

        await _plugin.zonedSchedule(
          dayNotificationId,
          alarm.label.isEmpty ? AppConstants.appName : alarm.label,
          alarm.time,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } else {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        notificationId,
        alarm.label.isEmpty ? AppConstants.appName : alarm.label,
        alarm.time,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static tz.TZDateTime _nextDayOfWeek(int dayOfWeek, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static Future<void> cancelAlarm(String alarmId) async {
    final notificationId = alarmId.hashCode;
    await _plugin.cancel(notificationId);

    for (int day = 0; day < 7; day++) {
      final dayNotificationId = '${alarmId}_$day'.hashCode;
      await _plugin.cancel(dayNotificationId);
    }
  }

  static Future<void> cancelAllAlarms() async {
    await _plugin.cancelAll();
  }

  static Future<void> initializeFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      developer.log('FCM Token: $token', name: 'NotificationService');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          _plugin.show(
            notification.hashCode,
            notification.title ?? AppConstants.appName,
            notification.body ?? '',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                AppConstants.notificationChannelId,
                AppConstants.notificationChannelName,
                channelDescription: AppConstants.notificationChannelDescription,
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log(
          'Message opened app: ${message.messageId}',
          name: 'NotificationService',
        );
      });
    } catch (e) {
      developer.log('FCM Initialization failed (likely missing config): $e',
          name: 'NotificationService');
    }
  }
}

