import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});

/// Local secure storage for application preferences (Theme, etc.)
/// No external API keys are stored or needed.
class TokenStorage {
  final FlutterSecureStorage _storage;
  static const String _themeModeKey = 'theme_mode';
  static const String _offlineModelKey = 'offline_whisper_model';

  TokenStorage(this._storage);

  Future<void> saveThemeMode(String mode) async {
    await _storage.write(key: _themeModeKey, value: mode);
  }

  Future<String?> readThemeMode() async {
    return await _storage.read(key: _themeModeKey);
  }

  Future<void> saveOfflineModel(String modelName) async {
    await _storage.write(key: _offlineModelKey, value: modelName);
  }

  Future<String?> readOfflineModel() async {
    return await _storage.read(key: _offlineModelKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _themeModeKey);
    await _storage.delete(key: _offlineModelKey);
  }
}
