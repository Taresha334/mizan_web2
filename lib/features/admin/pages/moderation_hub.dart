// filepath: lib/features/admin/pages/moderation_hub.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_direct_post.dart';

class ModerationHub extends StatefulWidget {
  const ModerationHub({super.key});

  @override
  State<ModerationHub> createState() => _ModerationHubState();
}

class _ModerationHubState extends State<ModerationHub> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: const Text(
          "MARKETPLACE MODERATION",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('market_listings')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Data Sync Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final listings = snapshot.data ?? [];
          if (listings.isEmpty) {
            return const Center(
              child: Text(
                "No active listings found.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: listings.length,
            itemBuilder: (context, index) =>
                _buildModerationCard(listings[index]),
          );
        },
      ),
    );
  }

  Widget _buildModerationCard(Map<String, dynamic> item) {
    final bool isPartner = item['is_partner_account'] == true;
    final String status = item['status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          item['title'] ?? 'No Title',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Owner: ${isPartner ? "Partner" : "Non-Partner"} | Status: ${status.toUpperCase()}",
            ),
            Text("Phone: ${item['contact_phone'] ?? 'N/A'}"),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleAdminAction(action, item),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text("Edit Listing"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'sold',
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18),
                  SizedBox(width: 8),
                  Text("Toggle Sold"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text("Delete", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAdminAction(
    String action,
    Map<String, dynamic> item,
  ) async {
    final String id = item['id'].toString();

    switch (action) {
      case 'edit':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDirectPost(existingProductId: id),
          ),
        );
        break;

      case 'sold':
        await _supabase
            .from('market_listings')
            .update({
              'is_sold': !(item['is_sold'] ?? false),
              'status': (item['is_sold'] ?? false) ? 'approved' : 'sold',
            })
            .eq('id', id);
        break;

      case 'delete':
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Confirm Deletion"),
            content: Text("Permanently remove '${item['title']}'?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await _supabase.from('market_listings').delete().eq('id', id);
          // Note: If DB has ON DELETE CASCADE, admin_todo_list will clean up automatically.
        }
        break;
    }
  }
}
