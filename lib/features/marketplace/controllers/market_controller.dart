import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, String> categoryMap = {};
  Map<String, Map<String, dynamic>> profileCache = {};
  bool isLoadingCategories = true;
  String? selectedCategoryId;
  String searchQuery = '';

  MarketController() {
    initializeCategories();
  }

  Future<void> initializeCategories() async {
    try {
      final List<dynamic> data = await _supabase
          .from('market_categories')
          .select('id, name');

      categoryMap = {
        for (var item in data) item['name'].toString(): item['id'].toString(),
      };
    } catch (e) {
      debugPrint("Category Init Error: $e");
    } finally {
      isLoadingCategories = false;
      notifyListeners();
    }
  }

  // NEW: Dedicated method to set category safely
  void setCategoryById(String? id) {
    if (selectedCategoryId != id) {
      selectedCategoryId = id;
      notifyListeners();
    }
  }

  Future<void> batchLoadProfiles(List<Map<String, dynamic>> items) async {
    final ids = items
        .map((i) => i['agent_id'] ?? i['farmer_id'] ?? i['non_partner_id'])
        .whereType<String>()
        .where((id) => !profileCache.containsKey(id))
        .toSet()
        .toList();

    if (ids.isEmpty) return;

    try {
      final List<dynamic> res = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', ids);
      for (var p in res) {
        profileCache[p['id']] = p;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Profile Batch Error: $e");
    }
  }

  void updateSearch(String query) {
    searchQuery = query.toLowerCase();
    notifyListeners();
  }

  void toggleCategory(String? categoryId) {
    selectedCategoryId = (selectedCategoryId == categoryId) ? null : categoryId;
    notifyListeners();
  }

  bool checkIsSold(Map<String, dynamic> data) {
    final bool isSoldFlag = data['is_sold'] == true;
    final String status = data['status']?.toString().toLowerCase() ?? '';
    return isSoldFlag || status == 'sold';
  }

  Stream<List<Map<String, dynamic>>> get marketListingsStream => _supabase
      .from('market_listings')
      .stream(primaryKey: ['id'])
      .order('updated_at', ascending: false);
}
