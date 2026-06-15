import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  Future<AuthSessionModel> signIn(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    return AuthSessionModel(
      accessToken: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      user: UserModel(
        id: 'user_1',
        name: 'Mock User',
        email: email,
      ),
    );
  }

  Future<AuthSessionModel> register(
    String name,
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    return AuthSessionModel(
      accessToken: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      user: UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
      ),
    );
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
