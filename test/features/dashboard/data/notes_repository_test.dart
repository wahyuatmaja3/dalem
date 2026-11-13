import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:dalem/core/services/offline_summary_service.dart';
import 'package:dalem/features/dashboard/data/repositories/notes_repository.dart';
import '../../../helpers/fake_offline_services.dart';

void main() {
  late Directory tempDir;
  late Box notesBox;
  late Box categoriesBox;
  late NotesRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    notesBox = await Hive.openBox('notes_test_${tempDir.path.hashCode}');
    categoriesBox = await Hive.openBox('cats_test_${tempDir.path.hashCode}');
    repo = NotesRepository(
      notesBox: notesBox,
      categoriesBox: categoriesBox,
      transcriptionService: FakeOfflineTranscriptionService(),
      summaryService: OfflineSummaryService(),
    );
  });

  tearDown(() async {
    await notesBox.deleteFromDisk();
    await categoriesBox.deleteFromDisk();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('createRecordedNote stores note with title and category and offline transcript', () async {
    final note = await repo.createRecordedNote('/tmp/a.wav',
        title: 'Standup', category: 'Meeting');
    expect(note.title, 'Standup');
    expect(note.category, 'Meeting');
    expect(note.transcript, 'Mock offline transcript');
    expect(note.summaryMarkdown, contains('## Overview'));
    final all = await repo.fetchNotes();
    expect(all.length, 1);
    expect(all.first.title, 'Standup');
  });

  test('fetchNotes sorts newest first', () async {
    await repo.createRecordedNote('/tmp/a.wav', title: 'First');
    await Future.delayed(const Duration(milliseconds: 5));
    await repo.createRecordedNote('/tmp/b.wav', title: 'Second');
    final all = await repo.fetchNotes();
    expect(all.first.title, 'Second');
  });

  test('updateNote changes title and category', () async {
    final note = await repo.createRecordedNote('/tmp/a.wav',
        title: 'Old', category: 'Work');
    final updated =
        await repo.updateNote(note.id, title: 'New', category: 'Personal');
    expect(updated.title, 'New');
    expect(updated.category, 'Personal');
    final fetched = await repo.fetchNoteDetail(note.id);
    expect(fetched.title, 'New');
  });

  test('custom category is persisted, preset is not', () async {
    await repo.createRecordedNote('/tmp/a.wav', title: 'A', category: 'Work');
    await repo.createRecordedNote('/tmp/b.wav',
        title: 'B', category: 'MyCustom');
    final customs = repo.getCustomCategories();
    expect(customs.contains('MyCustom'), true);
    expect(customs.contains('Work'), false);
  });

  test('empty title falls back to New Recording', () async {
    final note = await repo.createRecordedNote('/tmp/a.wav', title: '');
    expect(note.title, 'New Recording');
  });

  test('regenerateSummary updates summary markdown', () async {
    final note = await repo.createRecordedNote('/tmp/a.wav', title: 'Plan');
    final updated = await repo.regenerateSummary(note.id);
    expect(updated.summaryMarkdown, contains('## Overview'));
  });
}
