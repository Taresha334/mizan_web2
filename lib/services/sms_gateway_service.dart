// filepath: lib/services/sms_gateway_service.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:telephony/telephony.dart';

class MizanSmsGateway {
  // Hard-coded Supabase client for isolation and production reliability
  final SupabaseClient _client = SupabaseClient(
    'https://xztidxvdikyintwiaths.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6dGlkeHZkaWt5aW50d2lhdGhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMjYyODUsImV4cCI6MjA4NTcwMjI4NX0.ntd5TpKEYfzubCl3ljDqhM_6Ro-ZjsdbIvVexKNLFm8',
  );

  final Telephony _telephony = Telephony.instance;
  Timer? _timer;
  bool isRunning = false;

  /// Starts the polling engine. Note: We use requestSmsPermissions
  /// (property access) as required by the telephony package.
  Future<void> startService(Function(String) onLog) async {
    if (isRunning) return;

    onLog("Mizan Sentinel: Checking permissions...");

    // Request permissions correctly for the telephony plugin
    bool? permissionsGranted = await _telephony.requestSmsPermissions;

    if (permissionsGranted != true) {
      onLog("CRITICAL ERROR: SMS Permissions denied. Cannot send messages.");
      return;
    }

    isRunning = true;
    onLog("Mizan Sentinel: Engine Started. Monitoring Outbox...");

    // Persistent polling loop
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _processNextSms(onLog);
    });
  }

  // Stop the engine safely
  void stopService(Function(String) onLog) {
    _timer?.cancel();
    isRunning = false;
    onLog("Mizan Sentinel: Engine Stopped.");
  }

  Future<void> _processNextSms(Function(String) onLog) async {
    try {
      // 1. Fetch one pending message
      final data = await _client
          .from('sms_outbox')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();

      if (data != null) {
        final String phone = data['phone'];
        final String message = data['message'];
        final dynamic id = data['id'];

        onLog("Found Pending SMS for: $phone. Sending...");

        // 2. Fire the hardware SIM card
        await _telephony.sendSms(
          to: phone,
          message: message,
          isMultipart: true,
          statusListener: (SendStatus status) async {
            if (status == SendStatus.SENT) {
              // 3. Update DB to 'sent'
              await _client
                  .from('sms_outbox')
                  .update({
                    'status': 'sent',
                    'processed_at': DateTime.now().toIso8601String(),
                  })
                  .eq('id', id);

              onLog("Success: Message delivered to $phone.");
            } else {
              onLog(
                "Failed: SIM Card could not send to $phone. Status: $status",
              );
            }
          },
        );
      }
    } catch (e) {
      onLog("System Error during processing: ${e.toString()}");
    }
  }
}
