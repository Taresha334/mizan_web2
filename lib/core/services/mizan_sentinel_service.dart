// filepath: lib/core/services/mizan_sentinel_service.dart

import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:supabase/supabase.dart';
import 'package:telephony/telephony.dart';

class MizanSmsObserver {
  static const String url = 'https://xztidxvdikyintwiaths.supabase.co';
  static const String key =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6dGlkeHZkaWt5aW50d2lhdGhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMjYyODUsImV4cCI6MjA4NTcwMjI4NX0.ntd5TpKEYfzubCl3ljDqhM_6Ro-ZjsdbIvVexKNLFm8';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'mizan_sentinel_v1',
        initialNotificationTitle: 'MIZAN GATEWAY ACTIVE',
        initialNotificationContent: 'Relay Mode: Secure',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
    await service.startService();
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Pure Dart Client: Isolated from UI memory
  final supabase = SupabaseClient(MizanSmsObserver.url, MizanSmsObserver.key);
  final Telephony telephony = Telephony.instance;

  telephony.listenIncomingSms(
    onNewMessage: (SmsMessage message) async {
      try {
        final String raw = message.body ?? "";
        // Only trigger network if it looks like a Telebirr message
        if (raw.contains("telebirr") || raw.contains("received")) {
          await supabase.from('telebirr_sentinel').insert({
            'raw_message': raw,
            'sender_phone': message.address ?? "Unknown",
            'received_at': DateTime.now().toUtc().toIso8601String(),
          });
        }
      } catch (_) {
        // Absolute silence on error prevents OS 'App Bug' popup
      }
    },
    listenInBackground: false,
  );
}
