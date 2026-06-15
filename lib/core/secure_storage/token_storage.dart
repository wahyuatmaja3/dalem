import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});

class TokenStorage {
  final FlutterSecureStorage _storage;
  static const String _tokenKey = 'access_token';

  TokenStorage(this._storage);

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readAccessToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
  }
}
