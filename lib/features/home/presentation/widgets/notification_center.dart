import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import '../../../../core/services/notification_service.dart';

class NotificationCenter extends StatefulWidget {
  const NotificationCenter({super.key});

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _replyController = TextEditingController();

  List<Map<String, dynamic>> _testNotifications = [];
  List<Map<String, dynamic>> _adminMessages = [];
  bool _isLoading = true;
  bool _showReplyField = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _notificationService.fetchNotifications();
      final messages = await _notificationService.fetchAdminMessages();

      // Mark admin messages as read when viewing (clears indicator)
      await _notificationService.markMessagesAsRead();

      if (mounted) {
        setState(() {
          _testNotifications = notifications;
          _adminMessages = messages;
          _isLoading = false;
          // Show reply field by default if there are messages
          _showReplyField = messages.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    try {
      await _notificationService.sendReply(content);
      _replyController.clear();
      if (mounted) {
        setState(() {
          _showReplyField = false;
        });
        _loadNotifications(); // Refresh
      }
    } catch (e) {
      // Handle error
    }
  }

  String _getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      // Less than 10 seconds
      if (diff.inSeconds < 10) return 'Just now';

      // Less than 1 minute
      if (diff.inSeconds < 60) return '${diff.inSeconds} sec ago';

      // Less than 60 minutes
      if (diff.inMinutes < 60) {
        return diff.inMinutes == 1 ? '1 min ago' : '${diff.inMinutes} mins ago';
      }

      // Less than 24 hours
      if (diff.inHours < 24) {
        return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
      }

      // Days
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';

      // Older than a week - show date
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppPallete.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: AppPallete.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await _notificationService.markAllAsRead();
                    _loadNotifications();
                  },
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(color: AppPallete.primary, fontSize: 14),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppPallete.primary),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tests Section
                        _buildSection(
                          title: 'Tests',
                          icon: Icons.quiz_rounded,
                          iconColor: AppPallete.primary,
                          count: _testNotifications
                              .where((n) => n['is_read'] == false)
                              .length,
                          onClear: () async {
                            await _notificationService.clearNotifications(
                              'test',
                            );
                            _loadNotifications();
                          },
                          child: _buildTestNotifications(),
                        ),

                        const SizedBox(height: 24),

                        // Admin Messages Section
                        _buildSection(
                          title: 'Admin Messages',
                          icon: Icons.admin_panel_settings_rounded,
                          iconColor: AppPallete.secondary,
                          count: _adminMessages
                              .where(
                                (m) =>
                                    m['is_read'] == false &&
                                    m['is_from_admin'] == true,
                              )
                              .length,
                          onClear: () async {
                            await _notificationService.clearAdminMessages();
                            _loadNotifications();
                          },
                          child: _buildAdminMessages(),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required int count,
    required Widget child,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppPallete.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (count > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            TextButton(
              onPressed: onClear,
              child: const Text(
                'Clear all',
                style: TextStyle(color: AppPallete.primary, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildTestNotifications() {
    if (_testNotifications.isEmpty) {
      return _emptyState('No test notifications');
    }

    return GlassContainer(
      padding: const EdgeInsets.all(0),
      borderRadius: BorderRadius.circular(20),
      blur: 15,
      opacity: 0.08,
      color: Colors.white,
      child: Column(
        children: _testNotifications.asMap().entries.map((entry) {
          final index = entry.key;
          final notification = entry.value;
          final isLast = index == _testNotifications.length - 1;

          return Column(
            children: [
              _NotificationTile(
                title: notification['title'] ?? '',
                body: notification['message'] ?? notification['body'] ?? '',
                timeAgo: _getTimeAgo(notification['created_at']),
                isRead: notification['is_read'] ?? false,
                icon: Icons.assignment_rounded,
                iconColor: AppPallete.primary,
                onTap: () {
                  setState(() {
                    notification['is_read'] = true;
                  });
                },
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                  indent: 60,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdminMessages() {
    if (_adminMessages.isEmpty) {
      return _emptyState('No messages from admin');
    }

    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(20),
          blur: 15,
          opacity: 0.08,
          color: Colors.white,
          child: Column(
            children: [
              // Messages list
              ..._adminMessages.map((message) {
                final isFromAdmin = message['is_from_admin'] ?? true;
                return _MessageBubble(
                  content: message['content'] ?? '',
                  timeAgo: _getTimeAgo(message['created_at']),
                  isFromAdmin: isFromAdmin,
                  isRead: message['is_read'] ?? false,
                );
              }),

              const SizedBox(height: 12),

              // Reply section
              if (_showReplyField) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppPallete.surface,
                        AppPallete.surface.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppPallete.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppPallete.primary.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          maxLength: 500,
                          style: const TextStyle(
                            color: AppPallete.textPrimary,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type your reply...',
                            hintStyle: TextStyle(
                              color: AppPallete.textSecondary.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            counterText: '', // Hide the counter
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (_) => _sendReply(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendReply,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppPallete.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppPallete.primary.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.2),
              ] else ...[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showReplyField = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppPallete.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppPallete.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.reply_rounded,
                          color: AppPallete.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Reply to Admin',
                          style: TextStyle(
                            color: AppPallete.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPallete.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppPallete.textSecondary, fontSize: 14),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String body;
  final String timeAgo;
  final bool isRead;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.isRead,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: AppPallete.textPrimary,
                            fontSize: 15,
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      color: AppPallete.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: AppPallete.textSecondary.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final String timeAgo;
  final bool isFromAdmin;
  final bool isRead;

  const _MessageBubble({
    required this.content,
    required this.timeAgo,
    required this.isFromAdmin,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromAdmin
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isFromAdmin) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppPallete.secondary.withValues(alpha: 0.2),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppPallete.secondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromAdmin
                    ? AppPallete.surface
                    : AppPallete.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isFromAdmin ? 4 : 18),
                  bottomRight: Radius.circular(isFromAdmin ? 18 : 4),
                ),
                border: !isRead && isFromAdmin
                    ? Border.all(
                        color: AppPallete.secondary.withValues(alpha: 0.5),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: const TextStyle(
                      color: AppPallete.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: const TextStyle(
                      color: AppPallete.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isFromAdmin) ...[
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppPallete.primary.withValues(alpha: 0.2),
              child: const Icon(
                Icons.person_rounded,
                color: AppPallete.primary,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Show the notification center as a bottom sheet
Future<void> showNotificationCenter(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const NotificationCenter(),
  );
}
