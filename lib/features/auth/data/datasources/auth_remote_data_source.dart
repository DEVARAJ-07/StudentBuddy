import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as g_sign;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/secrets/app_secrets.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> signInWithGoogle();
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String gender,
    required String dob,
  });
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<String?> getUserRole(String userId);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl(this.supabaseClient);
  
  static bool _googleInitialized = false;

  /// Ensures GoogleSignIn.instance is initialized exactly once (v7+ pattern)
  Future<void> _ensureGoogleInitialized() async {
    if (!_googleInitialized) {
      await g_sign.GoogleSignIn.instance.initialize(
        serverClientId: AppSecrets.googleWebClientId,
      );
      _googleInitialized = true;
    }
  }

  @override
  Future<AuthResponse> signInWithGoogle() async {
    // 1. Ensure v7 instance is initialized with our secrets
    await _ensureGoogleInitialized();

    final g_sign.GoogleSignInAccount account;
    try {
      // In v7.2.0+, use authenticate() for interactive sign-in
      account = await g_sign.GoogleSignIn.instance.authenticate();
    } catch (e) {
      throw AuthException('Google Sign In failed: $e');
    }

    // 2. Extract authentication tokens (already available as a getter in v7)
    final googleAuth = account.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw const AuthException(
        'Could not retrieve Google ID token. Please try again.',
      );
    }

    debugPrint('Google Sign-In: Got ID token, exchanging with Supabase...');

    // 3. Exchange correctly matching token with Supabase for a session
    final response = await supabaseClient.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );

    debugPrint(
        'Google Sign-In: Supabase auth successful! User: ${response.user?.id}');

    // 4. Force rigorous syncing exactly matching Google profile data
    if (response.user != null) {
      await _ensureProfileExists(response.user!, googleAccount: account);
    }

    return response;
  }

  /// Ensures profile and user_progress rows exist for this Google user
  Future<void> _ensureProfileExists(User user, {g_sign.GoogleSignInAccount? googleAccount}) async {
    try {
      final meta = user.userMetadata ?? {};
      // Prioritize direct Google Account info over Supabase meta which might be empty on pure ID token auth
      final fullName = googleAccount?.displayName ?? meta['full_name'] ?? meta['name'] ?? 'Google User';
      final avatarUrl = googleAccount?.photoUrl ?? meta['avatar_url'] ?? meta['picture'] ?? meta['photo_url'] ?? 'assets/images/default_male_avatar.jpg';
      final email = googleAccount?.email ?? user.email ?? meta['email'] ?? '';
      
      debugPrint('Google Sign-In Sync: Name="$fullName", Email="$email"');

      final existing = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        // Completely new user or trigger failed
        final genId = 'SB-${DateTime.now().year % 100}-${DateTime.now().millisecond.toString().padLeft(3, '0')}';
        
        await supabaseClient.from('profiles').insert({
          'id': user.id,
          'full_name': fullName,
          'email': email,
          'avatar_url': avatarUrl,
          'role': 'user',
          'gender': 'male',
          'date_of_birth': '2000-01-01',
          'student_id': genId,
        });
        debugPrint('Google Sign-In: Created new profile with ID $genId');
      } else {
        // Profile exists (maybe created by a trigger blankly, or they are logging in again)
        final currentName = existing['full_name']?.toString() ?? '';
        final currentEmail = existing['email']?.toString() ?? '';
        final currentAvatar = existing['avatar_url']?.toString() ?? '';
        
        // This targets ANY generic placeholder the DB trigger might have slapped on the user previously!
        final isPlaceholderName = currentName.trim().isEmpty || 
            ['user', 'student', 'google user', 'null', 'unnamed', 'unknown'].contains(currentName.trim().toLowerCase());
        
        debugPrint('Google Sign-In: Current name is "$currentName". Is placeholder: $isPlaceholderName');
        debugPrint('Google Sign-In: Google display name discovered: "${googleAccount?.displayName}"');
        
        final isPlaceholderAvatar = currentAvatar.trim().isEmpty || 
            currentAvatar.contains('default_');
            
        if (isPlaceholderName || isPlaceholderAvatar || currentEmail.isEmpty) {
          debugPrint('Google Sign-In: Updating profile with real Google data...');
          await supabaseClient.from('profiles').update({
            if (isPlaceholderName) 'full_name': fullName,
            if (isPlaceholderAvatar) 'avatar_url': avatarUrl,
            if (currentEmail.isEmpty) 'email': email,
          }).eq('id', user.id);
          debugPrint('Google Sign-In: Profile update call completed.');
        }
      }
      
      debugPrint('Google Sign-In: Profile synced for $fullName');

      // Ensure user_progress exists
      final progress = await supabaseClient
          .from('user_progress')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (progress == null) {
        await supabaseClient.from('user_progress').insert({
          'user_id': user.id,
          'streak_count': 0,
          'study_hours': 0,
          'tests_completed': 0,
          'total_marks': 0,
          'avg_percentage': 0,
        });
        debugPrint('Google Sign-In: Created user_progress for $fullName');
      }
    } catch (e) {
      debugPrint('Google Sign-In: Profile check/creation error: $e');
      // Non-fatal — user is still signed in
    }
  }

  @override
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String gender,
    required String dob,
  }) async {
    final defaultAvatar = gender == 'female'
        ? 'assets/images/default_female_avatar.jpg'
        : 'assets/images/default_male_avatar.jpg';

    return await supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': name,
        'gender': gender,
        'avatar_url': defaultAvatar,
        'date_of_birth': dob,
      },
    );
  }

  @override
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<String?> getUserRole(String userId) async {
    try {
      final data = await supabaseClient
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      return data['role'] as String?;
    } catch (e) {
      return null;
    }
  }
}
