import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/data/repositories/notes_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../presentation/controllers/note_detail_controller.dart';

final noteDetailControllerProvider = StateNotifierProvider.family<
    NoteDetailController, NoteDetailState, String>((ref, noteId) {
  final notesRepository = ref.read(notesRepositoryProvider);
  final chatRepository = ref.read(chatRepositoryProvider);
  return NoteDetailController(
    noteId: noteId,
    notesRepository: notesRepository,
    chatRepository: chatRepository,
  );
});
