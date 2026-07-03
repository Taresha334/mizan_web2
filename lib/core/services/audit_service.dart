// filepath: lib/core/services/audit_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuditService {
  static final _supabase = Supabase.instance.client;

  /// Logs a financial action to the audit trail
  static Future<void> logAction({
    required String actionType, // e.g., 'PAYMENT_VERIFIED', 'PAYOUT_REJECTED'
    required double amount,
    required String reference,
    String? status,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      await _supabase.from('payment_audit_logs').insert({
        'user_id': userId,
        'action_type': actionType,
        'amount': amount,
        'reference_number': reference,
        'status': status ?? 'success',
        'metadata': extraData ?? {},
      });

      debugPrint("✅ Audit log saved: $actionType for $reference");
    } catch (e) {
      // We don't want an audit failure to crash the main app, but we must log it
      debugPrint("❌ Failed to save audit log: $e");
    }
  }
}
