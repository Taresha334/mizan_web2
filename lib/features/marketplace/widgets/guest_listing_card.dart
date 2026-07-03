// filepath: lib/features/marketplace/widgets/guest_listing_card.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_guest_listing_page.dart';

class GuestListingCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String userPhone;
  final VoidCallback onRefresh;

  const GuestListingCard({
    super.key,
    required this.item,
    required this.userPhone,
    required this.onRefresh,
  });

  Future<void> _handleAction(String action, BuildContext context) async {
    try {
      await Supabase.instance.client.rpc(
        'manage_non_partner_listing',
        params: {
          'listing_id': item['id'],
          'user_phone': userPhone,
          'action_type': action,
        },
      );
      onRefresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Robust check for both the boolean flag and the text status field
    final bool isSold = (item['is_sold'] == true) || (item['status'] == 'sold');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          item['title'] ?? "Untitled",
          style: TextStyle(
            decoration: isSold ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(isSold ? "SOLD" : "${item['unit_price']} ETB"),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditGuestListingPage(item: item, userPhone: userPhone),
                ),
              ).then((_) => onRefresh()),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _handleAction('delete', context),
            ),
            if (!isSold)
              TextButton(
                onPressed: () => _handleAction('sold', context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(60, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("Mark as Sold"),
              ),
          ],
        ),
      ),
    );
  }
}
