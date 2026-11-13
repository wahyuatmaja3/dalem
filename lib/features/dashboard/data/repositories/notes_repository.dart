import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/note_model.dart';
import '../models/transcript_segment.dart';
import '../category_constants.dart';
import '../../../../core/services/offline_transcription_service.dart';
import '../../../../core/services/offline_summary_service.dart';

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
    transcriptionService: ref.read(offlineTranscriptionServiceProvider),
    summaryService: ref.read(offlineSummaryServiceProvider),
  );
});

const String _customCategoriesKey = 'custom';

class NotesRepository {
  final Box _notesBox;
  final Box _categoriesBox;
  final OfflineTranscriptionService? _transcriptionService;
  final OfflineSummaryService? _summaryService;

  NotesRepository({
    required Box notesBox,
    required Box categoriesBox,
    OfflineTranscriptionService? transcriptionService,
    OfflineSummaryService? summaryService,
  })  : _notesBox = notesBox,
        _categoriesBox = categoriesBox,
        _transcriptionService = transcriptionService,
        _summaryService = summaryService;

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
    List<TranscriptSegment> segments = const [];

    // Offline transcription using Whisper on-device
    if (_transcriptionService != null) {
      try {
        final result = await _transcriptionService.transcribe(
          filePath: localAudioPath,
        );
        transcript = result.text;
        segments = result.segments
            .map((s) => TranscriptSegment(
                  startSeconds: s.startSeconds,
                  endSeconds: s.endSeconds,
                  speaker: s.speaker ?? 'Speaker',
                  text: s.text,
                ))
            .toList();
      } catch (_) {
        // If transcription is not yet ready or failed, audioPath will be preserved for retry
      }
    }

    final finalTranscript = transcript?.trim().isNotEmpty == true
        ? transcript!.trim()
        : null;

    // Offline summary generation using extractive rule-based engine
    final finalSummary = _buildSummary(finalTranscript);

    final note = NoteModel(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
      title: resolvedTitle,
      createdAt: DateTime.now(),
      status:
          finalTranscript != null ? NoteStatus.processed : NoteStatus.draft,
      category: category,
      transcript: finalTranscript,
      summaryMarkdown: finalSummary,
      transcriptSegments: segments,
      audioPath: finalTranscript == null ? localAudioPath : null,
    );

    await _notesBox.put(note.id, note.toJson());
    _saveCustomCategory(category);
    return note;
  }

  /// Retries transcription for a note that has a saved [audioPath].
  Future<NoteModel> transcribeNote(String noteId) async {
    final note = await fetchNoteDetail(noteId);
    final audioPath = note.audioPath;
    if (audioPath == null || audioPath.isEmpty) {
      throw StateError('Note has no audio file to transcribe');
    }

    final file = File(audioPath);
    if (!await file.exists()) {
      throw StateError('Audio file no longer exists at $audioPath');
    }

    if (_transcriptionService == null) {
      throw StateError('Layanan transkripsi offline tidak tersedia');
    }

    final result = await _transcriptionService.transcribe(filePath: audioPath);
    final finalTranscript = result.text.trim();
    if (finalTranscript.isEmpty) {
      throw StateError('Transkripsi suara offline tidak menghasilkan teks.');
    }

    final segments = result.segments
        .map((s) => TranscriptSegment(
              startSeconds: s.startSeconds,
              endSeconds: s.endSeconds,
              speaker: s.speaker ?? 'Speaker',
              text: s.text,
            ))
        .toList();

    final finalSummary = _buildSummary(finalTranscript);

    final updated = note.copyWith(
      transcript: finalTranscript,
      transcriptSegments: segments,
      summaryMarkdown: finalSummary,
      status: NoteStatus.processed,
      audioPath: null,
    );

    await _notesBox.put(updated.id, updated.toJson());
    await deleteLocalAudio(audioPath);
    return updated;
  }

  /// Regenerates (or generates) the offline AI summary for an existing note.
  Future<NoteModel> regenerateSummary(String noteId) async {
    final note = await fetchNoteDetail(noteId);
    final transcript = note.transcript;
    if (transcript == null || transcript.trim().isEmpty) {
      throw StateError('Catatan belum memiliki transkrip untuk diringkas.');
    }
    if (_summaryService == null) {
      throw StateError('Layanan ringkasan offline belum tersedia.');
    }
    final summary = _summaryService.generateSummary(transcript);
    final updated = note.copyWith(summaryMarkdown: summary);
    await _notesBox.put(updated.id, updated.toJson());
    return updated;
  }

  String? _buildSummary(String? transcript) {
    if (_summaryService != null &&
        transcript != null &&
        transcript.trim().isNotEmpty) {
      return _summaryService.generateSummary(transcript);
    }
    return null;
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
    try {
      final note = await fetchNoteDetail(id);
      if (note.audioPath != null) {
        await deleteLocalAudio(note.audioPath!);
      }
    } catch (_) {}
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
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
