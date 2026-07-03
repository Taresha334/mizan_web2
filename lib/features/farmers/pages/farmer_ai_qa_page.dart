import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FarmerAIQAPage extends StatefulWidget {
  const FarmerAIQAPage({super.key});

  @override
  State<FarmerAIQAPage> createState() => _FarmerAIQAPageState();
}

class _FarmerAIQAPageState extends State<FarmerAIQAPage> {
  final _supabase = Supabase.instance.client;
  final _questionController = TextEditingController();
  bool _isLoading = false;
  String? _aiResponse;

  Future<void> _askAI() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isLoading = true;
      _aiResponse = null;
    });

    try {
      // Calling your Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'ask-mizan-ai',
        body: {'question': question},
      );

      setState(() {
        _aiResponse = response.data['answer'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("AI Assistant is sleeping. Try again later.")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mizan AI Expert"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ask anything about your farm",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Example: How much space do I need for 50 layers?",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _questionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Type your question here...",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _askAI,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(_isLoading
                    ? "Expert is thinking..."
                    : "Get Instant Answer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_aiResponse != null) _buildAIResponseCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAIResponseCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text("AI Expert Advice",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const Divider(),
          Text(
            _aiResponse!,
            style: const TextStyle(
                fontSize: 15, height: 1.5, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          const Text(
            "Note: This is an AI recommendation. Always consult a local vet for critical issues.",
            style: TextStyle(
                fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
