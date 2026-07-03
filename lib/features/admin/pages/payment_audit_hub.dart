// filepath: lib/features/admin/pages/payment_audit_hub.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PaymentAuditHub extends StatelessWidget {
  const PaymentAuditHub({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text("SENTINEL AUDIT"),
        backgroundColor: const Color(0xFF1B5E20),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('telebirr_sentinel')
            .stream(primaryKey: ['id'])
            .order('created_at'),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final logs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              return Card(
                child: ListTile(
                  title: Text(log['transaction_id'] ?? "N/A"),
                  subtitle: Text(
                    "${log['amount']} ETB - ${log['sender_phone']}",
                  ),
                  trailing: Icon(
                    log['is_processed'] ? Icons.check_circle : Icons.pending,
                    color: log['is_processed'] ? Colors.green : Colors.orange,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
