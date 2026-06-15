import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository();
});

class NotesRepository {
  final List<NoteModel> _mockNotes = [
    NoteModel(
      id: 'note_1',
      title: 'Team Meeting Notes',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      status: NoteStatus.processed,
      transcript: 'This is a mock transcript of the team meeting...',
      summaryMarkdown: '# Team Meeting\n\n- Discussed project timeline\n- Reviewed features',
    ),
    NoteModel(
      id: 'note_2',
      title: 'Client Call',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: NoteStatus.processed,
      transcript: 'Client call transcript here...',
      summaryMarkdown: '# Client Call\n\n- Client feedback positive\n- Next steps defined',
    ),
    NoteModel(
      id: 'note_3',
      title: 'Morning Standup',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: NoteStatus.processed,
      transcript: 'Standup transcript...',
      summaryMarkdown: '# Standup\n\n- Everyone on track\n- No blockers',
    ),
  ];

  Future<List<NoteModel>> fetchNotes() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return List.from(_mockNotes);
  }

  Future<NoteModel> fetchNoteDetail(String noteId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockNotes.firstWhere(
      (note) => note.id == noteId,
      orElse: () => _mockNotes.first,
    );
  }

  Future<NoteModel> createRecordedNote(String localAudioPath) async {
    await Future.delayed(const Duration(seconds: 2));

    final newNote = NoteModel(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Recording',
      createdAt: DateTime.now(),
      status: NoteStatus.processed,
      transcript: 'Mock transcript for the new recording...',
      summaryMarkdown: '# New Recording\n\nProcessed successfully',
    );

    _mockNotes.insert(0, newNote);
    return newNote;
  }

  Future<void> deleteLocalAudio(String path) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
