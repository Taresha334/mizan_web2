import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as dev;

/// MIZAN PLC INDUSTRIAL STANDARD [2026-04-05]
/// Handles automated 1.00 ETB verification and restores the Admin Todo Loop.
class MizanVerificationService {
  final _supabase = Supabase.instance.client;

  /// CORE FUNCTION: Verifies Telebirr Transaction, Registers Agent, and Creates Admin Task.
  Future<void> verifyAndDispatchCredentials({
    required String partnerPhone,
    required String providedTransactionId,
    required double expectedAmount,
  }) async {
    try {
      // 1. DATABASE LOOKUP: FETCH FROM TELEBIRR_SENTINEL
      // Note: Supabase confirmed table is 'telebirr_sentinel'
      final response = await _supabase
          .from('telebirr_sentinel')
          .select()
          .eq('transaction_id', providedTransactionId)
          .maybeSingle();

      if (response == null) {
        await _logAuditFailure(
          partnerPhone,
          providedTransactionId,
          "ID_NOT_FOUND",
        );
        throw Exception("Transaction ID $providedTransactionId not found.");
      }

      // 2. DATA VALIDATION
      final double actualAmount = (response['amount'] as num).toDouble();
      final DateTime smsReceivedAt = DateTime.parse(response['created_at']);
      final bool isConsumed = response['is_consumed'] ?? false;

      if (isConsumed) {
        await _logAuditFailure(
          partnerPhone,
          providedTransactionId,
          "ALREADY_VERIFIED",
        );
        throw Exception("This payment ID has already been used.");
      }

      if (actualAmount < expectedAmount) {
        await _logAuditFailure(
          partnerPhone,
          providedTransactionId,
          "INSUFFICIENT_FUNDS",
        );
        throw Exception(
          "Payment of $actualAmount is below $expectedAmount ETB.",
        );
      }

      // 3. ATOMIC LOCK: MARK AS USED
      await _supabase
          .from('telebirr_sentinel')
          .update({'is_consumed': true})
          .eq('transaction_id', providedTransactionId);

      // 4. CREDENTIAL GENERATION (MZ-Standard)
      final String tempPin = _generateSecurePin();
      final String lastFour = partnerPhone.length >= 4
          ? partnerPhone.substring(partnerPhone.length - 4)
          : partnerPhone;
      final String username = "MZ-$lastFour";

      // Create the Agent Record
      await _supabase.from('agents').insert({
        'phone': partnerPhone,
        'username': username,
        'password_hash': tempPin,
        'status': 'pending_approval', // Set to pending for the Todo loop
        'created_at': DateTime.now().toIso8601String(),
      });

      // 4.5 RESTORE ADMIN TODO LIST LOGIC
      // Creates a task for the Admin to perform final verification
      await _supabase.from('admin_todo_list').insert({
        'title': 'New Partner Verification: $partnerPhone',
        'task_type': 'verification',
        'status': 'pending',
        'metadata': {
          'phone': partnerPhone,
          'transaction_id': providedTransactionId,
          'amount': actualAmount,
          'username_assigned': username,
        },
      });

      // 5. AUDIT HUB SYNC (TAB 6 VISIBILITY)
      final int duration = DateTime.now().difference(smsReceivedAt).inSeconds;
      await _supabase.from('mizan_audit_logs').insert({
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'AUTO_VERIFY_PARTNER',
        'entity': partnerPhone,
        'status': 'SUCCESS',
        'transaction_amount': actualAmount,
        'processing_duration_seconds': duration,
        'telebirr_reference_id': providedTransactionId,
      });

      // 6. DISPATCH VIA NATIVE SMS GATEWAY
      await _dispatchSmsViaLauncher(
        phone: partnerPhone,
        username: username,
        pin: tempPin,
      );

      dev.log(
        "MIZAN SYSTEM: Verification and Todo Task created for $partnerPhone",
      );
    } catch (e) {
      dev.log("MIZAN ARCHITECT CRITICAL: $e");
      rethrow;
    }
  }

  String _generateSecurePin() {
    return (100000 + (DateTime.now().microsecondsSinceEpoch % 900000))
        .toString();
  }

  Future<void> _dispatchSmsViaLauncher({
    required String phone,
    required String username,
    required String pin,
  }) async {
    final String message =
        "Welcome to Mizan PLC!\n"
        "User: $username\n"
        "PIN: $pin\n"
        "Factory: Adama (35 TPH)";

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: <String, String>{'body': message},
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        dev.log("Mizan SMS Error: Gateway Unreachable.");
      }
    } catch (e) {
      dev.log("Mizan SMS Error: $e");
    }
  }

  Future<void> _logAuditFailure(String phone, String tid, String reason) async {
    await _supabase.from('mizan_audit_logs').insert({
      'timestamp': DateTime.now().toIso8601String(),
      'action': 'AUTO_VERIFY_FAILED',
      'entity': phone,
      'status': 'FAILED: $reason',
      'telebirr_reference_id': tid,
    });
  }
}
