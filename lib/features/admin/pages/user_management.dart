// filepath: lib/features/admin/pages/user_management.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("User Lifecycle Management"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Partners"),
              Tab(text: "Non-Partners"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList(role: 'partner'),
            _buildUserList(role: 'non-partner'),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList({required String role}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('role', role)
          .order('updated_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!;
        if (users.isEmpty) return Center(child: Text("No $role users found."));

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, i) {
            final user = users[i];
            return ListTile(
              title: Text(user['full_name'] ?? 'No Name'),
              subtitle: Text(
                "Phone: ${user['phone'] ?? 'N/A'} | Banned: ${user['is_banned'] == true ? 'YES' : 'NO'}",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      user['is_banned'] == true ? Icons.lock_open : Icons.block,
                      color: Colors.orange,
                    ),
                    onPressed: () =>
                        _toggleBan(user['id'], user['is_banned'] ?? false),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _deleteUser(user['id']),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleBan(String userId, bool currentStatus) async {
    await _supabase
        .from('profiles')
        .update({'is_banned': !currentStatus})
        .eq('id', userId);
  }

  Future<void> _deleteUser(String userId) async {
    await _supabase.from('profiles').delete().eq('id', userId);
  }
}
