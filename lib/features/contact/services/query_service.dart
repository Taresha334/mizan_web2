import 'package:supabase_flutter/supabase_flutter.dart';

class QueryService {
  static Future<bool> submitToExpert({
    required String name,
    required String phone,
    required String animal,
    required String question,
  }) async {
    try {
      await Supabase.instance.client.from('expert_queries').insert({
        'farmer_name': name,
        'phone_number': phone,
        'animal_type': animal,
        'question': question,
      });
      return true;
    } catch (e) {
      print("Error submitting query: $e");
      return false;
    }
  }
}
