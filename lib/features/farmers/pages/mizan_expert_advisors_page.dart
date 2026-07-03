// filepath: lib/features/farmers/pages/mizan_expert_advisors_page.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/locale_provider.dart';
import 'package:mizan_web/core/l10n/l10n.dart';
import '../services/mizan_audio_service.dart';

class MizanExpertAdvisorsPage extends StatefulWidget {
  const MizanExpertAdvisorsPage({super.key});

  @override
  State<MizanExpertAdvisorsPage> createState() =>
      _MizanExpertAdvisorsPageState();
}

class _MizanExpertAdvisorsPageState extends State<MizanExpertAdvisorsPage> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<MessageBubbleData> _chatHistory = [];
  final MizanAudioService _audioService = MizanAudioService();
  final SpeechToText _speechToText = SpeechToText();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  Uint8List? _webImageBytes;

  final Map<String, Map<String, String>> _uiLabels = {
    'am': {
      'title': 'የሚዛን ግብርና ባለሙያ',
      'hint': 'ባለሙያውን ይጠይቁ...',
      'speaking': 'ሚዛን ባለሙያ በመናገር ላይ ነው...',
      'error': 'የግንኙነት ስህተት',
      'call': 'ሚዛንን ይደውሉ',
    },
    'en': {
      'title': 'MIZAN AI EXPERT',
      'hint': 'Ask the expert a question...',
      'speaking': 'Mizan Expert is speaking...',
      'error': 'Connection Error',
      'call': 'CALL MIZAN',
    },
    // Add other languages here as needed
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _audioService.onStart = () => setState(() => _isSpeaking = true);
    _audioService.onComplete = () => setState(() => _isSpeaking = false);
  }

  void _initSpeech() async => await _speechToText.initialize();

  void _listen(String langCode) async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          localeId: _getLocale(langCode),
          onResult: (val) =>
              setState(() => _questionController.text = val.recognizedWords),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  String _getLocale(String code) {
    Map<String, String> locales = {
      'am': 'am_ET',
      'ti': 'ti_ET',
      'om': 'om_ET',
      'so': 'so_ET',
    };
    return locales[code] ?? 'en_US';
  }

  Future<void> _handleUserMessage() async {
    final text = _questionController.text.trim();
    if (text.isEmpty && _webImageBytes == null) return;

    final lp = Provider.of<LocaleProvider>(context, listen: false);
    final String currentLangCode = lp.locale.languageCode;
    final String langName = L10n.getLanguageName(currentLangCode);

    String? base64String;
    if (_webImageBytes != null) base64String = base64Encode(_webImageBytes!);

    setState(() {
      _chatHistory.add(
        MessageBubbleData(text: text, isUser: true, imageBytes: _webImageBytes),
      );
      _isLoading = true;
      _isListening = false;
    });

    _webImageBytes = null;
    _questionController.clear();
    _scrollToBottom();

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'ask-mizan-ai',
        body: {
          'question': text,
          'imageBase64': base64String ?? "",
          'language': currentLangCode,
          'forced_language': langName,
        },
      );

      final String aiAnswer = response.data['answer'] ?? "Error";

      setState(() {
        _chatHistory.add(MessageBubbleData(text: aiAnswer, isUser: false));
        _isLoading = false;
      });

      _scrollToBottom();
      _audioService.speak(aiAnswer, currentLangCode);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _chatHistory.add(
          MessageBubbleData(
            text: _uiLabels[currentLangCode]?['error'] ?? "Connection Error",
            isUser: false,
          ),
        );
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LocaleProvider>(context);
    final langCode = lp.locale.languageCode;
    final labels = _uiLabels[langCode] ?? _uiLabels['en']!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          labels['title']!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.g_translate, color: Colors.white),
            onSelected: (Locale loc) => lp.setLocale(loc),
            itemBuilder: (ctx) => L10n.all
                .map(
                  (loc) => PopupMenuItem(
                    value: loc,
                    child: Text(
                      "${L10n.getFlag(loc.languageCode)} ${L10n.getLanguageName(loc.languageCode)}",
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSpeaking) _buildSpeakingIndicator(labels),
          Expanded(
            child: _chatHistory.isEmpty
                ? _buildWelcomeState(labels)
                : _buildChatList(labels),
          ),
          if (_isLoading) const LinearProgressIndicator(color: Colors.orange),
          _buildInputBar(labels, langCode),
        ],
      ),
    );
  }

  Widget _buildChatList(Map<String, String> labels) {
    final lp = Provider.of<LocaleProvider>(context, listen: false);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: _chatHistory.length,
      itemBuilder: (ctx, i) => MessageBubble(
        data: _chatHistory[i],
        callLabel: labels['call'] ?? "CALL",
        onPlay: () =>
            _audioService.speak(_chatHistory[i].text, lp.locale.languageCode),
      ),
    );
  }

  Widget _buildWelcomeState(Map<String, String> labels) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.support_agent,
              size: 100,
              color: Color(0xFF1B5E20),
            ),
            const SizedBox(height: 20),
            Text(
              labels['title']!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "How are your livestock doing today? Tell me your location so I can give you the best Mizan advice.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(Map<String, String> labels, String langCode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.camera_alt_rounded,
              color: Color(0xFF1B5E20),
            ),
            onPressed: _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: labels['hint'],
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: _isListening
                ? Colors.red
                : const Color(0xFF1B5E20),
            child: IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.send,
                color: Colors.white,
              ),
              onPressed: _handleUserMessage,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setState(() => _webImageBytes = bytes);
    }
  }

  Widget _buildSpeakingIndicator(Map<String, String> labels) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.volume_up, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Text(
            labels['speaking']!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.stop_circle, color: Colors.red),
            onPressed: () => _audioService.stop(),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final MessageBubbleData data;
  final VoidCallback onPlay;
  final String callLabel;
  const MessageBubble({
    super.key,
    required this.data,
    required this.onPlay,
    required this.callLabel,
  });

  // Function to launch phone
  Future<void> _makeCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = data.isUser;

    // Check if AI text contains Mizan phone numbers
    bool containsMizanPhone =
        data.text.contains('0935707075') || data.text.contains('0936262387');

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: EdgeInsets.only(
              top: 4,
              bottom: 4,
              left: isUser ? 50 : 0,
              right: isUser ? 0 : 50,
            ),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF1B5E20) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.imageBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(data.imageBytes!, width: 250),
                    ),
                  ),
                Text(
                  data.text,
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),

                // Show call button if phone numbers are present
                if (!isUser && containsMizanPhone)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () =>
                          _makeCall('0935707075'), // Default to main line
                      icon: const Icon(Icons.phone, size: 16),
                      label: Text(callLabel),
                    ),
                  ),
              ],
            ),
          ),
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: IconButton(
                icon: const Icon(
                  Icons.volume_up_rounded,
                  size: 20,
                  color: Color(0xFF1B5E20),
                ),
                onPressed: onPlay,
              ),
            ),
        ],
      ),
    );
  }
}

class MessageBubbleData {
  final String text;
  final bool isUser;
  final Uint8List? imageBytes;
  MessageBubbleData({
    required this.text,
    required this.isUser,
    this.imageBytes,
  });
}
