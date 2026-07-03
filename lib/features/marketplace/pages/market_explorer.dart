// filepath: lib/features/marketplace/pages/market_explorer.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../controllers/market_controller.dart';
import '../widgets/product_card.dart';
import '../widgets/product_details_sheet.dart';
import '../widgets/search_bar.dart';
import '../widgets/category_selector.dart';
import '../widgets/mizan_category_strip.dart';
import '../widgets/mizan_sub_category_item.dart';

class MarketExplorer extends StatefulWidget {
  const MarketExplorer({super.key});

  @override
  State<MarketExplorer> createState() => _MarketExplorerState();
}

class _MarketExplorerState extends State<MarketExplorer> {
  final MarketController _controller = MarketController();
  final supabase = Supabase.instance.client;
  bool _hasProcessedInitialCategory = false;

  String? _selectedFactoryCategory;
  final List<String> _factoryCategories = [
    "Poultry",
    "Broiler",
    "Dairy",
    "Beef Fattening",
    "Saso",
    "Sheep & Goat",
    "Camel",
    "Others",
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleInitialCategorySelection);
  }

  void _handleInitialCategorySelection() {
    if (_hasProcessedInitialCategory) return;
    if (!_controller.isLoadingCategories &&
        _controller.categoryMap.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final queryParams = GoRouterState.of(context).uri.queryParameters;
        final categoryName = queryParams['category'];
        if (categoryName != null) {
          final String decodedName = Uri.decodeComponent(categoryName);
          if (_controller.categoryMap.containsKey(decodedName)) {
            _controller.toggleCategory(_controller.categoryMap[decodedName]);
          }
        }
        setState(() => _hasProcessedInitialCategory = true);
      });
      _controller.removeListener(_handleInitialCategorySelection);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleInitialCategorySelection);
    _controller.dispose();
    super.dispose();
  }

  Widget _buildFactorySubCategoryList() {
    if (_selectedFactoryCategory == null) return const SizedBox.shrink();

    // The stream is initialized on the full table, and filtered via .map()
    // to bypass the SDK method-signature conflict.
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('products')
          .stream(primaryKey: ['id'])
          .map(
            (items) => items
                .where(
                  (item) =>
                      item['category'] == _selectedFactoryCategory &&
                      item['is_mizan_factory'] == true,
                )
                .toList(),
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox(
            height: 100,
            child: Center(child: Text("Sync Error")),
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(child: Text("No products found.")),
          );
        }

        return SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (ctx, i) => MizanSubCategoryItem(product: items[i]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFFF1F5F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          title: Text(
            l10n.portalTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MizanSearchBar(
                controller: _controller,
                hint: l10n.searchHint,
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/non-partner-post'),
          backgroundColor: const Color(0xFFC6A664),
          label: const Text(
            "SELL YOUR PRODUCTS",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B5E20),
            ),
          ),
        ),
        body: _controller.isLoadingCategories
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            "MIZAN FACTORY",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                        MizanCategoryStrip(
                          categories: _factoryCategories,
                          selectedCategory: _selectedFactoryCategory,
                          onSelect: (cat) =>
                              setState(() => _selectedFactoryCategory = cat),
                        ),
                        _buildFactorySubCategoryList(),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: CategorySelector(controller: _controller),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _controller.marketListingsStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const SliverToBoxAdapter(
                            child: Center(child: CircularProgressIndicator()),
                          );

                        final allItems = snapshot.data!
                            .where(
                              (item) =>
                                  _controller.searchQuery.isEmpty ||
                                  (item['title'] ?? '')
                                      .toString()
                                      .toLowerCase()
                                      .contains(_controller.searchQuery),
                            )
                            .toList();

                        if (_controller.selectedCategoryId != null) {
                          allItems.sort((a, b) {
                            final bool aMatch =
                                a['category_id']?.toString() ==
                                _controller.selectedCategoryId;
                            final bool bMatch =
                                b['category_id']?.toString() ==
                                _controller.selectedCategoryId;
                            return aMatch == bMatch ? 0 : (aMatch ? -1 : 1);
                          });
                        }

                        _controller.batchLoadProfiles(allItems);
                        if (allItems.isEmpty)
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: 50),
                              child: Center(child: Text("No products found.")),
                            ),
                          );

                        return SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.7,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => ProductCard(
                              data: allItems[i],
                              isHighlighted:
                                  allItems[i]['category_id']?.toString() ==
                                  _controller.selectedCategoryId,
                              profile:
                                  _controller
                                      .profileCache[allItems[i]['agent_id'] ??
                                      allItems[i]['farmer_id']],
                              isSold: _controller.checkIsSold(allItems[i]),
                              onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => ProductDetailsSheet(
                                  data: allItems[i],
                                  profile:
                                      _controller
                                          .profileCache[allItems[i]['agent_id'] ??
                                          allItems[i]['farmer_id']],
                                  onContact: (id, phone) {},
                                ),
                              ),
                            ),
                            childCount: allItems.length,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
