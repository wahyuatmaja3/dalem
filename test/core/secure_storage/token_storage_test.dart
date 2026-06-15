import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dalem/core/secure_storage/token_storage.dart';

void main() {
  group('TokenStorage', () {
    late TokenStorage tokenStorage;
    late FlutterSecureStorage mockStorage;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      mockStorage = const FlutterSecureStorage();
      tokenStorage = TokenStorage(mockStorage);
    });

    test('saveAccessToken stores token', () async {
      await tokenStorage.saveAccessToken('test_token');
      final token = await tokenStorage.readAccessToken();
      expect(token, 'test_token');
    });

    test('readAccessToken returns null when no token', () async {
      final token = await tokenStorage.readAccessToken();
      expect(token, null);
    });

    test('clear removes token', () async {
      await tokenStorage.saveAccessToken('test_token');
      await tokenStorage.clear();
      final token = await tokenStorage.readAccessToken();
      expect(token, null);
    });
  });
}
