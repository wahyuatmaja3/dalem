import 'package:flutter_test/flutter_test.dart';
import 'package:dalem/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:dalem/features/dashboard/data/repositories/notes_repository.dart';

void main() {
  group('DashboardController', () {
    late DashboardController controller;
    late NotesRepository repository;

    setUp(() {
      repository = NotesRepository();
      controller = DashboardController(repository: repository);
    });

    test('initial state is DashboardState.initial', () {
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
  });
}
