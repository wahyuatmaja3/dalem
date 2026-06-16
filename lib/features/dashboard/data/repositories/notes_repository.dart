import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/note_model.dart';
import '../category_constants.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';

/// Overridden in main.dart with the opened Hive box.
final notesBoxProvider = Provider<Box>((ref) {
  throw UnimplementedError('notesBoxProvider must be overridden in main.dart');
});

/// Overridden in main.dart with the opened Hive box.
final categoriesBoxProvider = Provider<Box>((ref) {
  throw UnimplementedError(
      'categoriesBoxProvider must be overridden in main.dart');
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(
    notesBox: ref.read(notesBoxProvider),
    categoriesBox: ref.read(categoriesBoxProvider),
    apiClient: ref.read(apiClientProvider),
  );
});

const String _customCategoriesKey = 'custom';

class NotesRepository {
  final Box _notesBox;
  final Box _categoriesBox;
  final ApiClient? _apiClient;

  NotesRepository({
    required Box notesBox,
    required Box categoriesBox,
    ApiClient? apiClient,
  })  : _notesBox = notesBox,
        _categoriesBox = categoriesBox,
        _apiClient = apiClient;

  Future<List<NoteModel>> fetchNotes() async {
    final notes = _notesBox.values
        .map((v) => NoteModel.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  Future<NoteModel> fetchNoteDetail(String noteId) async {
    final raw = _notesBox.get(noteId);
    if (raw == null) {
      throw StateError('Note not found: $noteId');
    }
    return NoteModel.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<NoteModel> createRecordedNote(
    String localAudioPath, {
    required String title,
    String? category,
  }) async {
    final resolvedTitle = title.trim().isEmpty ? 'New Recording' : title.trim();

    String? transcript;
    String? summary;
    if (_apiClient != null) {
      final result = await _apiClient.uploadFile(
        '/api/v1/notes/upload',
        localAudioPath,
        'audio',
      );
      if (result is ApiSuccess<Map<String, dynamic>>) {
        final data = result.data;
        transcript = data['transcript'] as String?;
        summary = data['summaryMarkdown'] as String?;
      }
    }

    final note = NoteModel(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
      title: resolvedTitle,
      createdAt: DateTime.now(),
      status: NoteStatus.processed,
      category: category,
      transcript: transcript ?? 'Mock transcript for the new recording...',
      summaryMarkdown: summary ?? '# $resolvedTitle\n\nProcessed successfully',
    );

    await _notesBox.put(note.id, note.toJson());
    _saveCustomCategory(category);
    return note;
  }

  Future<NoteModel> updateNote(
    String id, {
    required String title,
    String? category,
  }) async {
    final existing = await fetchNoteDetail(id);
    final resolvedTitle = title.trim().isEmpty ? existing.title : title.trim();
    final updated = existing.copyWith(title: resolvedTitle, category: category);
    await _notesBox.put(id, updated.toJson());
    _saveCustomCategory(category);
    return updated;
  }

  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  List<String> getCustomCategories() {
    final raw = _categoriesBox.get(_customCategoriesKey);
    if (raw == null) return [];
    return List<String>.from(raw as List);
  }

  void _saveCustomCategory(String? category) {
    if (category == null || category.isEmpty) return;
    if (kPresetCategories.contains(category)) return;
    final current = getCustomCategories();
    if (current.contains(category)) return;
    _categoriesBox.put(_customCategoriesKey, [...current, category]);
  }

  Future<void> deleteLocalAudio(String path) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
