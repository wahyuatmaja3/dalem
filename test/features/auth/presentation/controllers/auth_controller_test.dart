import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dalem/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dalem/features/auth/data/repositories/auth_repository.dart';
import 'package:dalem/core/secure_storage/token_storage.dart';

void main() {
  group('AuthController', () {
    late ProviderContainer container;
    late AuthController controller;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      container = ProviderContainer();
      final repository = AuthRepository();
      final tokenStorage = TokenStorage(const FlutterSecureStorage());
      controller = AuthController(
        repository: repository,
        tokenStorage: tokenStorage,
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is AuthState.initial', () {
      expect(controller.state, AuthState.initial());
    });

    test('login transitions through submitting to authenticated', () async {
      expect(controller.state, AuthState.initial());

      final loginFuture = controller.login('test@example.com', 'password123');
      expect(controller.state, AuthState.submitting());

      await loginFuture;
      expect(controller.state.isAuthenticated, true);
    });

    test('register transitions through submitting to authenticated', () async {
      expect(controller.state, AuthState.initial());

      final registerFuture = controller.register(
        'Test User',
        'test@example.com',
        'password123',
      );
      expect(controller.state, AuthState.submitting());

      await registerFuture;
      expect(controller.state.isAuthenticated, true);
    });

    test('logout clears state', () async {
      await controller.login('test@example.com', 'password123');
      expect(controller.state.isAuthenticated, true);

      await controller.logout();
      expect(controller.state, AuthState.initial());
    });
  });
}
