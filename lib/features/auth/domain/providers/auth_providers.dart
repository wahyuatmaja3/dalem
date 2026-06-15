import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../../../core/secure_storage/token_storage.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.read(authRepositoryProvider);
  final tokenStorage = ref.read(tokenStorageProvider);
  return AuthController(
    repository: repository,
    tokenStorage: tokenStorage,
  );
});
