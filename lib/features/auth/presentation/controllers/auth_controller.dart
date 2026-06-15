import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../../../core/secure_storage/token_storage.dart';

class AuthState {
  final bool isInitial;
  final bool isSubmitting;
  final bool isAuthenticated;
  final String? errorMessage;
  final UserModel? user;

  const AuthState({
    this.isInitial = false,
    this.isSubmitting = false,
    this.isAuthenticated = false,
    this.errorMessage,
    this.user,
  });

  factory AuthState.initial() => const AuthState(isInitial: true);
  factory AuthState.submitting() => const AuthState(isSubmitting: true);
  factory AuthState.authenticated(UserModel user) =>
      AuthState(isAuthenticated: true, user: user);
  factory AuthState.error(String message) =>
      AuthState(isInitial: true, errorMessage: message);
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository repository;
  final TokenStorage tokenStorage;

  AuthController({
    required this.repository,
    required this.tokenStorage,
  }) : super(AuthState.initial());

  Future<void> login(String email, String password) async {
    state = AuthState.submitting();
    try {
      final session = await repository.signIn(email, password);
      await tokenStorage.saveAccessToken(session.accessToken);
      state = AuthState.authenticated(session.user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = AuthState.submitting();
    try {
      final session = await repository.register(name, email, password);
      await tokenStorage.saveAccessToken(session.accessToken);
      state = AuthState.authenticated(session.user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    await repository.signOut();
    await tokenStorage.clear();
    state = AuthState.initial();
  }
}
