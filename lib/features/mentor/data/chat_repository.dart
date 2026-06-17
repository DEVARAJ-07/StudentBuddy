import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_message.dart';

class ChatRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ChatMessage>> getMessages(String mentorId) async {
    final response = await _supabase
        .from('chat_messages')
        .select()
        .eq('mentor_id', mentorId)
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('created_at', ascending: true); // Oldest first for chat UI

    return (response as List).map((e) {
      return ChatMessage(
        role: e['role'] ?? 'user', // Default to user if missing
        content: e['content'],
        timestamp: DateTime.parse(e['created_at']),
      );
    }).toList();
  }

  Future<void> saveMessage({
    required String mentorId,
    required String content,
    required String role,
  }) async {
    await _supabase.from('chat_messages').insert({
      'user_id': _supabase.auth.currentUser!.id,
      'mentor_id': mentorId,
      'content': content,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
