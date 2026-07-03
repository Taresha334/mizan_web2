// filepath: lib/features/marketplace/pages/mizan_category_view.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/product_image.dart';

class MizanCategoryView extends StatefulWidget {
  final String categoryKey;
  final Map<String, String> categoryNames;

  const MizanCategoryView({
    super.key,
    required this.categoryKey,
    required this.categoryNames,
  });

  @override
  State<MizanCategoryView> createState() => _MizanCategoryViewState();
}

class _MizanCategoryViewState extends State<MizanCategoryView> {
  // 1. Full paths matching pubspec.yaml declaration
  final Map<String, String> _localImageMap = {
    'poultry': 'assets/images/categories/poultry.png',
    'camel': 'assets/images/categories/camel.jpg',
    'sheep & goat': 'assets/images/categories/shoat.jpg',
    'beef fattening': 'assets/images/categories/beef.jpg',
    'dairy': 'assets/images/categories/dairy.png',
    'saso': 'assets/images/categories/saso.jpg',
    'broiler': 'assets/images/categories/broilers.jpg',
    'others': 'assets/images/categories/others.png',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 2. Pre-cache the image to prevent flickering on Web
    final lookupKey = widget.categoryKey.toLowerCase().trim();
    final path =
        _localImageMap[lookupKey] ?? 'assets/images/categories/others.png';
    precacheImage(AssetImage(path), context);
  }

  @override
  Widget build(BuildContext context) {
    final String lookupKey = widget.categoryKey.toLowerCase().trim();
    final String assetPath =
        _localImageMap[lookupKey] ?? 'assets/images/categories/others.png';

    return Scaffold(
      body: FutureBuilder(
        future: Supabase.instance.client
            .from('categories')
            .select('*, products(*)')
            .eq('name', widget.categoryKey)
            .single(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(child: Text("Error loading category."));
          }

          final data = snapshot.data as Map<String, dynamic>;
          final products = (data['products'] as List<dynamic>?) ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(widget.categoryNames['en'] ?? widget.categoryKey),
                  background: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    // 3. Ensuring Flutter uses the main bundle without package interference
                    package: null,
                    errorBuilder: (context, error, stack) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final p = products[index];
                  return Card(
                    child: ListTile(
                      leading: MizanProductImage(
                        imageUrl: p['image_url'],
                        width: 60,
                        height: 60,
                      ),
                      title: Text(p['name_en'] ?? 'Product'),
                    ),
                  );
                }, childCount: products.length),
              ),
            ],
          );
        },
      ),
    );
  }
}
