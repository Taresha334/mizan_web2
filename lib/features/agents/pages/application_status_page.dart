// filepath: lib/features/agents/pages/application_status_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApplicationStatusPage extends StatefulWidget {
  const ApplicationStatusPage({super.key});

  @override
  State<ApplicationStatusPage> createState() => _ApplicationStatusPageState();
}

class _ApplicationStatusPageState extends State<ApplicationStatusPage> {
  final _supabase = Supabase.instance.client;
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _applicationData;
  String? _errorMessage;

  final Color mizanGreen = const Color(0xFF1B5E20);

  Future<void> _checkStatus() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isLoading = true;
      _applicationData = null;
      _errorMessage = null;
    });

    try {
      final response = await _supabase
          .from('agent_applications')
          .select()
          .eq('phone', phone)
          .maybeSingle();

      setState(() {
        if (response == null) {
          _errorMessage = "No application found for this phone number.";
        } else {
          _applicationData = response;
        }
      });
    } catch (e) {
      setState(
        () => _errorMessage = "Error fetching status. Please try again.",
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Check Application Status"),
        backgroundColor: mizanGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Enter the phone number used during registration to see your current status.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Phone Number",
                prefixIcon: Icon(Icons.phone, color: mizanGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: mizanGreen),
                onPressed: _isLoading ? null : _checkStatus,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "CHECK STATUS",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            if (_applicationData != null) _buildStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _applicationData!['status'] ?? 'pending';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(statusIcon, color: statusColor, size: 60),
            const SizedBox(height: 10),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const Divider(height: 30),
            _statusRow("Applicant", _applicationData!['full_name']),
            _statusRow(
              "Plan",
              "${_applicationData!['subscription_weeks']} Weeks",
            ),
            _statusRow(
              "Applied On",
              _applicationData!['created_at'].toString().split('T')[0],
            ),
            if (status == 'approved')
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  "Welcome to Mizan PLC! You can now log in to the Agent Portal.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mizanGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
