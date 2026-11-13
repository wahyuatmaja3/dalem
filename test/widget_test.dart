import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:dalem/app/app.dart';
import 'package:dalem/app/router.dart';
import 'package:dalem/features/dashboard/data/repositories/notes_repository.dart';
import 'package:dalem/features/settings/presentation/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box notesBox;
  late Box categoriesBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_widget');
    Hive.init(tempDir.path);
    notesBox = await Hive.openBox('notes_test');
    categoriesBox = await Hive.openBox('categories_test');
  });

  tearDownAll(() async {
    await notesBox.deleteFromDisk();
    await categoriesBox.deleteFromDisk();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('App renders with Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notesBoxProvider.overrideWithValue(notesBox),
          categoriesBoxProvider.overrideWithValue(categoriesBox),
        ],
        child: const DalemApp(initialRoute: AppRouter.dashboard),
      ),
    );
    await tester.pump();
    expect(find.byType(DalemApp), findsOneWidget);
    expect(find.text('Dalem'), findsOneWidget);
  });

  testWidgets('Theme toggle switches ThemeMode in SettingsScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notesBoxProvider.overrideWithValue(notesBox),
          categoriesBoxProvider.overrideWithValue(categoriesBox),
        ],
        child: const DalemApp(initialRoute: AppRouter.settings),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Tampilan & Tema'), findsOneWidget);

    // Tap dark mode segment
    final darkButton = find.text('Gelap');
    expect(darkButton, findsOneWidget);
    await tester.tap(darkButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify MaterialApp has dark theme active
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
  });
}
