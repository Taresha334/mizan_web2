// filepath: lib/features/admin/pages/admin_orders_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _supabase = Supabase.instance.client;
  String _selectedFilter = 'all';

  // Mizan Brand Colors
  final Color mizanGreen = const Color(0xFF1B5E20);

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
      if (mounted) {
        _showSnackBar(
          "Order marked as ${newStatus.toUpperCase()}",
          isError: false,
        );
      }
    } catch (e) {
      _showSnackBar("Update failed: $e", isError: true);
    }
  }

  Future<void> _callUser(String? phone) async {
    if (phone == null || phone.isEmpty) {
      _showSnackBar("No phone number provided", isError: true);
      return;
    }
    // Clean the number for dialer compatibility
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri url = Uri.parse("tel:$cleanPhone");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showSnackBar("Could not launch phone dialer", isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[800] : mizanGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Order Fulfillment",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('orders')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                  );
                }

                var orders = snapshot.data!;
                if (_selectedFilter != 'all') {
                  orders = orders
                      .where((o) => o['status'] == _selectedFilter)
                      .toList();
                }

                if (orders.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) =>
                      _buildOrderCard(orders[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = ['all', 'pending', 'processing', 'shipped', 'completed'];
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, i) {
          final status = filters[i];
          final isSelected = _selectedFilter == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                status.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedFilter = status),
              selectedColor: mizanGreen,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final date = DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildStatusIcon(status),
        title: Text(
          order['customer_name'] ?? "Unknown Farmer",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${order['total_price'] ?? 0} ETB • ${DateFormat('MMM dd, HH:mm').format(date)}",
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
            ),
            child: Column(
              children: [
                _detailRow(
                  Icons.location_on_outlined,
                  "Delivery",
                  order['delivery_location'] ?? "Not provided",
                ),
                _detailRow(
                  Icons.inventory_2_outlined,
                  "Package",
                  "${order['quantity'] ?? 0} units of feed",
                ),
                _detailRow(
                  Icons.phone_outlined,
                  "Contact",
                  order['phone_number'] ?? "No number",
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _callUser(order['phone_number']),
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text("CALL CUSTOMER"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          side: BorderSide(color: Colors.blue.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatusMenu(order)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMenu(Map<String, dynamic> order) {
    return PopupMenuButton<String>(
      onSelected: (val) => _updateOrderStatus(order['id'], val),
      itemBuilder: (context) => [
        _menuItem('pending', 'Pending', Icons.history),
        _menuItem('processing', 'Processing', Icons.sync),
        _menuItem('shipped', 'Shipped', Icons.local_shipping),
        _menuItem('completed', 'Completed', Icons.check_circle),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: mizanGreen,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            "UPDATE STATUS",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String val, String label, IconData icon) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'shipped':
        icon = Icons.local_shipping;
        color = Colors.orange;
        break;
      case 'processing':
        icon = Icons.sync;
        color = Colors.blue;
        break;
      default:
        icon = Icons.pending_actions;
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            "No orders marked as '$_selectedFilter'",
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
