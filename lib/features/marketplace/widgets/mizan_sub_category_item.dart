import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MizanSubCategoryItem extends StatelessWidget {
  final Map<String, dynamic> product;

  const MizanSubCategoryItem({super.key, required this.product});

  Future<void> _callAdmin(BuildContext context) async {
    // Primary Admin Numbers
    final List<String> adminNumbers = ["0970807755", "0974506299"];
    final Uri url = Uri.parse("tel:${adminNumbers[0]}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not initiate call")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _callAdmin(context),
      child: Container(
        width: 150,
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['name_en'] ?? 'Product',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1B5E20),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              "${product['price_etb'] ?? 0} ETB",
              style: const TextStyle(
                color: Color(0xFFC6A664),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.phone_in_talk, size: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
