import 'dart:convert';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import '../utils/time_utils.dart';

const _alarmDataKey = 'alarm_data_';

@pragma('vm:entry-point')
void alarmCallback(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final dataJson = prefs.getString('$_alarmDataKey$id');
  if (dataJson == null) return;

  final alarmMap = jsonDecode(dataJson) as Map<String, dynamic>;
  final alarm = Alarm.fromMap(alarmMap);

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  const androidDetails = AndroidNotificationDetails(
    'cyclic_alarm_channel',
    'Cyclic Alarm',
    channelDescription: 'Alarm notifications',
    importance: Importance.max,
    priority: Priority.max,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    ongoing: true,
    autoCancel: false,
    actions: [
      AndroidNotificationAction('snooze', 'Snooze'),
      AndroidNotificationAction('dismiss', 'Dismiss'),
    ],
  );

  await flutterLocalNotificationsPlugin.show(
    id,
    alarm.label.isEmpty ? 'Alarm' : alarm.label,
    'Time to wake up!',
    const NotificationDetails(android: androidDetails),
  );
}

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    const channel = AndroidNotificationChannel(
      'cyclic_alarm_channel',
      'Cyclic Alarm',
      description: 'Alarm notifications',
      importance: Importance.max,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _onNotificationResponse(NotificationResponse response) {
    // Notification actions (snooze/dismiss) are handled by the wake-up screen.
  }

  static Future<void> scheduleAlarm(Alarm alarm) async {
    if (!alarm.isEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    final alarmId = _alarmIdFromString(alarm.id);
    await prefs.setString(
        '$_alarmDataKey$alarmId', jsonEncode(alarm.toMap()));

    final nextTime =
        TimeUtils.getNextAlarmTime(alarm.hour, alarm.minute, alarm.repeatDays);
    if (nextTime == null) return;

    await AndroidAlarmManager.oneShotAt(
      nextTime,
      alarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
    );
  }

  static Future<void> cancelAlarm(String alarmId) async {
    final id = _alarmIdFromString(alarmId);
    await AndroidAlarmManager.cancel(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_alarmDataKey$id');
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static int _alarmIdFromString(String id) {
    return id.hashCode.abs() % 2147483647;
  }

  static Future<void> rescheduleAll(List<Alarm> alarms) async {
    for (final alarm in alarms) {
      if (alarm.isEnabled) {
        await scheduleAlarm(alarm);
      }
    }
  }
}
