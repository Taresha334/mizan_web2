import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/responsive_layout.dart'; // Standardized Mizan Breakpoints

class PayoutManagement extends StatefulWidget {
  const PayoutManagement({super.key});

  @override
  State<PayoutManagement> createState() => _PayoutManagementState();
}

class _PayoutManagementState extends State<PayoutManagement> {
  final _supabase = Supabase.instance.client;
  final Color mizanGreen = const Color(0xFF1B5E20);
  final Color mizanGold = const Color(0xFFC6A664);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: const Text(
          "Payout & Commission Hub",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: mizanGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              /* Export Logic */
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 900;

          return Column(
            children: [
              _buildSummaryCards(isCompact),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase
                      .from('payout_logs')
                      .stream(primaryKey: ['id'])
                      .order('created_at'),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final logs = snapshot.data!;

                    return isCompact
                        ? _buildMobileList(logs)
                        : _buildWebTable(logs);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- RESPONSIVE HEADER ---
  Widget _buildSummaryCards(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Flex(
        direction: isCompact ? Axis.vertical : Axis.horizontal,
        children: [
          _buildStatTile(
            "Pending Payouts",
            "14,200 ETB",
            Icons.pending_actions,
            Colors.orange,
          ),
          const SizedBox(width: 12, height: 12),
          _buildStatTile(
            "Completed Today",
            "8,500 ETB",
            Icons.check_circle,
            mizanGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String val, IconData icon, Color col) {
    return Expanded(
      flex: 1,
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: col),
          title: Text(label, style: const TextStyle(fontSize: 12)),
          trailing: Text(
            val,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }

  // --- WEB VIEW: DATA TABLE ---
  Widget _buildWebTable(List<Map<String, dynamic>> logs) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Agent Name")),
            DataColumn(label: Text("Telebirr Phone")),
            DataColumn(label: Text("Amount")),
            DataColumn(label: Text("Status")),
            DataColumn(label: Text("Actions")),
          ],
          rows: logs
              .map(
                (log) => DataRow(
                  cells: [
                    DataCell(Text(log['agent_name'] ?? "Unknown")),
                    DataCell(Text(log['phone'] ?? "N/A")),
                    DataCell(Text("${log['amount']} ETB")),
                    DataCell(_buildStatusChip(log['status'])),
                    DataCell(
                      ElevatedButton(
                        onPressed: () => _processPayout(log),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mizanGreen,
                        ),
                        child: const Text(
                          "PAY NOW",
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // --- MOBILE VIEW: CARD LIST ---
  Widget _buildMobileList(List<Map<String, dynamic>> logs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(log['agent_name'] ?? "Agent"),
            subtitle: Text("${log['amount']} ETB"),
            trailing: _buildStatusChip(log['status']),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Phone:"),
                        Text(log['phone'] ?? "N/A"),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                        backgroundColor: mizanGreen,
                      ),
                      onPressed: () => _processPayout(log),
                      child: const Text(
                        "PROCESS TELEBIRR TRANSFER",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String? status) {
    final bool isPaid = status == 'completed';
    return Chip(
      label: Text(
        isPaid ? "PAID" : "PENDING",
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      backgroundColor: isPaid ? mizanGreen : Colors.orange,
    );
  }

  Future<void> _processPayout(Map<String, dynamic> log) async {
    // Logic: Trigger Mizan API to perform Telebirr B2C transfer
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Payout initiated...")));
  }
}
