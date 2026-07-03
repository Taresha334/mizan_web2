import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboard extends StatelessWidget {
  final Widget child;
  const AdminDashboard({super.key, required this.child});

  // Keep these constants static or inside the widget
  static const List<Map<String, dynamic>> navItems = [
    {
      'label': 'Moderation',
      'icon': Icons.admin_panel_settings,
      'route': '/admin/manage-products',
    },
    {
      'label': 'Users',
      'icon': Icons.people_alt_outlined,
      'route': '/admin/agents',
    },
    {
      'label': 'Direct Post',
      'icon': Icons.add_business,
      'route': '/admin/post-product',
    },
    {'label': 'Prices', 'icon': Icons.sell_rounded, 'route': '/admin/prices'},
    {
      'label': 'Categories',
      'icon': Icons.category_rounded,
      'route': '/admin/manage-categories',
    },
    {
      'label': 'Audit Log',
      'icon': Icons.history_edu_rounded,
      'route': '/admin/audit',
    },
  ];

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < navItems.length; i++) {
      if (location.startsWith(navItems[i]['route'])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 1100;
    final int currentIdx = _getSelectedIndex(context);

    // NO SCAFFOLD. NO APPBAR.
    // This now renders directly into the Body of the Global Shell.
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              if (isDesktop)
                NavigationRail(
                  extended: width > 1300,
                  selectedIndex: currentIdx,
                  onDestinationSelected: (idx) =>
                      context.go(navItems[idx]['route']),
                  destinations: navItems
                      .map(
                        (i) => NavigationRailDestination(
                          icon: Icon(i['icon']),
                          label: Text(i['label']),
                        ),
                      )
                      .toList(),
                ),
              Expanded(child: child),
            ],
          ),
        ),
        if (!isDesktop)
          BottomNavigationBar(
            currentIndex: currentIdx,
            onTap: (idx) => context.go(navItems[idx]['route']),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF1B5E20),
            items: navItems
                .map(
                  (i) => BottomNavigationBarItem(
                    icon: Icon(i['icon'], size: 20),
                    label: i['label'],
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
