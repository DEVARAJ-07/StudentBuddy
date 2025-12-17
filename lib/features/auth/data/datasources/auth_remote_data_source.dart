import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> signInWithGoogle();
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
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

  @override
  Future<AuthResponse> signInWithGoogle() async {
    final res = await supabaseClient.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'c.s.studentbuddy://login-callback',
    );
    if (!res) {
      throw const AuthException('Google Sign In failed to launch');
    }
    return AuthResponse();
  }

  @override
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    return await supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
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
      return null; // Handle error or return default
    }
  }
}
