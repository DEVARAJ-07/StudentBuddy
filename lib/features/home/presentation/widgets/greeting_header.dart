import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../chat/presentation/pages/users_list_page.dart';

class GreetingHeader extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMessageRefresh;
  final int notificationCount;
  final int messageCount;

  const GreetingHeader({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.onNotificationTap,
    this.onMessageRefresh,
    this.notificationCount = 0,
    this.messageCount = 0,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Avatar with glow effect
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppPallete.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppPallete.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppPallete.surface,
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      color: AppPallete.primary,
                      size: 28,
                    )
                  : null,
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),

          const SizedBox(width: 14),

          // Greeting text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_getGreeting()} ${_getGreetingEmoji()}',
                      style: const TextStyle(
                        color: AppPallete.textSecondary,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1),
                const SizedBox(height: 4),
                Text(
                      userName,
                      style: const TextStyle(
                        color: AppPallete.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms)
                    .slideX(begin: -0.1),
              ],
            ),
          ),

          // Community/Users button with message badge
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsersListPage()),
              );
              // Refresh counts after returning from chat list
              onMessageRefresh?.call();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppPallete.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Stack(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.people_rounded,
                      color: AppPallete.textSecondary,
                      size: 26,
                    ),
                  ),
                  // Message badge - glow only, no count
                  if (messageCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child:
                          Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  gradient: AppPallete.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppPallete.primary.withValues(
                                        alpha: 0.6,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.3, 1.3),
                                duration: 800.ms,
                              ),
                    ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 150.ms).scale(),

          // Notification button with badge
          GestureDetector(
            onTap: onNotificationTap,
            child: Container(
              decoration: BoxDecoration(
                color: AppPallete.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Stack(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.notifications_rounded,
                      color: AppPallete.textSecondary,
                      size: 26,
                    ),
                  ),
                  // Notification badge - glow only, no count
                  if (notificationCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child:
                          Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.3, 1.3),
                                duration: 800.ms,
                              ),
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).scale(),
          ),
        ],
      ),
    );
  }
}
