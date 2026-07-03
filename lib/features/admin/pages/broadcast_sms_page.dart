// filepath: lib/features/admin/pages/broadcast_sms_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper class to handle native SMS launching for Mizan PLC
class MizanSmsLauncher {
  static Future<void> launchNativeSMS({
    required List<String> recipients,
    required String message,
  }) async {
    // Android uses ';' to separate numbers, iOS uses ','
    String separator = Platform.isAndroid ? ';' : ',';
    String joinedNumbers = recipients.join(separator);

    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: joinedNumbers,
      queryParameters: <String, String>{'body': message},
    );

    if (await canLaunchUrl(smsLaunchUri)) {
      await launchUrl(smsLaunchUri);
    } else {
      throw 'Could not open your SMS application. Please check app permissions.';
    }
  }
}

class BroadcastSmsPage extends StatefulWidget {
  const BroadcastSmsPage({super.key});

  @override
  State<BroadcastSmsPage> createState() => _BroadcastSmsPageState();
}

class _BroadcastSmsPageState extends State<BroadcastSmsPage> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedTarget = 'all';
  bool _isSending = false;
  bool _useCityFilter = false;

  final Map<String, String> _targets = {
    'all': 'All Partners',
    'agent': 'Agricultural Agents',
    'vet': 'Veterinary Doctors',
    'farmer': 'Registered Farmers',
    'worker': 'Labour Workers',
  };

  /// Main logic to fetch numbers and trigger the personal phone SMS app
  Future<void> _sendBroadcast() async {
    final message = _messageController.text.trim();
    final city = _cityController.text.trim();

    if (message.isEmpty) {
      _showSnackBar("Please enter a message.", Colors.orange);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Mizan Broadcast"),
        content: Text(
          "Target: ${_targets[_selectedTarget]}\n"
          "Location: ${_useCityFilter ? (city.isEmpty ? 'All' : city) : 'Nationwide'}\n\n"
          "This will open your phone's SMS app.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "OPEN SMS APP",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSending = true);

    try {
      // 1. Logic: Fetch phone numbers directly from Supabase Profiles
      var query = _supabase
          .from('profiles')
          .select('phone')
          .eq('is_active', true);

      if (_selectedTarget != 'all') {
        query = query.eq('category', _selectedTarget);
      }
      if (_useCityFilter && city.isNotEmpty) {
        query = query.ilike('city_name', '%$city%');
      }

      final List<dynamic> data = await query;
      final List<String> phoneList = data
          .map((e) => e['phone']?.toString() ?? "")
          .where((p) => p.isNotEmpty)
          .toList();

      if (phoneList.isEmpty) {
        _showSnackBar("No partners found for this filter.", Colors.orange);
        return;
      }

      // 2. Logic: Launch the personal phone SMS app with pre-filled numbers and text
      await MizanSmsLauncher.launchNativeSMS(
        recipients: phoneList,
        message: message,
      );

      // 3. Log the attempt in history for Mizan records
      await _supabase.from('broadcast_logs').insert({
        'message': message,
        'target_group': _targets[_selectedTarget],
        'target_city': _useCityFilter
            ? (city.isEmpty ? 'All' : city)
            : 'Nationwide',
      });

      _messageController.clear();
      _showSnackBar(
        "Opening SMS App for ${phoneList.length} partners...",
        Colors.green,
      );
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Mizan Broadcast Center",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1B5E20),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.edit_notifications), text: "COMPOSE"),
              Tab(icon: Icon(Icons.history), text: "HISTORY"),
            ],
          ),
        ),
        body: TabBarView(children: [_buildComposeView(), _buildHistoryView()]),
      ),
    );
  }

  Widget _buildComposeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("1. Target Group"),
          DropdownButtonFormField<String>(
            value: _selectedTarget,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: _targets.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedTarget = val!),
          ),
          const SizedBox(height: 20),
          _buildLabel("2. Location"),
          SwitchListTile(
            title: const Text("City Filter"),
            value: _useCityFilter,
            activeColor: const Color(0xFF1B5E20),
            onChanged: (val) => setState(() => _useCityFilter = val),
          ),
          if (_useCityFilter)
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                hintText: "City Name",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          const SizedBox(height: 20),
          _buildLabel("3. Message"),
          TextField(
            controller: _messageController,
            maxLines: 4,
            maxLength: 160,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
              ),
              onPressed: _isSending ? null : _sendBroadcast,
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "SEND BROADCAST",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('broadcast_logs')
          .stream(primaryKey: ['id'])
          .order('sent_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final logs = snapshot.data!;
        if (logs.isEmpty)
          return const Center(child: Text("No broadcast history found."));

        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final DateTime date = DateTime.parse(log['sent_at']);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(
                  log['message'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  "${log['target_group']} (${log['target_city']})\n${DateFormat('MMM dd, yyyy - hh:mm a').format(date)}",
                ),
                isThreeLine: true,
                leading: const Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  void _showSnackBar(String msg, Color col) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: col));
}
