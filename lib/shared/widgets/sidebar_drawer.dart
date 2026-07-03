import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SidebarDrawer extends StatelessWidget {
  const SidebarDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            child: Center(
              child: Text(
                "QUICK ACTIONS",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle, color: Color(0xFFC6A664)),
            title: const Text("SELL YOUR PRODUCTS"),
            onTap: () {
              Navigator.pop(context); // Close drawer
              context.push('/non-partner-post');
            },
          ),
          // Add other non-redundant, specialized utility links here if needed
        ],
      ),
    );
  }
}
