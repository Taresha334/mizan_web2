// filepath: lib/features/admin/pages/unified_price_manager.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnifiedPriceManager extends StatefulWidget {
  const UnifiedPriceManager({super.key});

  @override
  State<UnifiedPriceManager> createState() => _UnifiedPriceManagerState();
}

class _UnifiedPriceManagerState extends State<UnifiedPriceManager> {
  final _supabase = Supabase.instance.client;

  final Color mizanGreen = const Color(0xFF1B5E20);
  final Color mizanGold = const Color(0xFFC6A664);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F3F4),
        appBar: AppBar(
          title: const Text(
            "MIZAN REVENUE ENGINE",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          backgroundColor: mizanGreen,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: "REGISTRATION"),
              Tab(text: "VISIBILITY"),
              Tab(text: "FACTORY FEED"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Registration Pricing
            _buildPriceStream(
              tableName: 'registration_pricing',
              info: "Partner Onboarding: 1 Month, 6 Months, or 1 Year tiers.",
              itemBuilder: (item) => _buildPriceCard(
                title: item['tier_name'] ?? "Standard Membership",
                subtitle: "Duration: ${item['duration_weeks']} Weeks",
                price: (item['price_etb'] as num?)?.toDouble() ?? 0.0,
                onEdit: () =>
                    _showEditDialog(item, 'registration_pricing', 'price_etb'),
              ),
            ),
            // Visibility Pricing
            _buildPriceStream(
              tableName: 'visibility_pricing',
              info: "Marketplace Tiers: Partner vs. Non-Partner rates.",
              itemBuilder: (item) => _buildPriceCard(
                title:
                    "${item['user_role'] == 'partner' ? 'Partner' : 'Non-Partner'} Rate",
                subtitle:
                    "${item['duration_category']} (${item['weeks']} Weeks)",
                price: (item['price_etb'] as num?)?.toDouble() ?? 0.0,
                onEdit: () =>
                    _showEditDialog(item, 'visibility_pricing', 'price_etb'),
              ),
            ),
            // Mizan Factory Feed (Refactored to price_etb)
            _buildPriceStream(
              tableName: 'products',
              filterField: 'is_mizan_factory',
              filterValue: true,
              info:
                  "Mizan Factory Feed: LIVE price control for all catalog items.",
              itemBuilder: (item) => _buildPriceCard(
                title: item['name_en'] ?? "Unknown Product",
                subtitle:
                    "Category: ${item['category']} | Sub-type: ${item['sub_type'] ?? 'N/A'}",
                price: (item['price_etb'] as num?)?.toDouble() ?? 0.0,
                onEdit: () => _showEditDialog(item, 'products', 'price_etb'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE STREAM ARCHITECTURE ---
  Widget _buildPriceStream({
    required String tableName,
    required String info,
    required Widget Function(Map<String, dynamic>) itemBuilder,
    String? filterField,
    dynamic filterValue,
  }) {
    final query = filterField != null
        ? _supabase
              .from(tableName)
              .stream(primaryKey: ['id'])
              .eq(filterField, filterValue)
        : _supabase.from(tableName).stream(primaryKey: ['id']);

    return Column(
      children: [
        _buildInfoBanner(info),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: query,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: mizanGreen),
                );
              }
              final data = List<Map<String, dynamic>>.from(snapshot.data ?? []);
              if (data.isEmpty)
                return const Center(child: Text("No items found."));

              // Sorting
              if (tableName == 'products') {
                data.sort(
                  (a, b) => (a['name_en'] ?? '').toString().compareTo(
                    (b['name_en'] ?? '').toString(),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: data.length,
                itemBuilder: (context, index) => itemBuilder(data[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(color: mizanGold.withOpacity(0.1)),
    child: Text(
      text,
      style: TextStyle(
        color: mizanGreen,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildPriceCard({
    required String title,
    required String subtitle,
    required double price,
    required VoidCallback onEdit,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${price.toStringAsFixed(2)} ETB",
              style: TextStyle(
                color: mizanGreen,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_note, color: mizanGold),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    Map<String, dynamic> item,
    String tableName,
    String fieldName,
  ) {
    final controller = TextEditingController(
      text: item[fieldName]?.toString() ?? '0',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "Adjust Price",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "New Rate (ETB)",
            border: OutlineInputBorder(),
            prefixText: "ETB ",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: mizanGreen),
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null) {
                await _supabase
                    .from(tableName)
                    .update({
                      fieldName: val,
                      'last_price_update': DateTime.now()
                          .toUtc()
                          .toIso8601String(),
                    })
                    .eq('id', item['id']);
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }
}
