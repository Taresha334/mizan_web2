// filepath: lib/features/marketplace/pages/listing_details_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mizan_web/core/l10n/app_localizations.dart';
import '../../../shared/widgets/mizan_image_gallery.dart';

class ListingDetailsPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ListingDetailsPage({super.key, required this.product});

  Future<void> _handleContact(
      BuildContext context, AppLocalizations l10n) async {
    final supabase = Supabase.instance.client;
    final String? agentId = product['agent_id'];

    if (agentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.navContact)),
      );
      return;
    }

    try {
      final agentData = await supabase
          .from('profiles')
          .select('full_name, phone')
          .eq('id', agentId)
          .single();

      final String? phone = agentData['phone'];
      final String name = agentData['full_name'] ?? "Mizan Agent";

      if (phone == null || phone.isEmpty) {
        _showNoPhoneError(context, name, l10n);
        return;
      }

      _showHandshakeDialog(context, name, phone, l10n);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.navContact)),
      );
    }
  }

  void _showNoPhoneError(
      BuildContext context, String name, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${l10n.navContact} $name"),
        content: Text(l10n.navContact),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  void _showHandshakeDialog(
      BuildContext context, String name, String phone, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.submitOrder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${l10n.navAdmin}: $name",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(l10n.heroSubtitle),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20)),
            onPressed: () async {
              Navigator.pop(context);
              final url = Uri.parse("tel:$phone");
              if (await canLaunchUrl(url)) await launchUrl(url);
            },
            child: Text(l10n.navContact,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isSold = product['is_sold'] == true;
    final double qty = (product['quantity'] ?? 0).toDouble();
    final double price = (product['unit_price'] ?? 0).toDouble();
    final double totalValue = qty * price;
    final List<String> images =
        (product['image_urls'] as List?)?.map((e) => e.toString()).toList() ??
            [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navProducts),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: MizanImageGallery(
                    imageUrls: images,
                    listingId: product['id'].toString(),
                    isAdminMode: false,
                  ),
                ),
                if (isSold)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Container(
                          transform: Matrix4.rotationZ(-0.15),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Text(l10n.outOfStock.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product['title'] ?? l10n.appTitle,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            decoration:
                                isSold ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSold ? Colors.red[100] : Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isSold ? l10n.outOfStock : l10n.available,
                          style: TextStyle(
                              color:
                                  isSold ? Colors.red[900] : Colors.green[900],
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!)),
                    child: Column(
                      children: [
                        _buildPriceRow(
                            l10n.orderTitle, "${price.toStringAsFixed(2)} ETB"),
                        const Divider(),
                        _buildPriceRow(l10n.productCategory,
                            "${qty.toStringAsFixed(0)} ${product['unit_label'] ?? ''}"),
                        const Divider(),
                        _buildPriceRow(l10n.submitOrder,
                            "${totalValue.toStringAsFixed(2)} ETB",
                            isTotal: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildVerificationRow(isSold, l10n),
                  const SizedBox(height: 30),
                  Text(l10n.navEducation,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(product['description'] ?? "",
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey[800], height: 1.5)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Color(0xFF1B5E20), size: 20),
                      const SizedBox(width: 8),
                      Text(product['location'] ?? "",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isSold ? Colors.grey : const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed:
                          isSold ? null : () => _handleContact(context, l10n),
                      child: Text(isSold ? l10n.outOfStock : l10n.submitOrder,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationRow(bool isSold, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.verified,
              color: isSold ? Colors.grey : Colors.blue, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.appTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue)),
              Text(l10n.heroSubtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: isTotal ? 20 : 16,
                  fontWeight: FontWeight.bold,
                  color: isTotal ? const Color(0xFF1B5E20) : Colors.black)),
        ],
      ),
    );
  }
}
