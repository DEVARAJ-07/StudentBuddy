import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service for managing notifications and admin messages
class NotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  // ==================== NOTIFICATIONS ====================

  /// Fetch all unread notifications with sender profile
  Future<List<Map<String, dynamic>>> fetchNotifications({
    bool unreadOnly = false,
  }) async {
    if (_userId == null) return [];

    try {
      var query = _client
          .from('notifications')
          .select('*, sender:profiles!sender_id(full_name, avatar_url)')
          .eq('user_id', _userId!);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    if (_userId == null) return 0;

    try {
      // Get unread from notifications table
      final notifResponse = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', _userId!)
          .eq('is_read', false);

      // Get unread from admin_messages table (messages from admin to user)
      final adminMsgResponse = await _client
          .from('admin_messages')
          .select('id')
          .eq('user_id', _userId!)
          .eq('is_from_admin', true)
          .eq('is_read', false);

      return (notifResponse as List).length + (adminMsgResponse as List).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Get unread message count from user chats
  Future<int> getUnreadMessageCount() async {
    if (_userId == null) return 0;

    try {
      final response = await _client
          .from('user_chats')
          .select('id')
          .eq('receiver_id', _userId!)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting unread message count: $e');
      return 0;
    }
  }

  /// Mark notification as read and optionally store a reply
  Future<void> markAsRead(String notificationId, {String? reply}) async {
    try {
      final Map<String, dynamic> data = {'is_read': true};
      if (reply != null) {
        data['reply_content'] = reply;
      }

      await _client.from('notifications').update(data).eq('id', notificationId);
    } catch (e) {
      debugPrint('Error updating notification: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _userId!)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  /// Delete all notifications for a specific type
  Future<void> clearNotifications(String type) async {
    if (_userId == null) return;

    try {
      await _client
          .from('notifications')
          .delete()
          .eq('user_id', _userId!)
          .eq('type', type);
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  /// Get notifications grouped by type
  Future<Map<String, List<Map<String, dynamic>>>>
  getGroupedNotifications() async {
    final notifications = await fetchNotifications();

    final Map<String, List<Map<String, dynamic>>> grouped = {
      'test': [],
      'admin_message': [],
      'system': [],
    };

    for (final notification in notifications) {
      final type = notification['type'] as String? ?? 'system';
      grouped[type]?.add(notification);
    }

    return grouped;
  }

  // ==================== ADMIN MESSAGES ====================

  /// Fetch admin messages (conversations)
  Future<List<Map<String, dynamic>>> fetchAdminMessages() async {
    if (_userId == null) return [];

    try {
      final response = await _client
          .from('admin_messages')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching admin messages: $e');
      return [];
    }
  }

  /// Send reply to admin
  Future<void> sendReply(String content, {String? parentId}) async {
    if (_userId == null) return;

    try {
      await _client.from('admin_messages').insert({
        'user_id': _userId,
        'content': content,
        'is_from_admin': false,
        'parent_id': parentId,
      });
    } catch (e) {
      debugPrint('Error sending reply: $e');
    }
  }

  /// Mark admin messages as read
  Future<void> markMessagesAsRead() async {
    if (_userId == null) return;

    try {
      await _client
          .from('admin_messages')
          .update({'is_read': true})
          .eq('user_id', _userId!)
          .eq('is_from_admin', true)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Clear all admin messages for the user
  Future<void> clearAdminMessages() async {
    if (_userId == null) return;

    try {
      await _client.from('admin_messages').delete().eq('user_id', _userId!);
    } catch (e) {
      debugPrint('Error clearing admin messages: $e');
    }
  }
}
