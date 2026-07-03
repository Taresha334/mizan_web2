import 'package:supabase_flutter/supabase_flutter.dart';

class AIService {
  final _supabase = Supabase.instance.client;

  /// Communicates with the 'ask-mizan-ai' Edge Function
  Future<String> getGeminiAdvice(String question) async {
    try {
      // We call the function by the name we deployed: 'ask-mizan-ai'
      final response = await _supabase.functions.invoke(
        'ask-mizan-ai',
        body: {'question': question},
      );

      // Status 200 means the cloud function and Gemini both succeeded
      if (response.status == 200 && response.data != null) {
        return response.data['answer'] ??
            "I'm sorry, I couldn't generate an answer.";
      } else {
        return "Mizan AI is currently over-capacity. Please try again in a moment.";
      }
    } on FunctionException catch (fe) {
      // Corrected: FunctionException uses 'reasonPhrase' or 'status'
      // You can also use fe.details for more technical info
      final errorInfo = fe.reasonPhrase ?? "Status: ${fe.status}";
      return "AI Service Error: $errorInfo";
    } catch (e) {
      // Handles network or other unexpected errors
      return "Connection error. Please check your internet.";
    }
  }
}
