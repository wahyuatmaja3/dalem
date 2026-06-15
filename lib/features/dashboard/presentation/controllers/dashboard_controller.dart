import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/notes_repository.dart';
import '../../data/models/note_model.dart';

sealed class DashboardState {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final List<NoteModel> notes;
  const DashboardLoaded(this.notes);
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
}

class DashboardController extends StateNotifier<DashboardState> {
  final NotesRepository repository;

  DashboardController({required this.repository})
      : super(const DashboardInitial());

  Future<void> loadNotes() async {
    state = const DashboardLoading();
    try {
      final notes = await repository.fetchNotes();
      state = DashboardLoaded(notes);
    } catch (e) {
      state = DashboardError(e.toString());
    }
  }

  Future<void> refresh() async {
    try {
      final notes = await repository.fetchNotes();
      state = DashboardLoaded(notes);
    } catch (e) {
      state = DashboardError(e.toString());
    }
  }
}
