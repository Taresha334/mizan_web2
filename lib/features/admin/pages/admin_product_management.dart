// filepath: lib/features/admin/pages/admin_product_management.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProductManagement extends StatefulWidget {
  const AdminProductManagement({super.key});

  @override
  State<AdminProductManagement> createState() => _AdminProductManagementState();
}

enum ProductView { factory, marketplace }

class _AdminProductManagementState extends State<AdminProductManagement> {
  final _supabase = Supabase.instance.client;
  ProductView _currentView = ProductView.factory;

  // Controller for the primary English name and prices
  final _nameEnController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();

  @override
  void dispose() {
    _nameEnController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _currentView == ProductView.factory
              ? "Mizan Feed Inventory"
              : "Market Moderation",
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_currentView == ProductView.factory)
            TextButton.icon(
              onPressed: _showBulkAdjustmentDialog,
              icon: const Icon(
                Icons.trending_up,
                size: 18,
                color: Color(0xFF1B5E20),
              ),
              label: const Text(
                "Price Adjustment",
                style: TextStyle(color: Color(0xFF1B5E20)),
              ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ProductView>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: const Color(0xFF1B5E20),
                selectedForegroundColor: Colors.white,
              ),
              segments: const [
                ButtonSegment(
                  value: ProductView.factory,
                  label: Text("Mizan Feed"),
                  icon: Icon(Icons.factory),
                ),
                ButtonSegment(
                  value: ProductView.marketplace,
                  label: Text("Marketplace"),
                  icon: Icon(Icons.storefront),
                ),
              ],
              selected: {_currentView},
              onSelectionChanged: (val) =>
                  setState(() => _currentView = val.first),
            ),
          ),
        ),
      ),
      body: _buildListStream(),
    );
  }

  Widget _buildListStream() {
    // List of official Mizan categories to filter factory products
    const mizanCategories = [
      'Poultry',
      'Broiler',
      'Saso',
      'Dairy',
      'Fattening',
      'Specialty',
    ];

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('products')
          .stream(primaryKey: ['id'])
          .order('category'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
          );
        }

        final allItems = snapshot.data ?? [];
        final items = allItems.where((item) {
          bool isFactory = mizanCategories.contains(item['category']);
          return _currentView == ProductView.factory ? isFactory : !isFactory;
        }).toList();

        if (items.isEmpty) {
          return const Center(child: Text("No items found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _currentView == ProductView.factory
                      ? const Color(0xFFE8F5E9)
                      : Colors.blue.shade50,
                  child: Icon(
                    _currentView == ProductView.factory
                        ? Icons.agriculture
                        : Icons.shopping_basket,
                    color: _currentView == ProductView.factory
                        ? const Color(0xFF1B5E20)
                        : Colors.blue,
                  ),
                ),
                title: Text(
                  item['name_en'] ?? 'Unnamed Product',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  item['price'] != null
                      ? "${item['price']} ETB"
                      : "Price Not Set",
                  style: TextStyle(
                    color: item['price'] != null ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.blueGrey,
                      ),
                      onPressed: () => _showEditPriceDialog(item),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_forever_outlined,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _confirmPurge(item['id']),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditPriceDialog(Map<String, dynamic> item) {
    _priceController.text = item['price']?.toString() ?? "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${item['name_en']}"),
        content: TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Price (ETB)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
            ),
            onPressed: () async {
              final newPrice = double.tryParse(_priceController.text);
              await _supabase
                  .from('products')
                  .update({'price': newPrice})
                  .eq('id', item['id']);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("SAVE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBulkAdjustmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bulk Price Change (%)"),
        content: TextField(
          controller: _discountController,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(
            hintText: "e.g. 5 for 5% increase, -5 for discount",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
            ),
            onPressed: () {
              final pct = double.tryParse(_discountController.text) ?? 0;
              _applyBulkPriceChange(pct);
              Navigator.pop(context);
            },
            child: const Text(
              "APPLY TO ALL FEED",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyBulkPriceChange(double percentage) async {
    try {
      const mizanCategories = [
        'Poultry',
        'Broiler',
        'Saso',
        'Dairy',
        'Fattening',
        'Specialty',
      ];
      final res = await _supabase
          .from('products')
          .select()
          .inFilter('category', mizanCategories);

      for (var p in (res as List)) {
        if (p['price'] != null) {
          double currentPrice = (p['price'] as num).toDouble();
          double newPrice = currentPrice * (1 + (percentage / 100));
          await _supabase
              .from('products')
              .update({'price': newPrice.roundToDouble()})
              .eq('id', p['id']);
        }
      }
      _discountController.clear();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mizan Feed prices adjusted successfully"),
          ),
        );
    } catch (e) {
      debugPrint("Bulk update error: $e");
    }
  }

  Future<void> _confirmPurge(String id) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Purge Product"),
        content: const Text(
          "This will permanently delete the product from the entire application. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "DELETE PERMANENTLY",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.from('products').delete().eq('id', id);
    }
  }
}
