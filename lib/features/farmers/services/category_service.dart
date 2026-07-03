import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _supabase
          .from('professional_categories')
          .select('ui_label, db_key')
          .eq('is_active', true);
      return response;
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      return [];
    }
  }
}
