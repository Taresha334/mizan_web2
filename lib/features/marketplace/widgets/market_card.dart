// filepath: lib/features/marketplace/widgets/market_card.dart

import 'package:flutter/material.dart';

class MarketCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const MarketCard({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // PRODUCTION LOGIC: Ensure the card identifies 'sold' status accurately
    // This catches the boolean flip from the Agent Portal toggle.
    final bool isSold = (data['is_sold'] == true) ||
        (data['status'] == 'sold') ||
        (data['status'] == 'archived');

    final bool isMizan = data['is_mizan_product'] == true;
    final List<dynamic> imageUrls = data['image_urls'] ?? [];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSold
              ? Colors.grey[300]!
              : (isMizan ? const Color(0xFFFFB300) : Colors.grey[200]!),
          width: isMizan ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isSold ? null : onTap, // Optional: Disable tap if sold
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                Container(
                  height: 110,
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: isMizan
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Image.asset('assets/images/logos/logo.png',
                              fit: BoxFit.contain),
                        )
                      : imageUrls.isNotEmpty
                          ? ColorFiltered(
                              colorFilter: isSold
                                  ? const ColorFilter.mode(
                                      Colors.grey, BlendMode.saturation)
                                  : const ColorFilter.mode(
                                      Colors.transparent, BlendMode.multiply),
                              child: Image.network(
                                imageUrls[0],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image,
                                        color: Colors.grey),
                              ),
                            )
                          : const Icon(Icons.agriculture,
                              size: 40, color: Color(0xFF1B5E20)),
                ),
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Product',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          decoration:
                              isSold ? TextDecoration.lineThrough : null,
                          color: isSold ? Colors.grey : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${data['unit_price']} ETB",
                        style: TextStyle(
                          color: isSold ? Colors.grey : const Color(0xFF1B5E20),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Badge Row
                      Row(
                        children: [
                          Icon(
                            isMizan ? Icons.verified : Icons.location_on,
                            size: 12,
                            color: isSold
                                ? Colors.grey
                                : (isMizan
                                    ? const Color(0xFFFFB300)
                                    : Colors.grey[600]),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isSold
                                  ? "ITEM NO LONGER AVAILABLE"
                                  : (isMizan
                                      ? "Mizan Factory"
                                      : (data['location'] ?? "Unknown")),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isSold
                                      ? Colors.grey
                                      : (isMizan
                                          ? const Color(0xFFE65100)
                                          : Colors.grey[600]),
                                  fontWeight: isMizan
                                      ? FontWeight.bold
                                      : FontWeight.normal),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // THE SOLD STAMP OVERLAY
            if (isSold)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.5),
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border:
                              Border.all(color: Colors.red[700]!, width: 2.5),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            )
                          ],
                        ),
                        child: Text(
                          "SOLD",
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
