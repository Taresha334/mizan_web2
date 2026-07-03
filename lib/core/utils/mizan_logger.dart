// MIZAN PLC: CENTRAL LOGGING ENGINE (2026 STANDARDS)
import 'dart:developer' as dev;

class MizanLogger {
  /// Logs hardware and background service events (The Sentinel)
  static void sentinel(String message) {
    dev.log(
      '🛰️ [SENTINEL]: $message',
      name: 'com.mizan.system',
      time: DateTime.now(),
    );
  }

  /// Logs Supabase and Cloud Database interactions
  static void cloud(String message) {
    dev.log(
      '☁️ [SUPABASE]: $message',
      name: 'com.mizan.cloud',
      time: DateTime.now(),
    );
  }

  /// Logs critical failures with stack traces for the Architect
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    dev.log(
      '❌ [ERROR]: $message',
      name: 'com.mizan.error',
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  /// Logs UI state changes and navigation
  static void ui(String message) {
    dev.log('📱 [UI]: $message', name: 'com.mizan.ui', time: DateTime.now());
  }
}
