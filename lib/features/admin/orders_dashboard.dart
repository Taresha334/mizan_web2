import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OrdersDashboard extends StatefulWidget {
  const OrdersDashboard({super.key});

  @override
  State<OrdersDashboard> createState() => _OrdersDashboardState();
}

class _OrdersDashboardState extends State<OrdersDashboard> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      // Fetch orders and join with products table to get the name
      final data = await supabase
          .from('orders')
          .select('*, products(name_en)')
          .order('created_at', ascending: false);
      setState(() {
        _orders = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _handleApproval(Map<String, dynamic> order) async {
    final String phone = order['phone_number'];
    final String productName = order['products']['name_en'] ?? "Feed Product";

    try {
      // 1. Update Database
      await supabase
          .from('orders')
          .update({'status': 'paid'}).eq('id', order['id']);

      // 2. Prepare SMS
      final String msg =
          "Mizan PLC: Payment confirmed for $productName. Your order is being processed. Contact us at +251XXXXXXXXX for delivery.";
      final Uri uri = Uri.parse("sms:$phone?body=${Uri.encodeComponent(msg)}");

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }

      _fetchOrders(); // Refresh list
    } catch (e) {
      debugPrint("Approval Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mizan Orders Manager"),
        backgroundColor: const Color(0xFF1B5E20),
        actions: [
          IconButton(onPressed: _fetchOrders, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                bool isPaid = order['status'] == 'paid';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    isThreeLine: true,
                    title: Text(order['customer_name'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Product: ${order['products']['name_en']}"),
                        Text("Phone: ${order['phone_number']}"),
                        Text(
                            "Status: ${order['status'].toString().toUpperCase()}",
                            style: TextStyle(
                                color: isPaid ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: isPaid
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[800]),
                            onPressed: () => _handleApproval(order),
                            child: const Text("Approve & SMS",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
