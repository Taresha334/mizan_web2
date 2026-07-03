// filepath: lib/features/admin/pages/payment_verification_hub.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/string_diff_helper.dart';

class PaymentVerificationHub extends StatefulWidget {
  const PaymentVerificationHub({super.key});

  @override
  State<PaymentVerificationHub> createState() => _PaymentVerificationHubState();
}

class _PaymentVerificationHubState extends State<PaymentVerificationHub> {
  final _supabase = Supabase.instance.client;

  // Persistence: This Set survives Stream updates
  final Set<String> _locallyHiddenIds = {};

  Future<void> _handleApproval({
    required String listingId,
    required String correctRef,
  }) async {
    // 1. UI LOCK: Hide immediately before the network call
    setState(() {
      _locallyHiddenIds.add(listingId);
    });

    try {
      // 2. REMOTE ACTION
      await _supabase.rpc(
        'verify_and_burn_telebirr',
        params: {'p_listing_id': listingId, 'p_correct_ref': correctRef},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Verification Successful"),
            backgroundColor: Color(0xFF1B5E20),
            duration: Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      // 3. REVERT ON FAILURE
      if (mounted) {
        setState(() {
          _locallyHiddenIds.remove(listingId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4),
      appBar: AppBar(
        title: const Text("Mizan Verification Hub"),
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Explicitly defining the stream to ensure it remains stable
        stream: _supabase
            .from('payment_verification_queue')
            .stream(primaryKey: ['listing_id']),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // FILTERING LOGIC: This runs every time the Stream delivers a packet
          final List<Map<String, dynamic>> allData = snapshot.data ?? [];
          final List<Map<String, dynamic>> visibleItems = allData
              .where((item) => !_locallyHiddenIds.contains(item['listing_id']))
              .toList();

          if (visibleItems.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            key: const ValueKey(
              'verification_list',
            ), // Keeps the list state stable
            padding: const EdgeInsets.all(16),
            itemCount: visibleItems.length,
            itemBuilder: (context, index) {
              final item = visibleItems[index];
              return _buildMatchCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> item) {
    final String listingId = item['listing_id'];
    final String farmerInput = item['farmer_input_ref'] ?? "";
    final String smsRef = item['sms_ref'] ?? "";

    return Card(
      key: ValueKey(
        listingId,
      ), // Crucial for Flutter to track which card is which
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['product_name'] ?? "Listing",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildTypoBadge(item['typo_distance'] ?? 0),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _buildRefDisplay("FARMER TYPED", farmerInput, smsRef, true),
                const Icon(Icons.compare_arrows, color: Colors.green, size: 20),
                _buildRefDisplay("REAL TELEBIRR", smsRef, smsRef, false),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  _handleApproval(listingId: listingId, correctRef: smsRef),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "FIX TYPO & APPROVE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefDisplay(
    String label,
    String val,
    String target,
    bool isFarmer,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: isFarmer
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          isFarmer
              ? RichText(
                  text: TextSpan(
                    children: StringDiffHelper.highlightDifferences(
                      val,
                      target,
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                )
              : Text(
                  val,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTypoBadge(int dist) {
    final bool match = dist == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (match ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        match ? "MATCH" : "$dist TYPOS",
        style: TextStyle(
          color: match ? Colors.green : Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            "Verification Queue Clear",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
