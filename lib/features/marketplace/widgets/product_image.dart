// lib/features/market/widgets/product_image.dart
import 'package:flutter/material.dart';

class MizanProductImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;

  const MizanProductImage({
    super.key,
    this.imageUrl,
    this.width = 50,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Check if the URL is reaching the widget
    debugPrint("DEBUG: MizanProductImage received URL: $imageUrl");

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      debugPrint("DEBUG: No valid URL, showing placeholder");
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl!.trim(), // Trim whitespace just in case
        key: ValueKey(imageUrl!),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint("DEBUG: Image Load Error: $error");
          return _buildPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.green[100], // Visible color to debug if it's appearing
      child: const Icon(Icons.broken_image, color: Colors.green),
    );
  }
}
