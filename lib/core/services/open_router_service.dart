import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// LM Studio Service - Connects to local LM Studio server
/// Using meta-llama-3.1-8b-instruct model for fast offline responses
class OpenRouterService {
  final String _systemInstruction;

  // Cache for the AI URL to avoid constant fetching
  static String? _cachedBaseUrl;
  static DateTime? _lastFetchTime;

  // Fallback URL (Local Emulator Bridge to PC)
  static const String _defaultUrl =
      'http://10.0.2.2:1234/v1/chat/completions';

  OpenRouterService({String? systemInstruction})
    : _systemInstruction =
          systemInstruction ??
          'You are an expert AI Mentor for StudentBuddy, a student learning platform. '
          'Help students understand academic concepts clearly and concisely. '
          'Use simple language, real-world examples, and step-by-step reasoning. '
          'Keep responses focused, practical, and formatted for a mobile chat interface. '
          'Always be encouraging and supportive in your tone.';

  Future<String> _getBaseUrl() async {
    // Return cached URL if it's less than 5 minutes old
    if (_cachedBaseUrl != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 5) {
      return _cachedBaseUrl!;
    }

    try {
      final response = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', 'ai_mentor_url')
          .maybeSingle();

      if (response != null && response['value'] != null) {
        String url = response['value'].toString();
        // Ensure URL doesn't end with /v1/chat/completions twice
        if (!url.endsWith('/v1/chat/completions')) {
          url = url.endsWith('/')
              ? '${url}v1/chat/completions'
              : '$url/v1/chat/completions';
        }
        _cachedBaseUrl = url;
        _lastFetchTime = DateTime.now();
        debugPrint("AI: Dynamic URL fetched: $_cachedBaseUrl");
        return _cachedBaseUrl!;
      }
    } catch (e) {
      debugPrint("AI: Error fetching dynamic URL: $e");
    }

    debugPrint("AI: Using fallback URL: $_defaultUrl");
    return _defaultUrl;
  }

  Future<String> sendMessage(
    String message, {
    List<Map<String, dynamic>>? history,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final messages = <Map<String, dynamic>>[];

      // 1. Add System Prompt
      messages.add({'role': 'system', 'content': _systemInstruction});

      // 2. Add History (limit to last 8 messages for context)
      if (history != null && history.isNotEmpty) {
        final recentHistory = history.length > 8
            ? history.sublist(history.length - 8)
            : history;
        messages.addAll(recentHistory);
      }

      // 3. Add Current Message
      messages.add({'role': 'user', 'content': message});

      debugPrint("AI: Connecting to: $baseUrl");

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'meta-llama-3.1-8b-instruct',
              'messages': messages,
              'temperature': 0.4,
              'max_tokens': 512,
              'stream': false,
              'top_p': 0.9,
              'frequency_penalty': 0.3,
              'presence_penalty': 0.3,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        debugPrint(
          'AI: Server Error: ${response.statusCode} - ${response.body}',
        );
        throw Exception('AI Server Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('AI: Connection Error: $e');
      throw Exception(
        'Failed to connect to AI Mentor. Check your Ngrok tunnel.',
      );
    }
  }
}
