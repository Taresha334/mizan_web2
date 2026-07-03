import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navbar.dart';
import '../widgets/sidebar_drawer.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return Scaffold(
      appBar: const Navbar(),
      endDrawer: const SidebarDrawer(),
      body: child,
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF1B5E20),
              unselectedItemColor: Colors.grey,
              currentIndex: _calculateSelectedIndex(context),
              onTap: (index) => _onItemTapped(context, index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.storefront),
                  label: 'Market',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: 'Find Agents',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.work),
                  label: "Agent Entrance",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline),
                  label: 'Sell',
                ),
              ],
            )
          : null,
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/marketplace')) return 0;
    if (location.startsWith('/mizan-map')) return 1;
    // Map Agent Entrance tab to /login
    if (location.startsWith('/login') || location.startsWith('/agent-portal'))
      return 2;
    if (location.startsWith('/non-partner-post')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/marketplace');
        break;
      case 1:
        context.go('/mizan-map');
        break;
      case 2:
        context.go('/login'); // Redirect to portal_login_page.dart
        break;
      case 3:
        context.go('/non-partner-post');
        break;
    }
  }
}
