import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../widgets/hero_slider.dart';
import '../widgets/featured_mizan_carousel.dart';
import '../../../shared/widgets/footer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = Supabase.instance.client
        .from('market_categories')
        .select('name')
        .order('name');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 10),
              const HeroSlider(),
              _buildSectionTitle("GET STARTED"),
              _buildCategorySearchAnchor(context),
              _buildSellingInstructionCard(context),
              _buildSlimAIVisionCTA(context, l10n),
              const FeaturedMizanCarousel(),
              const Footer(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySearchAnchor(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SearchAnchor(
        builder: (BuildContext context, SearchController controller) {
          return SearchBar(
            controller: controller,
            hintText: "What do you want to buy?",
            onTap: () => controller.openView(),
            onChanged: (_) => controller.openView(),
            leading: const Icon(Icons.search, color: Color(0xFF1B5E20)),
            elevation: const WidgetStatePropertyAll(0),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        },
        suggestionsBuilder:
            (BuildContext context, SearchController controller) async {
              final categories = await _categoriesFuture;
              final query = controller.text.toLowerCase();

              final filtered = categories
                  .where(
                    (c) => c['name'].toString().toLowerCase().contains(query),
                  )
                  .toList();

              return filtered.map((cat) {
                final name = cat['name'] as String;
                return ListTile(
                  title: Text(name),
                  leading: const Icon(Icons.category, color: Color(0xFF1B5E20)),
                  onTap: () {
                    controller.closeView(name);
                    context.push(
                      '/marketplace?category=${Uri.encodeComponent(name)}',
                    );
                  },
                );
              }).toList();
            },
      ),
    );
  }

  Widget _buildSellingInstructionCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "NEW TO MIZAN? START HERE",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text:
                      "• Want to sell regularly? Become a Partner Agent for exclusive benefits. Click ",
                ),
                WidgetSpan(
                  child: InkWell(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      "AGENT",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: " to register."),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text:
                      "• Need a one-time sale? Use our Quick Post feature. Click ",
                ),
                WidgetSpan(
                  child: InkWell(
                    onTap: () => context.go('/non-partner-post'),
                    child: const Text(
                      "SELL",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: " to list your product instantly."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlimAIVisionCTA(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Color(0xFFC6A664), size: 30),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Expert livestock advice for instant results.",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          ElevatedButton(
            onPressed: () => context.go('/expert-advisors'),
            child: const Text("ASK"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
    );
  }
}
