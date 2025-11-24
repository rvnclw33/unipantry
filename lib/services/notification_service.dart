import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();

    // 2. Android
    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS
    const fln.DarwinInitializationSettings initializationSettingsIOS =
        fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const fln.InitializationSettings initializationSettings = fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // --- IMMEDIATE NOTIFICATION ---
  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      _notificationDetails(),
    );
  }

  // --- SCHEDULED NOTIFICATION ---
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      _notificationDetails(),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  fln.NotificationDetails _notificationDetails() {
    return const fln.NotificationDetails(
      android: fln.AndroidNotificationDetails(
        'pantry_channel_id',
        'Pantry Notifications',
        channelDescription: 'Notifications for food expiry',
        importance: fln.Importance.max,
        priority: fln.Priority.high,
      ),
      iOS: fln.DarwinNotificationDetails(),
    );
  }
}