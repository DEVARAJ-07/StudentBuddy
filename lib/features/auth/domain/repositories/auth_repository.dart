import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
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
