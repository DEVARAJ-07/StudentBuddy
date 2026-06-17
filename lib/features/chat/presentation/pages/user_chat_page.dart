import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/services/chat_service.dart';

class UserChatPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserChatPage({super.key, required this.user});

  @override
  State<UserChatPage> createState() => _UserChatPageState();
}

class _UserChatPageState extends State<UserChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _hasText = false;
  RealtimeChannel? _realtimeChannel;

  String get otherUserId => widget.user['id'] as String? ?? '';
  String get otherUserName => widget.user['full_name'] as String? ?? 'User';
  String? get avatarUrl => widget.user['avatar_url'] as String?;
  String get gender => widget.user['gender'] as String? ?? 'male';

  String get defaultAvatar => gender == 'female'
      ? 'assets/images/default_female_avatar.jpg'
      : 'assets/images/default_male_avatar.jpg';

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() => _hasText = _messageController.text.trim().isNotEmpty);
    });
    _loadMessages();
    _setupRealtimeListener();

    // Mark messages as read immediately when entering the chat
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    if (otherUserId.isNotEmpty) {
      await _chatService.markAsRead(otherUserId);
    }
  }

  void _setupRealtimeListener() {
    final currentUserId = _chatService.currentUserId;
    if (currentUserId == null) return;

    _realtimeChannel = Supabase.instance.client
        .channel('chat_${currentUserId}_$otherUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'user_chats',
          callback: (payload) {
            final newMessage = payload.newRecord;
            // Only add if it's for this conversation
            final senderId = newMessage['sender_id'];
            final receiverId = newMessage['receiver_id'];
            if ((senderId == otherUserId && receiverId == currentUserId) ||
                (senderId == currentUserId && receiverId == otherUserId)) {
              if (mounted) {
                // Check if message already exists
                final exists = _messages.any(
                  (m) => m['id'] == newMessage['id'],
                );
                if (!exists) {
                  setState(() {
                    _messages.add(newMessage);
                  });
                  _scrollToBottom();

                  // Auto mark as read if it's from the other user
                  if (senderId == otherUserId) {
                    _chatService.markAsRead(otherUserId);
                  }
                }
              }
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final messages = await _chatService.getMessages(otherUserId);
    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    HapticFeedback.lightImpact();

    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'sender_id': _chatService.currentUserId,
      'receiver_id': otherUserId,
      'content': content,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    _scrollToBottom();
    await _chatService.sendMessage(otherUserId, content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessagesList()),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E14),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppPallete.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppPallete.textPrimary,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Profile image
          _buildProfileAvatar(44),

          const SizedBox(width: 12),

          // Name only
          Expanded(
            child: Text(
              otherUserName,
              style: GoogleFonts.poppins(
                color: AppPallete.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildProfileAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppPallete.primary.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: ClipOval(
        child:
            avatarUrl != null &&
                avatarUrl!.isNotEmpty &&
                avatarUrl!.startsWith('http')
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Image.asset(defaultAvatar, fit: BoxFit.cover),
              )
            : Image.asset(defaultAvatar, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppPallete.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppPallete.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppPallete.textSecondary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: GoogleFonts.poppins(
                color: AppPallete.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Say hello to $otherUserName',
              style: GoogleFonts.inter(
                color: AppPallete.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message['sender_id'] == _chatService.currentUserId;
        final showAvatar =
            !isMe &&
            (index == 0 ||
                _messages[index - 1]['sender_id'] != message['sender_id']);
        return _MessageBubble(
          content: message['content'] ?? '',
          isMe: isMe,
          showAvatar: showAvatar,
          avatarWidget: _buildProfileAvatar(32),
        ).animate(delay: (index * 20).ms).fadeIn();
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 16,
      ),
      color: const Color(0xFF0A0E14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field - simple clean design without box
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              minLines: 1,
              maxLength: 1000,
              style: GoogleFonts.inter(
                color: AppPallete.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: GoogleFonts.inter(
                  color: AppPallete.textSecondary.withValues(alpha: 0.5),
                ),
                counterText: '', // Hide characters counter for cleaner UI
                border: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppPallete.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppPallete.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppPallete.primary.withValues(alpha: 0.5),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 4,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),

          const SizedBox(width: 12),

          // Send button
          GestureDetector(
            onTap: _hasText ? _sendMessage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: _hasText ? AppPallete.primaryGradient : null,
                color: _hasText ? null : AppPallete.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                color: _hasText ? Colors.white : AppPallete.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final bool showAvatar;
  final Widget avatarWidget;

  const _MessageBubble({
    required this.content,
    required this.isMe,
    required this.showAvatar,
    required this.avatarWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        left: isMe ? 50 : 0,
        right: isMe ? 0 : 50,
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                if (showAvatar) avatarWidget else const SizedBox(width: 32),
                const SizedBox(width: 8),
              ],

              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe ? AppPallete.primaryGradient : null,
                    color: isMe ? null : AppPallete.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    content,
                    style: GoogleFonts.inter(
                      color: isMe ? Colors.white : AppPallete.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
