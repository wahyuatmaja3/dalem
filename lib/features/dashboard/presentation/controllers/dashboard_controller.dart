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
  final String? selectedCategory;

  const DashboardLoaded(this.notes, {this.selectedCategory});

  List<NoteModel> get visibleNotes => selectedCategory == null
      ? notes
      : notes.where((n) => n.category == selectedCategory).toList();

  List<String> get availableCategories {
    final cats = notes
        .map((n) => n.category)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    return cats;
  }

  DashboardLoaded copyWith({
    List<NoteModel>? notes,
    String? selectedCategory,
    bool clearCategory = false,
  }) {
    return DashboardLoaded(
      notes ?? this.notes,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
    );
  }
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
    final current = state;
    final keepCategory =
        current is DashboardLoaded ? current.selectedCategory : null;
    try {
      final notes = await repository.fetchNotes();
      state = DashboardLoaded(notes, selectedCategory: keepCategory);
    } catch (e) {
      state = DashboardError(e.toString());
    }
  }

  Future<void> updateNote(String id,
      {required String title, String? category}) async {
    await repository.updateNote(id, title: title, category: category);
    await refresh();
  }

  void setCategoryFilter(String? category) {
    final current = state;
    if (current is! DashboardLoaded) return;
    if (category == null) {
      state = current.copyWith(clearCategory: true);
    } else {
      state = current.copyWith(selectedCategory: category);
    }
  }
}
