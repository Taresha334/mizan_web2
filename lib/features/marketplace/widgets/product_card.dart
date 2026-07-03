import 'package:flutter/material.dart';
import '../../../shared/widgets/mizan_image_gallery.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic>? profile;
  final VoidCallback onTap;
  final bool isSold;
  final bool isHighlighted; // New parameter

  const ProductCard({
    super.key,
    required this.data,
    required this.profile,
    required this.onTap,
    required this.isSold,
    this.isHighlighted = false, // Defaults to false
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Card(
            elevation: isHighlighted
                ? 4
                : 0, // Adds subtle depth to highlighted items
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                // Use a different color/thickness if highlighted
                color: isSold
                    ? Colors.grey[300]!
                    : (isHighlighted
                          ? const Color(0xFF1B5E20)
                          : Colors.grey[100]!),
                width: isHighlighted ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: MizanImageGallery(
                    imageUrls:
                        (data['image_urls'] as List?)?.cast<String>() ?? [],
                    listingId: data['id'].toString(),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (profile?['full_name'] ?? "Mizan Farmer")
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        Text(
                          data['title'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSold
                                ? Colors.grey
                                : const Color(0xFF1B5E20),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${data['unit_price']} ETB",
                          style: TextStyle(
                            color: isSold
                                ? Colors.grey
                                : const Color(0xFFC6A664),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // SOLD Badge Overlay
          if (isSold)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "SOLD",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          // Optional: Highlight badge
          if (isHighlighted && !isSold)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B5E20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  size: 12,
                  color: Color(0xFFC6A664),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
