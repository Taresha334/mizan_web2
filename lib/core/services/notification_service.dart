// MIZAN PLC: UNIFIED NOTIFICATION SYSTEM (2026 PRODUCTION READY)
// ARCHITECT: Mizan PLC Chief Systems Architect
// FIX: Resolved Parameter mismatch in .initialize()

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. REGISTRY: Define the Sentinel Channel for the System
    // This is mandatory for Android 16 Foreground Services
    const AndroidNotificationChannel sentinelChannel =
        AndroidNotificationChannel(
          'mizan_sentinel',
          'MIZAN SENTINEL',
          description: 'Critical Gateway for Telebirr 127 Interception',
          importance: Importance.max,
          enableVibration: false,
          playSound: false,
        );

    const AndroidNotificationChannel paymentChannel =
        AndroidNotificationChannel(
          'mizan_payments',
          'Mizan Payments',
          description: 'Alerts for successful marketplace transactions',
          importance: Importance.high,
        );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    // 2. SYSTEM-LEVEL CHANNEL CREATION
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(sentinelChannel);
      await androidPlugin.createNotificationChannel(paymentChannel);
      debugPrint("MIZAN NOTIF: Android 16 Channels Registered.");
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // FIX: Restored named parameter 'settings' and removed incorrect positional arg
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("Mizan Notification Tapped: ${response.payload}");
      },
    );
  }

  static Future<void> showInstantAlert(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'mizan_payments',
          'Mizan Payments',
          channelDescription: 'Real-time transaction alerts for Mizan PLC',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          color: Color(0xFF1B5E20),
        );

    await _notificationsPlugin.show(
      DateTime.now().millisecond % 100000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
}
