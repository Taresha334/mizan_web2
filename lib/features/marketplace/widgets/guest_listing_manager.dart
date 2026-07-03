// filepath: lib/features/marketplace/widgets/guest_listings_manager.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'guest_listing_card.dart';

class GuestListingsManager extends StatefulWidget {
  const GuestListingsManager({super.key});

  @override
  State<GuestListingsManager> createState() => _GuestListingsManagerState();
}

class _GuestListingsManagerState extends State<GuestListingsManager> {
  final _phoneCtrl = TextEditingController();
  String? _authenticatedPhone;

  @override
  Widget build(BuildContext context) {
    if (_authenticatedPhone == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: "Enter Phone to Manage",
              ),
              keyboardType: TextInputType.phone,
            ),
            ElevatedButton(
              onPressed: () =>
                  setState(() => _authenticatedPhone = _phoneCtrl.text.trim()),
              child: const Text("LOGIN"),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('market_listings')
          .stream(primaryKey: ['id'])
          .eq('contact_phone', _authenticatedPhone!)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;

        if (items.isEmpty)
          return const Center(
            child: Text("No listings found for this number."),
          );

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (ctx, i) => GuestListingCard(
            item: items[i],
            userPhone: _authenticatedPhone!,
            onRefresh: () => setState(() {}),
          ),
        );
      },
    );
  }
}
