// filepath: lib/features/agents/pages/agent_listings_view.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/agent_listing_card.dart';

class AgentListingsView extends StatefulWidget {
  const AgentListingsView({super.key});

  @override
  State<AgentListingsView> createState() => _AgentListingsViewState();
}

class _AgentListingsViewState extends State<AgentListingsView> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _listings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchListings();
  }

  Future<void> _fetchListings() async {
    setState(() => _loading = true);
    final data = await _supabase
        .from('market_listings')
        .select('*')
        .eq('agent_id', _supabase.auth.currentUser!.id);
    if (mounted)
      setState(() {
        _listings = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MY LISTINGS")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _listings.length,
              itemBuilder: (c, i) => AgentListingCard(
                listing: _listings[i],
                onRefresh: _fetchListings,
              ),
            ),
    );
  }
}
