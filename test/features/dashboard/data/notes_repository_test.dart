import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:dalem/features/dashboard/data/repositories/notes_repository.dart';

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
    repo = NotesRepository(notesBox: notesBox, categoriesBox: categoriesBox);
  });

  tearDown(() async {
    await notesBox.deleteFromDisk();
    await categoriesBox.deleteFromDisk();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('createRecordedNote stores note with title and category', () async {
    final note = await repo.createRecordedNote('/tmp/a.m4a',
        title: 'Standup', category: 'Meeting');
    expect(note.title, 'Standup');
    expect(note.category, 'Meeting');
    final all = await repo.fetchNotes();
    expect(all.length, 1);
    expect(all.first.title, 'Standup');
  });

  test('fetchNotes sorts newest first', () async {
    await repo.createRecordedNote('/tmp/a.m4a', title: 'First');
    await Future.delayed(const Duration(milliseconds: 5));
    await repo.createRecordedNote('/tmp/b.m4a', title: 'Second');
    final all = await repo.fetchNotes();
    expect(all.first.title, 'Second');
  });

  test('updateNote changes title and category', () async {
    final note = await repo.createRecordedNote('/tmp/a.m4a',
        title: 'Old', category: 'Work');
    final updated =
        await repo.updateNote(note.id, title: 'New', category: 'Personal');
    expect(updated.title, 'New');
    expect(updated.category, 'Personal');
    final fetched = await repo.fetchNoteDetail(note.id);
    expect(fetched.title, 'New');
  });

  test('custom category is persisted, preset is not', () async {
    await repo.createRecordedNote('/tmp/a.m4a', title: 'A', category: 'Work');
    await repo.createRecordedNote('/tmp/b.m4a',
        title: 'B', category: 'MyCustom');
    final customs = repo.getCustomCategories();
    expect(customs.contains('MyCustom'), true);
    expect(customs.contains('Work'), false);
  });

  test('empty title falls back to New Recording', () async {
    final note = await repo.createRecordedNote('/tmp/a.m4a', title: '');
    expect(note.title, 'New Recording');
  });
}
