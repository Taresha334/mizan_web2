import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PriceManager extends StatefulWidget {
  const PriceManager({super.key});

  @override
  State<PriceManager> createState() => _PriceManagerState();
}

class _PriceManagerState extends State<PriceManager> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Load products from Supabase
  Future<void> _fetchProducts() async {
    try {
      final data = await supabase
          .from('products')
          .select()
          .order('category', ascending: true);
      setState(() {
        _products = data;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading products: $e")),
      );
    }
  }

  // Update price in Supabase
  Future<void> _updatePrice(String id, String newPrice) async {
    final double? price = double.tryParse(newPrice);
    if (price == null) return;

    await supabase.from('products').update({'price_etb': price}).eq('id', id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Price updated successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin: Set Feed Prices"),
        backgroundColor: const Color(0xFF1B5E20),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  final controller = TextEditingController(
                    text: product['price_etb'].toString(),
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(product['name_en'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(product['category']),
                      trailing: SizedBox(
                        width: 150,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            suffixText: "ETB",
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onSubmitted: (value) =>
                              _updatePrice(product['id'], value),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
