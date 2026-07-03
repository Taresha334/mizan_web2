// filepath: lib/features/agents/pages/agent_portal.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';

class AgentPortal extends StatefulWidget {
  const AgentPortal({super.key});

  @override
  State<AgentPortal> createState() => _AgentPortalState();
}

class _AgentPortalState extends State<AgentPortal> {
  final _supabase = Supabase.instance.client;
  late Future<String?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _initializeAgent();
  }

  Future<String?> _initializeAgent() async {
    final String? nativeId = _supabase.auth.currentUser?.id;
    if (nativeId != null) return nativeId;

    // Check custom auth via provider
    if (!mounted) return null;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.isCustomAuthenticated ? authProvider.customId : null;
  }

  Future<void> _handleMarkSold(String id) async {
    try {
      await _supabase
          .from('market_listings')
          .update({
            'is_sold': true,
            'status': 'sold',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
      if (mounted)
        _showSnackBar("Inventory Updated: Item marked as Sold", Colors.green);
    } catch (e) {
      debugPrint("MIZAN DEBUG [AgentPortal ERROR]: Mark sold fail: $e");
    }
  }

  Future<void> _handlePurge(String id) async {
    try {
      await _supabase.from('market_listings').delete().eq('id', id);
      if (mounted)
        _showSnackBar("Product removed from system", Colors.redAccent);
    } catch (e) {
      debugPrint("MIZAN DEBUG [AgentPortal ERROR]: Purge fail: $e");
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      appBar: AppBar(
        title: const Text(
          "Agent Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        actions: [
          IconButton(
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            );
          }
          final resolvedUid = snapshot.data;
          if (resolvedUid == null)
            return const Center(child: Text("Authentication required."));

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase
                .from('market_listings')
                .stream(primaryKey: ['id'])
                .eq('agent_id', resolvedUid)
                .order('created_at', ascending: false),
            builder: (context, streamSnapshot) {
              if (streamSnapshot.connectionState == ConnectionState.waiting)
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                );

              final listings = streamSnapshot.data ?? [];
              if (listings.isEmpty)
                return const Center(child: Text("No active listings found."));

              return LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 900
                      ? 3
                      : (constraints.maxWidth > 600 ? 2 : 1);
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: constraints.maxWidth > 600 ? 2.5 : 3.2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final item = listings[index];
                      final bool isSold = item['is_sold'] == true;
                      return Card(
                        child: ListTile(
                          title: Text(item['title'] ?? "Untitled"),
                          subtitle: Text("${item['unit_price']} ETB"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: isSold
                                    ? null
                                    : () => _handleMarkSold(item['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSold
                                      ? Colors.grey
                                      : const Color(0xFF1B5E20),
                                ),
                                child: Text(
                                  isSold ? "SOLD" : "MARK SOLD",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                onPressed: () => _handlePurge(item['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B5E20),
        onPressed: () => context.push('/post-product'),
        label: const Text(
          "POST NEW PRODUCT",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
