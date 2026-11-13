import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'app/router.dart';
import 'core/services/whatsapp_bridge_service.dart';
import 'features/dashboard/data/repositories/notes_repository.dart';
import 'features/note_detail/data/repositories/chat_repository.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  final notesBox = await Hive.openBox('notes');
  final categoriesBox = await Hive.openBox('categories');
  final chatBox = await Hive.openBox('chat_history');

  final container = ProviderContainer(
    overrides: [
      notesBoxProvider.overrideWithValue(notesBox),
      categoriesBoxProvider.overrideWithValue(categoriesBox),
      chatBoxProvider.overrideWithValue(chatBox),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DalemApp(initialRoute: AppRouter.dashboard),
    ),
  );

  Future.microtask(() {
    container.read(whatsAppBridgeProvider).initialize();
  });
}
