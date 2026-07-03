// filepath: lib/features/marketplace/pages/category_detail_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/mizan_image_gallery.dart';

class CategoryDetailPage extends StatefulWidget {
  final String categoryName;

  const CategoryDetailPage({super.key, required this.categoryName});

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  final _supabase = Supabase.instance.client;
  final List<String> _supportNumbers = ["0935707075", "0936262387"];

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse("tel:${phoneNumber.trim()}");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _contactAgent(String? agentId) async {
    if (agentId == null) {
      _showSupportOptions();
      return;
    }
    try {
      final res = await _supabase
          .from('profiles')
          .select('phone')
          .eq('id', agentId)
          .maybeSingle();
      if (res != null && res['phone'] != null) {
        _makeCall(res['phone'].toString());
      } else {
        _showSupportOptions();
      }
    } catch (e) {
      _showSupportOptions();
    }
  }

  void _showSupportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "CONTACT MIZAN SUPPORT",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
            ..._supportNumbers.map(
              (num) => ListTile(
                leading: const Icon(Icons.phone, color: Color(0xFF1B5E20)),
                title: Text(
                  num,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _makeCall(num);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.categoryName.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('market_listings')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          // Filter by category and approval status
          final products = snapshot.data!.where((item) {
            final itemCategory = (item['category_name'] ?? '')
                .toString()
                .toLowerCase();
            final targetCategory = widget.categoryName.toLowerCase();
            final status = item['status']?.toString().toLowerCase();
            return itemCategory == targetCategory &&
                (status == 'approved' || status == 'sold_pending');
          }).toList();

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No products in ${widget.categoryName} yet.",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) =>
                _buildProductCard(products[index], l10n),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data, AppLocalizations l10n) {
    final bool isSold =
        data['is_sold'] == true || data['status'] == 'sold_pending';

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(data, l10n),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ColorFiltered(
                    colorFilter: isSold
                        ? const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          )
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply,
                          ),
                    child: MizanImageGallery(
                      imageUrls: List<String>.from(data['image_urls'] ?? []),
                      listingId: data['id'].toString(),
                    ),
                  ),
                  if (isSold)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "SOLD",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                    ),
                    Text(
                      "${data['unit_price']} ETB",
                      style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "${data['location']}",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(Map<String, dynamic> data, AppLocalizations l10n) {
    final bool isSold =
        data['is_sold'] == true || data['status'] == 'sold_pending';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              data['title'] ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "${data['unit_price']} ETB",
              style: const TextStyle(
                fontSize: 24,
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w900,
              ),
            ),
            const Divider(height: 32),
            const Text(
              "DESCRIPTION",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data['description'] ?? "No description provided.",
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSold ? Colors.grey : const Color(0xFF1B5E20),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isSold
                  ? null
                  : () => data['is_mizan_product'] == true
                        ? _makeCall(_supportNumbers[0])
                        : _contactAgent(data['agent_id']),
              child: Text(
                isSold ? "OUT OF STOCK" : "CONTACT FOR DETAILS",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
