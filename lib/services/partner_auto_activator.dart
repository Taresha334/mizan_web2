import 'dart:math';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// MIZAN SYSTEMS ARCHITECT: Partner Auto-Activation Engine
/// CORRECTED: Removed all 'trans_id' references.
/// MAPPED: transactionId -> payment_ref (agent_applications)
/// MAPPED: transactionId -> last_payment_ref (profiles)
class PartnerAutoActivator {
  final _supabase = Supabase.instance.client;

  // Synchronized with MainActivity.kt: com.mizan.sentinel/sms
  static const _smsChannel = MethodChannel('com.mizan.sentinel/sms');

  /// Main entry point triggered by the Telebirr 127 SMS Parser
  Future<void> processRegistration({
    required String incomingPhone,
    required double paidAmount,
    required String transactionId,
  }) async {
    try {
      print("MIZAN SENTINEL: Starting activation for $incomingPhone...");

      // 1. Normalize Phone (Targeting core 9 digits)
      final normalizedPhone = _normalizePhone(incomingPhone);
      final last4 = normalizedPhone.substring(normalizedPhone.length - 4);

      // 2. Cross-Reference Live Pricing Table
      final pricingTier = await _getMatchingTier(paidAmount);
      if (pricingTier == null) {
        print("MIZAN ERROR: $paidAmount ETB matches no registration tier.");
        return;
      }

      // 3. Match against Pending Applications using normalized phone
      final application = await _supabase
          .from('agent_applications')
          .select()
          .ilike('phone', '%$normalizedPhone%')
          .eq('status', 'pending')
          .maybeSingle();

      if (application == null) {
        print("MIZAN ERROR: No pending application for $normalizedPhone");
        return;
      }

      // 4. Credential Generation (Permanent)
      final String username = "mizan_$last4";
      final String password = _generateSecurePassword();
      final String virtualEmail = "$username@mizan.plc";

      // 5. Atomic Auth Creation in Supabase auth.users
      final AuthResponse res = await _supabase.auth.signUp(
        email: virtualEmail,
        password: password,
        data: {
          'full_name': application['full_name'],
          'phone': normalizedPhone,
          'role': 'agent',
          'category': 'agent',
        },
      );

      if (res.user != null) {
        // Use pricing tier duration, fallback to application duration, fallback to 4 weeks
        final int weeks =
            pricingTier['duration_weeks'] ??
            application['subscription_weeks'] ??
            4;
        final expiryDate = DateTime.now().add(Duration(days: weeks * 7));

        // 6. Update Mizan Profiles (public.profiles)
        // FIXED: Using last_payment_ref as established in our ALTER commands
        await _supabase
            .from('profiles')
            .update({
              'username': username,
              'is_active': true,
              'is_verified': true,
              'subscription_expires_at': expiryDate.toIso8601String(),
              'last_payment_ref': transactionId,
            })
            .eq('id', res.user!.id);

        // 7. Update Agent Applications (public.agent_applications)
        // FIXED: Using payment_ref to match your SQL schema provided
        await _supabase
            .from('agent_applications')
            .update({
              'status': 'auto_verified',
              'payment_ref': transactionId,
              'verified_amount': paidAmount,
              'agent_id': res.user!.id, // Link to the new profile
            })
            .eq('id', application['id']);

        // 8. Trigger Hardware SMS via Native Bridge
        await _sendCredentialSms(
          targetPhone: incomingPhone,
          username: username,
          password: password,
          expiry: expiryDate,
        );

        print(
          "MIZAN SUCCESS: Partner $username Activated and credentials dispatched.",
        );
      }
    } catch (e) {
      print("MIZAN CRITICAL EXCEPTION: $e");
    }
  }

  /// Communicates with MainActivity.kt to send physical SMS
  Future<void> _sendCredentialSms({
    required String targetPhone,
    required String username,
    required String password,
    required DateTime expiry,
  }) async {
    final String dateStr = DateFormat('yyyy-MM-dd').format(expiry);
    final String message =
        "Welcome Partner! Mizan Account ACTIVE.\n"
        "User: $username\n"
        "Pass: $password\n"
        "Valid until: $dateStr\n"
        "Login at the Mizan Agent Portal.";

    try {
      final String result = await _smsChannel.invokeMethod('sendSms', {
        'phone': targetPhone,
        'message': message,
      });
      print("MIZAN SMS HARDWARE DISPATCH: $result");
    } on PlatformException catch (e) {
      print("MIZAN SMS HARDWARE FAILURE: ${e.message}");
    }
  }

  /// Fetches price matching from the unified database
  Future<Map<String, dynamic>?> _getMatchingTier(double amount) async {
    final List<Map<String, dynamic>> tiers = await _supabase
        .from('registration_pricing')
        .select()
        .eq('price_etb', amount);
    return tiers.isNotEmpty ? tiers.first : null;
  }

  /// Normalizes Ethiopian formats (+251, 09, 9) to core digits
  String _normalizePhone(String phone) {
    String p = phone.replaceAll(RegExp(r'\D'), '');
    if (p.startsWith('251')) p = p.substring(3);
    if (p.startsWith('0')) p = p.substring(1);
    return p;
  }

  /// Generates a readable, permanent 8-character password
  String _generateSecurePassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789';
    return List.generate(
      8,
      (index) => chars[Random().nextInt(chars.length)],
    ).join();
  }
}
