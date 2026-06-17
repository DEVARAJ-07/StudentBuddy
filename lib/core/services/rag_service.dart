import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env_config.dart';

class RagService {
  final SupabaseClient _supabase;
  final String _baseUrl = 'https://openrouter.ai/api/v1/embeddings';
  final String _apiKey = EnvConfig.openRouterKey;

  RagService(this._supabase);

  // 1. Get Embedding from OpenRouter (Gemini Free)
  Future<List<double>> getEmbedding(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'google/gemini-embedding-exp-03-07:free',
          'input': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embeddingList = List<double>.from(data['data'][0]['embedding']);
        return embeddingList;
      } else {
        throw Exception(
          'Failed to generate embedding: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Embedding Error: $e');
    }
  }

  // 2. Store Document with Embedding
  Future<void> addDocument(String filename, String content) async {
    final embedding = await getEmbedding(content);

    await _supabase.from('documents').insert({
      'user_id': _supabase.auth.currentUser!.id,
      'filename': filename,
      'content': content,
      'embedding': embedding,
    });
  }

  // 3. Retrieve Context
  Future<String?> retrieveContext(String query) async {
    try {
      final queryEmbedding = await getEmbedding(query);

      final response = await _supabase.rpc(
        'match_documents',
        params: {
          'query_embedding': queryEmbedding,
          'match_threshold': 0.5, // Similarity threshold (0 to 1)
          'match_count': 3, // Number of chunks to retrieve
        },
      );

      if (response is List && response.isNotEmpty) {
        // Combine retrieved contents
        final buffer = StringBuffer();
        buffer.writeln("Here is some context from the user's files:");
        for (var doc in response) {
          buffer.writeln("- ${doc['content']}");
        }
        return buffer.toString();
      }
      return null;
    } catch (e) {
      // If RAG fails, just return null so chat continues normally
      // debugPrint("RAG Search Error: $e");
      return null;
    }
  }
}
