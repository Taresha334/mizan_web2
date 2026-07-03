// filepath: lib/features/agents/widgets/agent_listing_card.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_listing_page.dart';

class AgentListingCard extends StatefulWidget {
  final Map<String, dynamic> listing;
  final VoidCallback onRefresh;
  const AgentListingCard({
    super.key,
    required this.listing,
    required this.onRefresh,
  });

  @override
  State<AgentListingCard> createState() => _AgentListingCardState();
}

class _AgentListingCardState extends State<AgentListingCard> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _markAsSold() async {
    setState(() => _isLoading = true);
    try {
      // Bypassing RLS via RPC Security Definer function
      await _supabase.rpc(
        'mark_listing_as_sold',
        params: {'listing_id': widget.listing['id']},
      );
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error marking as sold: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteListing() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirm Purge"),
        content: const Text(
          "This will permanently remove the listing from the app.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        // Bypassing RLS via RPC Security Definer function
        await _supabase.rpc(
          'delete_listing',
          params: {'listing_id': widget.listing['id']},
        );
        widget.onRefresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error deleting listing: $e")));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSold = widget.listing['is_sold'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.listing['title'] ?? 'No Title'),
            subtitle: Text("Price: ${widget.listing['unit_price']} ETB"),
            trailing: isSold
                ? const Chip(label: Text("SOLD"), backgroundColor: Colors.amber)
                : null,
          ),
          ButtonBar(
            children: [
              TextButton(
                onPressed: isSold
                    ? null
                    : () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditListingPage(listingData: widget.listing),
                          ),
                        );
                        if (result == true) widget.onRefresh();
                      },
                child: const Text("Edit"),
              ),
              TextButton(
                onPressed: isSold ? null : _markAsSold,
                child: const Text("Mark as Sold"),
              ),
              IconButton(
                onPressed: _deleteListing,
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
          if (_isLoading) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
