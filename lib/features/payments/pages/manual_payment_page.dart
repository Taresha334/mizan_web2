import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManualPaymentPage extends StatefulWidget {
  final String listingId;
  const ManualPaymentPage({super.key, required this.listingId});

  @override
  State<ManualPaymentPage> createState() => _ManualPaymentPageState();
}

class _ManualPaymentPageState extends State<ManualPaymentPage> {
  final _txController = TextEditingController();
  String _selectedMethod = 'TeleBirr';
  bool _isSubmitting = false;

  final Map<String, String> _bankDetails = {
    'TeleBirr': 'Mizan PLC - 0911XXXXXX',
    'CBE': 'Mizan Agricultural Solutions - 1000XXXXXXXX',
    'M-Pesa': 'Mizan PLC - 07XXXXXXXX',
  };

  Future<void> _submitClaim() async {
    if (_txController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enter the Transaction Reference ID")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;

      await Supabase.instance.client.from('payments').insert({
        'user_id': user?.id,
        'listing_id': widget.listingId,
        'amount': 500,
        'payment_method': _selectedMethod,
        'transaction_ref': _txController.text.trim(),
        'status': 'pending_verification',
      });

      if (mounted) {
        _showFinalDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting claim: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showFinalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Payment Submitted"),
        content: const Text(
          "Our admin will verify your transaction within 1-2 hours. Once verified, your listing will go live and you will receive your bonus.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to marketplace
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submit Payment Detail")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How to Pay:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("1. Transfer 500 ETB to one of the accounts below."),
            const Text("2. Copy the Transaction ID from the SMS you receive."),
            const Text("3. Paste the ID below and submit."),
            const SizedBox(height: 30),
            const Text("Choose Payment Method:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _bankDetails.keys.map((method) {
                return DropdownMenuItem(value: method, child: Text(method));
              }).toList(),
              onChanged: (val) => setState(() => _selectedMethod = val!),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  const Text("SEND TO:",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(
                    _bankDetails[_selectedMethod]!,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Transaction Reference ID:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _txController,
              decoration: const InputDecoration(
                hintText: "Enter the ID from your SMS (e.g. 9GH5...) ",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitClaim,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit for Verification"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
