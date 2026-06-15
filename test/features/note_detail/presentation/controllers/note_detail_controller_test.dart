import 'package:flutter_test/flutter_test.dart';
import 'package:dalem/features/note_detail/presentation/controllers/note_detail_controller.dart';
import 'package:dalem/features/dashboard/data/repositories/notes_repository.dart';
import 'package:dalem/features/note_detail/data/repositories/chat_repository.dart';

void main() {
  group('NoteDetailController', () {
    late NoteDetailController controller;
    late NotesRepository notesRepository;
    late ChatRepository chatRepository;

    setUp(() {
      notesRepository = NotesRepository();
      chatRepository = ChatRepository();
      controller = NoteDetailController(
        noteId: 'note_1',
        notesRepository: notesRepository,
        chatRepository: chatRepository,
      );
    });

    test('initial state is NoteDetailLoading', () {
      expect(controller.state, isA<NoteDetailLoading>());
    });

    test('loadNote transitions to loaded with note and chat history', () async {
      await controller.loadNote();
      
      expect(controller.state, isA<NoteDetailLoaded>());
      final loadedState = controller.state as NoteDetailLoaded;
      expect(loadedState.note.id, 'note_1');
      expect(loadedState.chatHistory, isA<List>());
    });

    test('sendMessage adds user message and AI response', () async {
      await controller.loadNote();
      final initialState = controller.state as NoteDetailLoaded;
      final initialCount = initialState.chatHistory.length;

      await controller.sendMessage('Hello AI');
      
      final finalState = controller.state as NoteDetailLoaded;
      expect(finalState.chatHistory.length, greaterThan(initialCount));
    });
  });
}
