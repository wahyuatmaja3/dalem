import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:dalem/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:dalem/features/dashboard/data/repositories/notes_repository.dart';

void main() {
  group('DashboardController', () {
    late Directory tempDir;
    late Box notesBox;
    late Box categoriesBox;
    late DashboardController controller;
    late NotesRepository repository;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_dash');
      Hive.init(tempDir.path);
      notesBox = await Hive.openBox('notes_${tempDir.path.hashCode}');
      categoriesBox = await Hive.openBox('cats_${tempDir.path.hashCode}');
      repository =
          NotesRepository(notesBox: notesBox, categoriesBox: categoriesBox);
      await repository.createRecordedNote('/tmp/a.m4a',
          title: 'Seed', category: 'Work');
      controller = DashboardController(repository: repository);
    });

    tearDown(() async {
      await notesBox.deleteFromDisk();
      await categoriesBox.deleteFromDisk();
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('initial state is DashboardInitial', () {
      expect(controller.state, isA<DashboardInitial>());
    });

    test('loadNotes transitions through loading to loaded', () async {
      expect(controller.state, isA<DashboardInitial>());

      final loadFuture = controller.loadNotes();
      expect(controller.state, isA<DashboardLoading>());

      await loadFuture;
      expect(controller.state, isA<DashboardLoaded>());
      final loadedState = controller.state as DashboardLoaded;
      expect(loadedState.notes.isNotEmpty, true);
    });

    test('refresh updates notes list', () async {
      await controller.loadNotes();
      final firstState = controller.state as DashboardLoaded;
      final firstCount = firstState.notes.length;

      await controller.refresh();
      final secondState = controller.state as DashboardLoaded;
      expect(secondState.notes.length, firstCount);
    });

    test('setCategoryFilter narrows visible notes', () async {
      await repository.createRecordedNote('/tmp/b.m4a',
          title: 'Other note', category: 'Personal');
      await controller.loadNotes();

      controller.setCategoryFilter('Work');
      final state = controller.state as DashboardLoaded;
      expect(state.visibleNotes.every((n) => n.category == 'Work'), true);

      controller.setCategoryFilter(null);
      final cleared = controller.state as DashboardLoaded;
      expect(cleared.visibleNotes.length, cleared.notes.length);
    });

    test('updateNote persists new title', () async {
      await controller.loadNotes();
      final note = (controller.state as DashboardLoaded).notes.first;

      await controller.updateNote(note.id,
          title: 'Renamed', category: 'Ideas');

      final updated = (controller.state as DashboardLoaded)
          .notes
          .firstWhere((n) => n.id == note.id);
      expect(updated.title, 'Renamed');
      expect(updated.category, 'Ideas');
    });
  });
}
