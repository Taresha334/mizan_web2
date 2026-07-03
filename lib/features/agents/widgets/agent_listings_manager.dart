// filepath: lib/features/agents/widgets/agent_listings_manager.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'agent_listing_card.dart';

class AgentListingsManager extends StatefulWidget {
  const AgentListingsManager({super.key});

  @override
  State<AgentListingsManager> createState() => _AgentListingsManagerState();
}

class _AgentListingsManagerState extends State<AgentListingsManager> {
  bool _showSold = false;
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Center(child: Text("Please log in."));

    return Column(
      children: [
        SwitchListTile(
          title: const Text(
            "Show Sold Items",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          value: _showSold,
          activeColor: const Color(0xFF1B5E20),
          onChanged: (v) => setState(() => _showSold = v),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase
                .from('market_listings')
                .stream(primaryKey: ['id'])
                .eq('agent_id', userId)
                .order('updated_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                );
              }

              final items = (snapshot.data ?? []).where((item) {
                final isSold = item['is_sold'] == true;
                return _showSold ? isSold : !isSold;
              }).toList();

              if (items.isEmpty) {
                return Center(
                  child: Text(
                    _showSold ? "No sold items found." : "No active listings.",
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                // Fixed: passing 'listing' argument correctly
                itemBuilder: (ctx, i) => AgentListingCard(
                  listing: items[i],
                  onRefresh:
                      () {}, // StreamBuilder handles UI refresh automatically
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
