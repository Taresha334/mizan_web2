import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class NutritionHub extends StatefulWidget {
  const NutritionHub({super.key});

  @override
  State<NutritionHub> createState() => _NutritionHubState();
}

class _NutritionHubState extends State<NutritionHub> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _products = [];
  String _searchQuery = "";

  final String _botToken = "8356088970:AAGQ5vjSde9g6PQ7H5qH_tcc63haGN5L5Ug";
  final String _adminChatId = "958515554";

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final data = await supabase.from('products').select().order('category');
      setState(() {
        _products = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))),
      );
    }

    final filteredProducts = _products.where((p) {
      final nameEn = (p['name_en'] ?? '').toLowerCase();
      final nameAm = (p['name_am'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return nameEn.contains(query) || nameAm.contains(query);
    }).toList();

    Map<String, List<dynamic>> categories = {};
    final Set<String> seenNames = {};

    for (var p in filteredProducts) {
      String name = p['name_en'] ?? '';
      if (seenNames.contains(name)) continue;
      seenNames.add(name);

      String cat = p['category'] ?? 'General';
      categories.putIfAbsent(cat, () => []).add(p);
    }

    final priorityOrder = {
      'Poultry': 1,
      'Broiler': 2,
      'Saso': 3,
      'Dairy': 4,
      'Fattening': 5,
      'Ruminants': 6,
      'Specialty': 7,
      'Custom': 8,
    };

    List<String> sortedCategoryNames = categories.keys.toList();
    sortedCategoryNames.sort(
        (a, b) => (priorityOrder[a] ?? 99).compareTo(priorityOrder[b] ?? 99));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mizan Nutrition Hub",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int cols = constraints.maxWidth > 900
                      ? 3
                      : (constraints.maxWidth > 600 ? 2 : 1);
                  if (categories.isEmpty) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text("No products found.")));
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: constraints.maxWidth < 600
                          ? 0.75
                          : 0.70, // MOBILE VIEW FIX
                    ),
                    itemCount: sortedCategoryNames.length,
                    itemBuilder: (context, index) {
                      String catName = sortedCategoryNames[index];
                      return _buildCategoryCard(catName, categories[catName]!);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1B5E20).withOpacity(0.05),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "Search Mizan feeds...",
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1B5E20)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, List<dynamic> items) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFF1B5E20)),
            width: double.infinity,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6)),
                  child: Image.asset(
                    'assets/images/logos/logo.png', // FIXED UNIFIED PATH
                    width: 25,
                    height: 25,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.inventory_2,
                        size: 20,
                        color: Color(0xFF1B5E20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = items[index];
                bool isAvailable = product['stock_status'] == 'available';

                return ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  title: Text(product['name_en'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                  subtitle: Text("${product['price']} ETB",
                      style: TextStyle(
                          color: isAvailable
                              ? const Color(0xFF2E7D32)
                              : Colors.red,
                          fontWeight: FontWeight.w900,
                          fontSize: 13)),
                  trailing: IconButton(
                    icon: Icon(Icons.add_shopping_cart,
                        color:
                            isAvailable ? const Color(0xFF1B5E20) : Colors.grey,
                        size: 18),
                    onPressed:
                        isAvailable ? () => _showOrderModal(product) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderModal(Map<String, dynamic> product) {
    final name = TextEditingController();
    final phone = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 24,
            right: 24,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Order: ${product['name_en']}",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20))),
            const SizedBox(height: 20),
            TextField(
                controller: name,
                decoration: const InputDecoration(
                    labelText: "Full Name", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(
                controller: phone,
                decoration: const InputDecoration(
                    labelText: "Phone Number", border: OutlineInputBorder()),
                keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  if (name.text.isEmpty || phone.text.isEmpty) return;
                  try {
                    await supabase.from('orders').insert({
                      'customer_name': name.text,
                      'phone_number': phone.text,
                      'product_id': product['id'],
                      'total_price': product['price'],
                      'status': 'pending'
                    });

                    final msg =
                        "🔔 *NUTRITION HUB ORDER*\n📦 *Feed:* ${product['name_en']}\n👤 *Buyer:* ${name.text}\n📞 *Phone:* ${phone.text}";
                    await http.post(
                        Uri.parse(
                            'https://api.telegram.org/bot$_botToken/sendMessage'),
                        body: {
                          'chat_id': _adminChatId,
                          'text': msg,
                          'parse_mode': 'Markdown'
                        });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "Order Successful! Mizan will contact you soon.")));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Submission error.")));
                  }
                },
                child: const Text("Confirm Order",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
