import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  final _supabase = Supabase.instance.client;

  // 1. Record the Manual Payment Claim
  Future<void> submitManualPaymentClaim({
    required String listingId,
    required String transactionRef,
    required String method,
    required double amount,
  }) async {
    try {
      final user = _supabase.auth.currentUser;

      await _supabase.from('payments').insert({
        'user_id': user?.id,
        'listing_id': listingId,
        'transaction_ref': transactionRef.trim(),
        'payment_method': method,
        'amount': amount,
        'status': 'pending_verification',
      });
    } catch (e) {
      throw Exception('Failed to log payment claim: $e');
    }
  }

  // 2. Fetch Pending Payments (For Admin Dashboard)
  Future<List<Map<String, dynamic>>> getPendingVerifications() async {
    try {
      final data = await _supabase
          .from('payments')
          .select('*, profiles(full_name), market_listings(title)')
          .eq('status', 'pending_verification')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Error fetching pending payments: $e');
    }
  }

  // 3. ADMIN ONLY: Approve Payment & Release Bonus
  // This triggers the activation and the 50 ETB payment to the Agent
  Future<void> approvePayment({
    required String paymentId,
    required String listingId,
    required String agentId,
  }) async {
    try {
      // Step A: Update Payment Status
      await _supabase
          .from('payments')
          .update({'status': 'verified'}).eq('id', paymentId);

      // Step B: Make the Listing Active
      await _supabase
          .from('market_listings')
          .update({'status': 'active'}).eq('id', listingId);

      // Step C: Release the 50 ETB Bonus to Agent Wallet
      // This uses the Postgres Function we ran in the SQL editor
      await _supabase.rpc('increment_wallet', params: {
        'user_id': agentId,
        'amount': 50.0,
      });

      // Step D: Log the commission history for the Agent to see
      await _supabase.from('commissions').insert({
        'agent_id': agentId,
        'listing_id': listingId,
        'amount': 50.0,
        'type': 'Listing Bonus',
      });
    } catch (e) {
      throw Exception('Approval workflow failed: $e');
    }
  }

  // 4. ADMIN ONLY: Reject Payment
  Future<void> rejectPayment(String paymentId, String reason) async {
    await _supabase.from('payments').update({
      'status': 'rejected',
      'admin_notes': reason,
    }).eq('id', paymentId);
  }
}
