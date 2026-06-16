import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'app/router.dart';
import 'core/secure_storage/token_storage.dart';
import 'core/services/whatsapp_bridge_service.dart';
import 'features/dashboard/data/repositories/notes_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  final notesBox = await Hive.openBox('notes');
  final categoriesBox = await Hive.openBox('categories');

  final container = ProviderContainer(
    overrides: [
      notesBoxProvider.overrideWithValue(notesBox),
      categoriesBoxProvider.overrideWithValue(categoriesBox),
    ],
  );

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
