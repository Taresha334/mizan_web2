// filepath: lib/features/marketplace/non-partner_hub.dart
import 'package:flutter/material.dart';
import 'package:mizan_web/features/marketplace/pages/non_partner_post_form.dart'; // Your existing form
import 'package:mizan_web/features/marketplace/widgets/guest_listing_manager.dart'; // The management widget

class NonPartnerHub extends StatelessWidget {
  const NonPartnerHub({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          title: const Text("Mizan Guest Marketplace"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add_circle), text: "POST"),
              Tab(icon: Icon(Icons.inventory), text: "MY LISTINGS"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            NonPartnerPostForm(), // Your existing code, untouched
            GuestListingsManager(), // The widget we just created
          ],
        ),
      ),
    );
  }
}
