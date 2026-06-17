import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:student_buddy/core/secrets/app_secrets.dart';

class DeepSeekService {
  final String _baseUrl = 'https://api.deepseek.com/chat/completions';
  final String _apiKey = AppSecrets.deepSeekApiKey;
  final String? systemInstruction;

  DeepSeekService({this.systemInstruction});

  Future<String> sendMessage(
    String message, {
    List<Map<String, String>>? history,
  }) async {
    try {
      final messages = <Map<String, String>>[];

      // Add system instruction if available
      if (systemInstruction != null) {
        messages.add({'role': 'system', 'content': systemInstruction!});
      }

      // Add conversation history
      if (history != null) {
        messages.addAll(history);
      }

      // Add current message
      messages.add({'role': 'user', 'content': message});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': messages,
          'stream': false,
          'temperature': 0.5,
          'max_tokens': 1024,
          'top_p': 0.9,
          'frequency_penalty': 0.3,
          'presence_penalty': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content.toString();
      } else {
        throw Exception(
          'Failed to load response: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to reach AI mentor. Please check your connection and try again.');
    }
  }
}
