import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/router.dart';
import 'core/secure_storage/token_storage.dart';
import 'core/services/whatsapp_bridge_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  String initialRoute;
  try {
    final tokenStorage = container.read(tokenStorageProvider);
    final token = await tokenStorage.readAccessToken();
    initialRoute = token != null ? AppRouter.dashboard : AppRouter.signIn;
  } catch (_) {
    initialRoute = AppRouter.signIn;
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: DalemApp(initialRoute: initialRoute),
    ),
  );

  Future.microtask(() {
    container.read(whatsAppBridgeProvider).initialize();
  });
}
