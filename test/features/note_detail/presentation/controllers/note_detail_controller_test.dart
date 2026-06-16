import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:dalem/features/note_detail/presentation/controllers/note_detail_controller.dart';
import 'package:dalem/features/dashboard/data/repositories/notes_repository.dart';
import 'package:dalem/features/note_detail/data/repositories/chat_repository.dart';

void main() {
  group('NoteDetailController', () {
    late Directory tempDir;
    late Box notesBox;
    late Box categoriesBox;
    late NoteDetailController controller;
    late NotesRepository notesRepository;
    late ChatRepository chatRepository;
    late String noteId;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_detail');
      Hive.init(tempDir.path);
      notesBox = await Hive.openBox('notes_${tempDir.path.hashCode}');
      categoriesBox = await Hive.openBox('cats_${tempDir.path.hashCode}');
      notesRepository =
          NotesRepository(notesBox: notesBox, categoriesBox: categoriesBox);
      chatRepository = ChatRepository();
      final note = await notesRepository.createRecordedNote('/tmp/a.m4a',
          title: 'Detail seed', category: 'Work');
      noteId = note.id;
      controller = NoteDetailController(
        noteId: noteId,
        notesRepository: notesRepository,
        chatRepository: chatRepository,
      );
    });

    tearDown(() async {
      await notesBox.deleteFromDisk();
      await categoriesBox.deleteFromDisk();
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('initial state is NoteDetailLoading', () {
      expect(controller.state, isA<NoteDetailLoading>());
    });

    test('loadNote transitions to loaded with note and chat history', () async {
      await controller.loadNote();

      expect(controller.state, isA<NoteDetailLoaded>());
      final loadedState = controller.state as NoteDetailLoaded;
      expect(loadedState.note.id, noteId);
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
