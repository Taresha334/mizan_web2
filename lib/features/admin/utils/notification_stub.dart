// filepath: lib/features/admin/utils/notification_stub.dart

/// A stub class to prevent compilation errors on Web.
/// This mimics the interface of flutter_notification_listener.
class NotificationsListener {
  static Future<bool?> get isRunning async => false;
  static Future<bool?> get hasPermission async => false;

  static Future<void> openPermissionSettings() async {}
  static Future<void> stopService() async {}

  static Future<void> startService({
    String? title,
    String? description,
  }) async {}

  /// Added to satisfy the call in main.dart
  static Future<void> initialize({required Function callbackHandle}) async {
    // No-op on Web
  }
}
