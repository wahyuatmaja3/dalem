import 'package:flutter_test/flutter_test.dart';
import 'package:dalem/features/dashboard/data/repositories/notes_repository.dart';
import 'package:dalem/features/dashboard/data/models/note_model.dart';

void main() {
  group('NotesRepository', () {
    late NotesRepository repository;

    setUp(() {
      repository = NotesRepository();
    });

    test('fetchNotes returns list of notes', () async {
      final notes = await repository.fetchNotes();
      
      expect(notes, isA<List<NoteModel>>());
      expect(notes.isNotEmpty, true);
    });

    test('fetchNoteDetail returns note with content', () async {
      final note = await repository.fetchNoteDetail('note_1');
      
      expect(note, isA<NoteModel>());
      expect(note.transcript, isNotNull);
      expect(note.summaryMarkdown, isNotNull);
    });

    test('createRecordedNote returns new note', () async {
      final note = await repository.createRecordedNote('/path/to/audio.m4a');
      
      expect(note, isA<NoteModel>());
      expect(note.status, NoteStatus.processed);
    });
  });
}
