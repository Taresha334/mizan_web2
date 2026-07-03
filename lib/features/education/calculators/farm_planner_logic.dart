import 'package:supabase_flutter/supabase_flutter.dart';

class FarmPlannerService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, double>> getCalculation(String type, int headCount) async {
    try {
      // Fetch the constants from the new SQL table
      final data = await _supabase
          .from('planner_constants')
          .select()
          .eq('animal_type', type)
          .single();

      return {
        'space': (data['space_per_head'] as double) * headCount,
        'water': (data['water_per_head'] as double) * headCount,
        'feed': (data['feed_per_head_weekly'] as double) * headCount,
      };
    } catch (e) {
      // Fallback defaults if database fails
      return {
        'space': headCount * 0.15,
        'water': headCount * 0.25,
        'feed': headCount * 0.8,
      };
    }
  }
}
