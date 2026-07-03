import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// These imports must match the new folder structure exactly
import '../../../models/product_model.dart';

class NutritionProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Product> _allProducts = [];
  bool _isLoading = false;

  // Public Getters
  List<Product> get allProducts => _allProducts;
  bool get isLoading => _isLoading;

  // --- Logic for Nested Categories (The Sandwich Menu logic) ---

  List<Product> get poultryProducts => _allProducts
      .where((p) => p.mainCategory.toLowerCase() == 'poultry')
      .toList();

  List<Product> get ruminantProducts => _allProducts
      .where((p) => p.mainCategory.toLowerCase() == 'ruminant')
      .toList();

  // --- Database Actions ---

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetching from your Supabase 'products' table
      final response = await _supabase
          .from('products')
          .select()
          .order('name', ascending: true);

      _allProducts =
          (response as List).map((item) => Product.fromJson(item)).toList();
    } catch (e) {
      debugPrint("Mizan Provider Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search logic for farmers looking for specific feed (e.g. "Saso")
  void searchProducts(String query) {
    if (query.isEmpty) {
      fetchProducts();
    } else {
      _allProducts = _allProducts
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      notifyListeners();
    }
  }
}
