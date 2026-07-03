// filepath: lib/features/admin/presentation/screens/sentinel_debug_console.dart
// MIZAN PLC: HARDWARE X-RAY (V2026.STABLE)
// ARCHITECT: Mizan PLC Chief Systems Architect

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/sentinel_test_suite.dart';

class SentinelDebugConsole extends StatefulWidget {
  const SentinelDebugConsole({super.key});

  @override
  State<SentinelDebugConsole> createState() => _SentinelDebugConsoleState();
}

class _SentinelDebugConsoleState extends State<SentinelDebugConsole> {
  final _supabase = Supabase.instance.client;
  final List<Map<String, dynamic>> _liveLogs = [];
  StreamSubscription? _logSubscription;

  @override
  void initState() {
    super.initState();
    _connectToCloudStream();
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    super.dispose();
  }

  /// REALTIME BRIDGE: Listens to the database table where the isolate writes.
  void _connectToCloudStream() {
    _logSubscription = _supabase
        .from('telebirr_sentinel')
        .stream(primaryKey: ['transaction_id'])
        .order('received_at', ascending: false)
        .limit(20) // Show last 20 events
        .listen((List<Map<String, dynamic>> data) {
          if (mounted) {
            setState(() {
              _liveLogs.clear();
              _liveLogs.addAll(data);
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          "MIZAN SENTINEL: HARDWARE X-RAY",
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Inject Test Payload",
            icon: const Icon(Icons.bug_report, color: Colors.amber, size: 20),
            onPressed: () {
              // Now only prints to terminal/console for logic testing
              SentinelTestSuite.runTelebirrDetectionTest();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Test Payload Injected to Logic Engine"),
                ),
              );
            },
          ),
          IconButton(
            tooltip: "Database Cleanup",
            icon: const Icon(
              Icons.cleaning_services_rounded,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () {
              // In production, we don't clear the cloud buffer from UI easily
              setState(() => _liveLogs.clear());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusRibbon(),
          Expanded(
            child: _liveLogs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _liveLogs.length,
                    itemBuilder: (context, index) =>
                        _buildLogEntry(_liveLogs[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRibbon() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      color: Colors.blueAccent.withOpacity(0.1),
      child: const Row(
        children: [
          Icon(Icons.dns_rounded, size: 12, color: Colors.blueAccent),
          SizedBox(width: 8),
          Text(
            "ISOLATE PIPE: ACTIVE",
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          Icon(Icons.circle, size: 8, color: Colors.green),
          SizedBox(width: 6),
          Text(
            "CLOUD SYNCED",
            style: TextStyle(color: Colors.green, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> log) {
    // Logic: In the table, we verify processed status
    final bool isProcessed = log['is_processed'] ?? false;
    final DateTime timestamp = DateTime.parse(log['received_at']).toLocal();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isProcessed
              ? Colors.green.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isProcessed ? "PAYMENT_AUTO_VERIFIED" : "TRANSACTION_LOGGED",
                style: TextStyle(
                  color: isProcessed ? Colors.green : Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                DateFormat('HH:mm:ss').format(timestamp),
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const Divider(color: Colors.white10),
          Text(
            log['raw_message'] ?? "No Raw Body Found",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildChip("ID: ${log['transaction_id']}", Colors.blue),
              const SizedBox(width: 8),
              _buildChip("ETB ${log['amount'] ?? '0'}", Colors.amber),
              const Spacer(),
              if (isProcessed)
                const Icon(Icons.verified, color: Colors.green, size: 14),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2, color: Colors.white10),
          SizedBox(height: 20),
          Text(
            "INITIALIZING CLOUD X-RAY...",
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
