import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io'; // ✅ Required for Platform check

import '../utils/deeplink/howwowDeeplinkRouter.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> requestAndroidNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  // Initialize notification service
  Future<void> initNotifications() async {
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   print("User tapped the notification: ${message.notification?.title}");
    // });
    if (Platform.isAndroid) {
      await requestAndroidNotificationPermission();
    }
    // Request permission
    await requestIOSPermissions();

    // Initialize local notifications for both Android and iOS
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/logo');

    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tapped logic here
        // You could navigate to a specific screen based on payload
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // Channel ID
      'GlutaClass Notifications', // Channel name
      description:
          'This channel is used for important notifications.', // Channel description
      importance: Importance.high,
    );

    // Create notification channel on Android
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Listen to messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background and terminated messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Cold-launch case: if the user tapped a notification while the app
    // was killed, FCM exposes that initial RemoteMessage here. Route it
    // immediately so the in-app deeplink fires on first frame.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _routeNotificationDeeplink(initial, source: 'push_cold_start');
    }
  }

  // Handle foreground message by showing a local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      _showLocalNotification(notification);
    }
  }

  // Handle background and terminated messages — the user tapped the
  // notification while the app was already in the OS task switcher
  // (background or recently-used), bringing it to the foreground.
  void _handleBackgroundMessage(RemoteMessage message) {
    _routeNotificationDeeplink(message, source: 'push');
  }

  /// Extract `data.url` from the FCM payload and hand it to
  /// {@link HowwowDeeplinkRouter}. Notifications without a `url` field
  /// are silently ignored — they're informational pushes (no destination).
  void _routeNotificationDeeplink(RemoteMessage message,
      {required String source}) {
    final data = message.data;
    final raw = data['url'];
    if (raw is! String || raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) {
      // ignore: avoid_print
      print('notification deeplink: malformed url=$raw');
      return;
    }
    // ignore: discarded_futures
    HowwowDeeplinkRouter.handle(uri, defaultSource: source);
  }

  // Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteNotification notification) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'high_importance_channel', // Unique channel ID
      'GlutaClass Notifications', // User-visible name
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true, // Display alert for foreground notifications
      presentBadge: true, // Display badge for foreground notifications
      presentSound: true, // Play sound for foreground notifications
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
    );
  }

  // Get FCM token for the device
  Future<String?> getDeviceToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print("FCM Device Token: $token");
      return token;
    } catch (e) {
      print("Error getting FCM device token: $e");
      return null;
    }
  }

  // Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Request iOS-specific permissions
  Future<void> requestIOSPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Check the current notification settings
    NotificationSettings currentSettings =
        await messaging.getNotificationSettings();

    if (currentSettings.authorizationStatus ==
        AuthorizationStatus.notDetermined) {
      // Only request permission if not already granted or declined
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print("User granted permission for notifications");
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print("User granted provisional permission");
      } else {
        print("User declined or has not accepted permission");
      }
    } else {
      print(
          "Notifications permission already set to: ${currentSettings.authorizationStatus}");
    }
  }
}
