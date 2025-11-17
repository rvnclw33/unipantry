// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton pattern to ensure only one instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Android initialization settings
    // 'app_icon' must exist in android/app/src/main/res/drawable
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    // --- THIS IS THE CORRECTED PART ---
    // We must explicitly tell iOS to show alerts, play sounds,
    // and update the badge *while the app is in the foreground*.
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      
      // 1. This requests permission from the user
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      
      // 2. THIS IS THE CRITICAL FIX
      // These force the notification to appear even if the app is open
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS, // Use the new, corrected settings
    );

    // This initializes the plugin with our settings
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Function to show a simple notification
  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0, // ID for the notification
  }) async {
    
    // 1. Android Details
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pantry_channel_id', // Channel ID
      'Pantry Notifications', // Channel Name
      channelDescription: 'Notifications about food items',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    // 2. iOS Details
    const DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,  // Required to show a visual alert
      presentBadge: true,  // Required to update the app badge
      presentSound: true,  // Required to play a sound
    );

    // 3. Combine both platforms
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics, // Include the iOS settings
    );

    // 4. Show the notification
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}