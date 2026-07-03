import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class AdminSidebarNav extends StatelessWidget {
  const AdminSidebarNav({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          // Use your new Navigation items here
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text("Moderation"),
            onTap: () => context.go('/admin/manage-products'),
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text("Users"),
            onTap: () => context.go('/admin/agents'),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () async {
              await supabase.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(color: Color(0xFF1B5E20)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.agriculture, color: Colors.white, size: 40),
            const SizedBox(height: 10),
            const Text(
              "MIZAN ADMIN",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
