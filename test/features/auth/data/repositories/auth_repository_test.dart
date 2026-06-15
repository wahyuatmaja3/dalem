import 'package:flutter_test/flutter_test.dart';
import 'package:dalem/features/auth/data/repositories/auth_repository.dart';
import 'package:dalem/features/auth/data/models/auth_session_model.dart';

void main() {
  group('AuthRepository', () {
    late AuthRepository repository;

    setUp(() {
      repository = AuthRepository();
    });

    test('signIn returns session with valid credentials', () async {
      final result = await repository.signIn('test@example.com', 'password123');
      
      expect(result, isA<AuthSessionModel>());
      expect(result.user.email, 'test@example.com');
      expect(result.accessToken, isNotEmpty);
    });

    test('register returns session with valid data', () async {
      final result = await repository.register(
        'Test User',
        'newuser@example.com',
        'password123',
      );
      
      expect(result, isA<AuthSessionModel>());
      expect(result.user.name, 'Test User');
      expect(result.user.email, 'newuser@example.com');
      expect(result.accessToken, isNotEmpty);
    });

    test('signOut completes successfully', () async {
      await expectLater(repository.signOut(), completes);
    });
  });
}
