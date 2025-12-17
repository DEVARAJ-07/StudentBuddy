import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<AuthResponse> signInWithGoogle() async {
    return await remoteDataSource.signInWithGoogle();
  }

  @override
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    return await remoteDataSource.signUpWithEmailPassword(
      email: email,
      password: password,
      name: name,
    );
  }

  @override
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await remoteDataSource.signInWithEmailPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<String?> getUserRole(String userId) async {
    return await remoteDataSource.getUserRole(userId);
  }
}
