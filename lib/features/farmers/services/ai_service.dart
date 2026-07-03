// filepath: lib/features/farmers/services/ai_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AIService {
  final _supabase = Supabase.instance.client;

  Future<String> getGeminiAdvice({
    required String question,
    String? imageBase64,
    required String languageName,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'ask-mizan-ai',
        body: {
          'question': question,
          'imageBase64': imageBase64 ?? "",
          'language_name': languageName, // e.g., "Tigrigna"
        },
      );

      if (response.status == 200) {
        return response.data['answer'];
      }
      return "Error: AI is currently unavailable.";
    } catch (e) {
      return "Connection failed. Please check your network.";
    }
  }
}
