// filepath: lib/features/agents/agent_hub.dart
import 'package:flutter/material.dart';
import 'pages/agent_post_flow.dart';
import 'widgets/agent_listings_manager.dart';

class AgentHub extends StatelessWidget {
  const AgentHub({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          title: const Text(
            "MIZAN AGENT HUB",
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFFC6A664),
            indicatorWeight: 4,
            tabs: [
              Tab(icon: Icon(Icons.add_circle_outline), text: "POST NEW"),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: "MY LISTINGS"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [AgentPostFlow(), AgentListingsManager()],
        ),
      ),
    );
  }
}
