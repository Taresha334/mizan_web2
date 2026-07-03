// filepath: lib/features/home/widgets/category_grid.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_localizations.dart';

class CategoryGrid extends StatefulWidget {
  const CategoryGrid({super.key});

  @override
  CategoryGridState createState() => CategoryGridState(); // Public State for GlobalKey access
}

class CategoryGridState extends State<CategoryGrid> {
  final Map<String, int> _categoryCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    refreshCounts(); // Initial fetch
  }

  /// Public method triggered by HomePage's RefreshIndicator
  Future<void> refreshCounts() async {
    try {
      final supabase = Supabase.instance.client;

      // Production-ready query: Fetch only the category_id of active/approved items
      // This is much lighter than fetching full rows.
      final response = await supabase
          .from('market_listings') // Ensure this matches your table name
          .select('category_id')
          .or('status.eq.approved,status.eq.active');

      final Map<String, int> counts = {};

      if (response != null) {
        for (var item in (response as List)) {
          final catId = item['category_id']?.toString();
          if (catId != null) {
            counts[catId] = (counts[catId] ?? 0) + 1;
          }
        }
      }

      if (mounted) {
        setState(() {
          _categoryCounts.clear();
          _categoryCounts.addAll(counts);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Mizan Category Count Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    // Professional Mizan Palette
    const Color mizanGreen = Color(0xFF1B5E20);
    const Color harvestGold = Color(0xFFC6A664);

    final List<Map<String, dynamic>> categories = [
      {
        'id': 'animal_feed',
        'name': l10n.catAnimalFeed,
        'icon': Icons.bakery_dining_rounded,
        'path': '/marketplace?category=Animal Feed',
        'color': mizanGreen,
      },
      {
        'id': 'livestock',
        'name': l10n.catLivestock,
        'icon': Icons.pets_rounded,
        'path': '/marketplace?category=Livestock',
        'color': const Color(0xFF5D4037),
      },
      {
        'id': 'tools_machinery',
        'name': l10n.catFarmTools,
        'icon': Icons.handyman_rounded,
        'path': '/marketplace?category=Farm Tools',
        'color': harvestGold,
      },
      {
        'id': 'seeds_crops',
        'name': l10n.catSeedsCrops,
        'icon': Icons.eco_rounded,
        'path': '/marketplace?category=Seeds/Crops',
        'color': const Color(0xFF2E7D32),
      },
      {
        'id': 'agri_products',
        'name': l10n.catAgriProducts,
        'icon': Icons.agriculture_rounded,
        'path': '/marketplace?category=Agri-products',
        'color': const Color(0xFF00796B),
      },
      {
        'id': 'vet',
        'name': l10n.findVetNearby,
        'icon': Icons.medical_services_rounded,
        'path': '/mizan-map?category=vet',
        'color': const Color(0xFF1565C0),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 4 : 6,
        mainAxisSpacing: 20,
        crossAxisSpacing: 12,
        childAspectRatio: isMobile ? 0.65 : 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final int count = _categoryCounts[cat['id']] ?? 0;

        return _CategoryItem(
          cat: cat,
          count: count,
          showBadge: cat['id'] != 'vet',
        );
      },
    );
  }
}

class _CategoryItem extends StatefulWidget {
  final Map<String, dynamic> cat;
  final int count;
  final bool showBadge;

  const _CategoryItem({
    required this.cat,
    required this.count,
    required this.showBadge,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    final Color brandColor = cat['color'] as Color;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => context.push(cat['path']),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: Matrix4.identity()..scale(_isPressed ? 0.92 : 1.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: brandColor.withOpacity(0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: brandColor.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(cat['icon'], color: brandColor, size: 26),
                  ),
                ),
              ),
              if (widget.showBadge && widget.count > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFC6A664),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${widget.count}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cat['name'],
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D2D2D),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
