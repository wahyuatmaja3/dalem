import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dalem/core/secure_storage/token_storage.dart';

void main() {
  group('TokenStorage (Offline & Preferences)', () {
    late TokenStorage tokenStorage;
    late FlutterSecureStorage mockStorage;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      mockStorage = const FlutterSecureStorage();
      tokenStorage = TokenStorage(mockStorage);
    });

    test('saveThemeMode and readThemeMode stores and retrieves theme', () async {
      await tokenStorage.saveThemeMode('dark');
      expect(await tokenStorage.readThemeMode(), 'dark');
    });

    test('readThemeMode returns null when unset', () async {
      expect(await tokenStorage.readThemeMode(), null);
    });

    test('saveOfflineModel and readOfflineModel works', () async {
      await tokenStorage.saveOfflineModel('base');
      expect(await tokenStorage.readOfflineModel(), 'base');
    });

    test('clear removes all stored preferences', () async {
      await tokenStorage.saveThemeMode('light');
      await tokenStorage.saveOfflineModel('tiny');
      await tokenStorage.clear();
      expect(await tokenStorage.readThemeMode(), null);
      expect(await tokenStorage.readOfflineModel(), null);
    });
  });
}
