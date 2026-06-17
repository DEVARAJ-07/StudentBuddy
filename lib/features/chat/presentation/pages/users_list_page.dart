import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/services/chat_service.dart';
import 'user_chat_page.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage>
    with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final users = await _chatService.getUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final name = (user['full_name'] as String?)?.toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _openChat(Map<String, dynamic> user) async {
    HapticFeedback.mediumImpact();
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            UserChatPage(user: user),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    // Small delay to ensure markAsRead has completed in the database
    await Future.delayed(const Duration(milliseconds: 100));
    // Refresh users list to update read status
    if (mounted) {
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _filteredUsers.isEmpty
                  ? _buildEmptyState()
                  : _buildUsersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppPallete.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppPallete.textPrimary,
                size: 18,
              ),
            ),
          ).animate().fadeIn().scale(delay: 50.ms),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppPallete.primary, AppPallete.secondary],
                  ).createShader(bounds),
                  child: Text(
                    'Buddies',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Connect with buddies',
                  style: GoogleFonts.inter(
                    color: AppPallete.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: AppPallete.textSecondary.withValues(alpha: 0.6),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: GoogleFonts.inter(
                color: AppPallete.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search buddies...',
                hintStyle: GoogleFonts.inter(
                  color: AppPallete.textSecondary.withValues(alpha: 0.5),
                ),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Icon(
                Icons.close_rounded,
                color: AppPallete.textSecondary,
                size: 18,
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppPallete.primary,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading buddies...',
            style: GoogleFonts.inter(
              color: AppPallete.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppPallete.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isEmpty
                  ? Icons.people_outline_rounded
                  : Icons.search_off_rounded,
              color: AppPallete.textSecondary,
              size: 40,
            ),
          ).animate().scale().fadeIn(),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty ? 'No buddies yet' : 'No results found',
            style: GoogleFonts.poppins(
              color: AppPallete.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 100.ms),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    // Separate unread and read users
    final unreadUsers = _filteredUsers
        .where((u) => (u['unread_count'] as int? ?? 0) > 0)
        .toList();
    final readUsers = _filteredUsers
        .where((u) => (u['unread_count'] as int? ?? 0) == 0)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: AppPallete.primary,
      backgroundColor: AppPallete.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        physics: const BouncingScrollPhysics(),
        children: [
          // New Messages Section
          if (unreadUsers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppPallete.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'New Messages',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(
                        duration: 2000.ms,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                ],
              ),
            ).animate().fadeIn(),
            ...unreadUsers.asMap().entries.map((entry) {
              return _BuddyTile(
                    user: entry.value,
                    onOpen: () => _openChat(entry.value),
                  )
                  .animate(delay: (entry.key * 50).ms)
                  .fadeIn()
                  .slideX(begin: 0.02);
            }),
            const SizedBox(height: 20),
          ],

          // All Chats Section
          if (readUsers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'All Chats',
                style: GoogleFonts.poppins(
                  color: AppPallete.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),
            ...readUsers.asMap().entries.map((entry) {
              return _BuddyTile(
                    user: entry.value,
                    onOpen: () => _openChat(entry.value),
                  )
                  .animate(delay: ((unreadUsers.length + entry.key) * 30).ms)
                  .fadeIn()
                  .slideX(begin: 0.02);
            }),
          ],

          // Show message if no chats at all
          if (unreadUsers.isEmpty && readUsers.isEmpty) _buildEmptyState(),
        ],
      ),
    );
  }
}

class _BuddyTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onOpen;

  const _BuddyTile({required this.user, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final name = user['full_name'] as String? ?? 'Unknown';
    final gender = user['gender'] as String? ?? 'male';
    final avatarUrl = user['avatar_url'] as String?;
    final unreadCount = user['unread_count'] as int? ?? 0;
    final lastMessage = user['last_message'] as String?;
    final hasUnread = unreadCount > 0;

    final defaultAvatar = gender == 'female'
        ? 'assets/images/default_female_avatar.jpg'
        : 'assets/images/default_male_avatar.jpg';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasUnread
                ? AppPallete.primary.withValues(alpha: 0.08)
                : AppPallete.surface,
            borderRadius: BorderRadius.circular(16),
            border: hasUnread
                ? Border.all(
                    color: AppPallete.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  )
                : Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              // Avatar with pulsing glow for unread
              Stack(
                children: [
                  // Glow effect behind avatar
                  if (hasUnread)
                    Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppPallete.primary.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .shimmer(
                          duration: 1500.ms,
                          color: AppPallete.primary.withValues(alpha: 0.3),
                        ),

                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasUnread
                            ? AppPallete.primary
                            : AppPallete.primary.withValues(alpha: 0.3),
                        width: hasUnread ? 2.5 : 2,
                      ),
                    ),
                    child: ClipOval(
                      child:
                          avatarUrl != null &&
                              avatarUrl.isNotEmpty &&
                              avatarUrl.startsWith('http')
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(defaultAvatar, fit: BoxFit.cover),
                            )
                          : Image.asset(defaultAvatar, fit: BoxFit.cover),
                    ),
                  ),

                  // Unread dot indicator
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child:
                          Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  gradient: AppPallete.primaryGradient,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF0A0E14),
                                    width: 2,
                                  ),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.2, 1.2),
                                duration: 800.ms,
                              ),
                    ),
                ],
              ),

              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              color: AppPallete.textPrimary,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppPallete.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount new',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage ?? 'Start a conversation',
                      style: GoogleFonts.inter(
                        color: hasUnread
                            ? AppPallete.textPrimary
                            : AppPallete.textSecondary,
                        fontSize: 12,
                        fontWeight: hasUnread
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Arrow
              Icon(
                Icons.chevron_right_rounded,
                color: hasUnread
                    ? AppPallete.primary.withValues(alpha: 0.8)
                    : AppPallete.textSecondary.withValues(alpha: 0.4),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
