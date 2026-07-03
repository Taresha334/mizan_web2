// filepath: lib/features/farmers/pages/farmer_main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FarmerMainShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  const FarmerMainShell({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Row(
        children: [
          if (isWideScreen) ...[
            NavigationRail(
              backgroundColor: const Color(0xFF1B5E20),
              unselectedIconTheme: const IconThemeData(color: Colors.white70),
              selectedIconTheme: const IconThemeData(color: Colors.white),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
              selectedLabelTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              selectedIndex: selectedIndex,
              onDestinationSelected: (int index) =>
                  _handleNavigation(context, index),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.tips_and_updates_outlined),
                  selectedIcon: Icon(Icons.tips_and_updates),
                  label: Text("Smart Tips"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.support_agent_outlined),
                  selectedIcon: Icon(Icons.support_agent),
                  label: Text("Expert Advisors"),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
          ],
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : BottomNavigationBar(
              currentIndex: selectedIndex,
              selectedItemColor: const Color(0xFF1B5E20),
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              onTap: (int index) => _handleNavigation(context, index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.tips_and_updates_outlined),
                  activeIcon: Icon(Icons.tips_and_updates),
                  label: "Smart Tips",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.support_agent_outlined),
                  activeIcon: Icon(Icons.support_agent),
                  label: "Expert Advisors",
                ),
              ],
            ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == 0) {
      context.go('/ai-expert/tips');
    } else if (index == 1) {
      context.go('/ai-expert/advisors');
    }
  }
}
