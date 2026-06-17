import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;
  String? get currentUserName =>
      _supabase.auth.currentUser?.userMetadata?['full_name'];

  // Get all users except current user with last message preview
  // Only show users with role='user' (no admins/super_admins)
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      List<Map<String, dynamic>> users = [];

      // Try using the RPC function first for basic user data
      final rpcResponse = await _supabase.rpc(
        'get_chat_users',
        params: {'current_user_id': currentUserId},
      );

      if (rpcResponse != null && (rpcResponse as List).isNotEmpty) {
        final filtered = rpcResponse
            .where((u) => u['role'] == 'user' || u['role'] == null)
            .toList();
        users = List<Map<String, dynamic>>.from(filtered);
      } else {
        // Fallback: get basic user profiles
        final usersResponse = await _supabase
            .from('profiles')
            .select('id, full_name, role, avatar_url, gender')
            .eq('role', 'user')
            .neq('id', currentUserId ?? '')
            .order('full_name');

        users = List<Map<String, dynamic>>.from(usersResponse);
      }

      // ALWAYS fetch last message and unread count for each user
      for (var user in users) {
        try {
          // Get last message
          final lastMsgResponse = await _supabase
              .from('user_chats')
              .select('content, created_at, sender_id')
              .or(
                'and(sender_id.eq.$currentUserId,receiver_id.eq.${user['id']}),and(sender_id.eq.${user['id']},receiver_id.eq.$currentUserId)',
              )
              .order('created_at', ascending: false)
              .limit(1);

          if (lastMsgResponse.isNotEmpty) {
            user['last_message'] = lastMsgResponse[0]['content'];
          } else {
            user['last_message'] = null;
          }

          // Get unread count - messages sent TO me FROM this user
          final unreadResponse = await _supabase
              .from('user_chats')
              .select('id')
              .eq('sender_id', user['id'])
              .eq('receiver_id', currentUserId ?? '')
              .eq('is_read', false);

          user['unread_count'] = (unreadResponse as List).length;
          debugPrint(
            'getUsers: User ${user['full_name']} has ${user['unread_count']} unread messages',
          );
        } catch (e) {
          debugPrint('Error fetching chat data for user: $e');
          user['unread_count'] = 0;
          user['last_message'] = null;
        }
      }

      // Sort users: unread first, then by name
      users.sort((a, b) {
        final aUnread = a['unread_count'] as int? ?? 0;
        final bUnread = b['unread_count'] as int? ?? 0;
        if (aUnread > 0 && bUnread == 0) return -1;
        if (aUnread == 0 && bUnread > 0) return 1;
        return (a['full_name'] as String? ?? '').compareTo(
          b['full_name'] as String? ?? '',
        );
      });

      return users;
    } catch (e) {
      debugPrint('Error fetching users: $e');

      // Basic fallback
      try {
        final fallback = await _supabase
            .from('profiles')
            .select('id, full_name, role, avatar_url, gender')
            .eq('role', 'user')
            .neq('id', currentUserId ?? '')
            .order('full_name');
        return List<Map<String, dynamic>>.from(fallback);
      } catch (e2) {
        debugPrint('Fallback error: $e2');
        return [];
      }
    }
  }

  // Get chat messages between two users with real-time updates
  Future<List<Map<String, dynamic>>> getMessages(String otherUserId) async {
    try {
      final response = await _supabase
          .from('user_chats')
          .select('*')
          .or(
            'and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)',
          )
          .order('created_at', ascending: true);

      // Mark received messages as read
      await markAsRead(otherUserId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  // Send a message with notification trigger
  Future<bool> sendMessage(String receiverId, String content) async {
    try {
      final messageData = {
        'sender_id': currentUserId,
        'receiver_id': receiverId,
        'content': content,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('user_chats').insert(messageData);

      // Trigger notification (Supabase edge function or realtime)
      await _triggerNotification(receiverId, content);

      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  // Trigger push notification to receiver
  Future<void> _triggerNotification(String receiverId, String content) async {
    try {
      // This would call a Supabase Edge Function or external service
      // For now, we'll use Supabase realtime which the receiver listens to
      debugPrint('Notification triggered for $receiverId: $content');
    } catch (e) {
      debugPrint('Error triggering notification: $e');
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String senderId) async {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) {
      debugPrint('markAsRead: currentUserId is null or empty');
      return;
    }
    if (senderId.isEmpty) {
      debugPrint('markAsRead: senderId is empty');
      return;
    }

    try {
      debugPrint(
        'markAsRead: Marking messages from $senderId as read for user $userId',
      );

      // First check how many unread messages exist
      final unreadCheck = await _supabase
          .from('user_chats')
          .select('id')
          .eq('sender_id', senderId)
          .eq('receiver_id', userId)
          .eq('is_read', false);

      debugPrint(
        'markAsRead: Found ${(unreadCheck as List).length} unread messages',
      );

      if ((unreadCheck as List).isNotEmpty) {
        // Update all unread messages
        await _supabase
            .from('user_chats')
            .update({'is_read': true})
            .eq('sender_id', senderId)
            .eq('receiver_id', userId)
            .eq('is_read', false);

        debugPrint('markAsRead: Successfully marked messages as read');
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  // Get unread message count for badge
  Future<int> getUnreadCount() async {
    try {
      final response = await _supabase
          .from('user_chats')
          .select('id')
          .eq('receiver_id', currentUserId ?? '')
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Check if user has any unread messages (for glow badge)
  Future<bool> hasUnreadMessages() async {
    final count = await getUnreadCount();
    return count > 0;
  }

  /// Check if a specific user has sent unread messages
  Future<bool> hasUnreadFromUser(String senderId) async {
    try {
      final response = await _supabase
          .from('user_chats')
          .select('id')
          .eq('sender_id', senderId)
          .eq('receiver_id', currentUserId ?? '')
          .eq('is_read', false)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('Error checking unread from user: $e');
      return false;
    }
  }

  // Get unread count by user
  Future<Map<String, int>> getUnreadCountByUser() async {
    try {
      final response = await _supabase
          .from('user_chats')
          .select('sender_id')
          .eq('receiver_id', currentUserId ?? '')
          .eq('is_read', false);

      final counts = <String, int>{};
      for (var msg in response) {
        final senderId = msg['sender_id'] as String;
        counts[senderId] = (counts[senderId] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      debugPrint('Error getting unread by user: $e');
      return {};
    }
  }

  // Subscribe to real-time messages
  RealtimeChannel subscribeToMessages(
    String otherUserId,
    Function(Map<String, dynamic>) onMessage,
  ) {
    return _supabase
        .channel('user_chats_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'user_chats',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: currentUserId ?? '',
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;
            if (newMessage['sender_id'] == otherUserId) {
              onMessage(newMessage);
            }
          },
        )
        .subscribe();
  }

  // Get recent chats (last message with each user)
  Future<List<Map<String, dynamic>>> getRecentChats() async {
    try {
      // Get unique conversations
      final sent = await _supabase
          .from('user_chats')
          .select('receiver_id, content, created_at')
          .eq('sender_id', currentUserId ?? '')
          .order('created_at', ascending: false);

      final received = await _supabase
          .from('user_chats')
          .select('sender_id, content, created_at')
          .eq('receiver_id', currentUserId ?? '')
          .order('created_at', ascending: false);

      // Merge and deduplicate
      final chatMap = <String, Map<String, dynamic>>{};

      for (var msg in sent) {
        final id = msg['receiver_id'];
        if (!chatMap.containsKey(id)) {
          chatMap[id] = msg;
        }
      }

      for (var msg in received) {
        final id = msg['sender_id'];
        if (!chatMap.containsKey(id)) {
          chatMap[id] = msg;
        }
      }

      return chatMap.values.toList();
    } catch (e) {
      debugPrint('Error getting recent chats: $e');
      return [];
    }
  }
}
