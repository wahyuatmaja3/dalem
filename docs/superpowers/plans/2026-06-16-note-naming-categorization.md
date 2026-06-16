# Note Naming & Categorization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to name and categorize voice notes before saving, edit name/category via swipe on the dashboard, filter notes by category, and persist everything with Hive.

**Architecture:** Migrate `NotesRepository` from an in-memory mock list to two Hive boxes (`notes` keyed by id storing JSON maps, `categories` storing custom category names). A reusable bottom sheet handles name + category input for both the recorder save flow and dashboard edit flow. Dashboard gains a category badge on each card, a `Dismissible`-based swipe-to-edit, and a category filter chip row.

**Tech Stack:** Flutter, Riverpod (StateNotifier), Hive + hive_flutter, existing `AppButton`/`AppTextField` widgets.

---

## File Structure

**Create:**
- `lib/features/dashboard/data/category_constants.dart` — preset category list + category merge helper.
- `lib/features/dashboard/presentation/widgets/note_edit_sheet.dart` — reusable name+category bottom sheet, returns a result object.
- `test/features/dashboard/data/note_model_test.dart` — model JSON/copyWith tests.
- `test/features/dashboard/data/notes_repository_test.dart` — repository Hive tests.
- `test/features/dashboard/data/category_constants_test.dart` — category merge tests.

**Modify:**
- `lib/features/dashboard/data/models/note_model.dart` — add `category` field.
- `lib/features/dashboard/data/repositories/notes_repository.dart` — Hive-backed CRUD + category persistence.
- `lib/features/dashboard/domain/providers/dashboard_providers.dart` — Hive box providers + repository wiring.
- `lib/main.dart` — init Hive, open boxes, override box providers.
- `lib/features/dashboard/presentation/controllers/dashboard_controller.dart` — store full notes + filter, add `updateNote`/`setCategoryFilter`.
- `lib/features/dashboard/presentation/screens/recorder_screen.dart` — review state + show sheet before upload.
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — filter chip row + swipe-to-edit wiring.
- `lib/features/dashboard/presentation/widgets/note_card.dart` — category badge.
- `pubspec.yaml` — add hive dependencies.

---

## Task 1: Add `category` field to NoteModel

**Files:**
- Modify: `lib/features/dashboard/data/models/note_model.dart`
- Test: `test/features/dashboard/data/note_model_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/dashboard/data/note_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dalem/features/dashboard/data/models/note_model.dart';

void main() {
  final base = NoteModel(
    id: 'n1',
    title: 'Hello',
    createdAt: DateTime.parse('2026-06-16T10:00:00.000'),
    status: NoteStatus.processed,
    category: 'Work',
  );

  group('NoteModel category', () {
    test('toJson includes category', () {
      expect(base.toJson()['category'], 'Work');
    });

    test('fromJson reads category', () {
      final note = NoteModel.fromJson(base.toJson());
      expect(note.category, 'Work');
    });

    test('fromJson tolerates missing category', () {
      final json = base.toJson()..remove('category');
      final note = NoteModel.fromJson(json);
      expect(note.category, isNull);
    });

    test('copyWith overrides category', () {
      expect(base.copyWith(category: 'Personal').category, 'Personal');
    });

    test('copyWith keeps category when omitted', () {
      expect(base.copyWith(title: 'New').category, 'Work');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/data/note_model_test.dart`
Expected: FAIL — `category` is not a named parameter / getter not defined.

- [ ] **Step 3: Write minimal implementation**

Replace the contents of `lib/features/dashboard/data/models/note_model.dart`:

```dart
enum NoteStatus { draft, uploading, processed, error }

class NoteModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final NoteStatus status;
  final String? category;
  final String? transcript;
  final String? summaryMarkdown;

  const NoteModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.status,
    this.category,
    this.transcript,
    this.summaryMarkdown,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: NoteStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => NoteStatus.draft,
      ),
      category: json['category'] as String?,
      transcript: json['transcript'] as String?,
      summaryMarkdown: json['summaryMarkdown'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'category': category,
      'transcript': transcript,
      'summaryMarkdown': summaryMarkdown,
    };
  }

  NoteModel copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    NoteStatus? status,
    String? category,
    String? transcript,
    String? summaryMarkdown,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      category: category ?? this.category,
      transcript: transcript ?? this.transcript,
      summaryMarkdown: summaryMarkdown ?? this.summaryMarkdown,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/data/note_model_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/data/models/note_model.dart test/features/dashboard/data/note_model_test.dart
git commit -m "feat: add category field to NoteModel"
```

---

## Task 2: Category constants + merge helper

**Files:**
- Create: `lib/features/dashboard/data/category_constants.dart`
- Test: `test/features/dashboard/data/category_constants_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/dashboard/data/category_constants_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dalem/features/dashboard/data/category_constants.dart';

void main() {
  group('mergeCategories', () {
    test('presets come first', () {
      final result = mergeCategories(['Custom A']);
      expect(result.take(kPresetCategories.length).toList(), kPresetCategories);
      expect(result.last, 'Custom A');
    });

    test('dedupes custom that matches a preset', () {
      final result = mergeCategories(['Work', 'Custom B']);
      expect(result.where((c) => c == 'Work').length, 1);
      expect(result.contains('Custom B'), true);
    });

    test('empty custom returns presets only', () {
      expect(mergeCategories([]), kPresetCategories);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/data/category_constants_test.dart`
Expected: FAIL — target of URI doesn't exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/dashboard/data/category_constants.dart`:

```dart
const List<String> kPresetCategories = [
  'Meeting',
  'Personal',
  'Ideas',
  'Work',
  'Other',
];

/// Presets first, then custom categories not already in presets (order preserved, deduped).
List<String> mergeCategories(List<String> custom) {
  final seen = kPresetCategories.toSet();
  final result = <String>[...kPresetCategories];
  for (final c in custom) {
    if (c.isNotEmpty && !seen.contains(c)) {
      seen.add(c);
      result.add(c);
    }
  }
  return result;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/data/category_constants_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/data/category_constants.dart test/features/dashboard/data/category_constants_test.dart
git commit -m "feat: add category presets and merge helper"
```

---

## Task 3: Add Hive dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add dependencies**

In `pubspec.yaml`, under `dependencies:` after the `intl: ^0.19.0` line, add:

```yaml
  # Local storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

- [ ] **Step 2: Fetch packages**

Run: `flutter pub get`
Expected: resolves successfully, `hive` and `hive_flutter` appear in `pubspec.lock`.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "build: add hive and hive_flutter dependencies"
```

---

## Task 4: Hive-backed NotesRepository

**Files:**
- Modify: `lib/features/dashboard/data/repositories/notes_repository.dart`
- Test: `test/features/dashboard/data/notes_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/dashboard/data/notes_repository_test.dart`:

```dart
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
    final note =
        await repo.createRecordedNote('/tmp/a.m4a', title: 'Old', category: 'Work');
    final updated =
        await repo.updateNote(note.id, title: 'New', category: 'Personal');
    expect(updated.title, 'New');
    expect(updated.category, 'Personal');
    final fetched = await repo.fetchNoteDetail(note.id);
    expect(fetched.title, 'New');
  });

  test('custom category is persisted, preset is not', () async {
    await repo.createRecordedNote('/tmp/a.m4a', title: 'A', category: 'Work');
    await repo.createRecordedNote('/tmp/b.m4a', title: 'B', category: 'MyCustom');
    final customs = repo.getCustomCategories();
    expect(customs.contains('MyCustom'), true);
    expect(customs.contains('Work'), false);
  });

  test('empty title falls back to New Recording', () async {
    final note = await repo.createRecordedNote('/tmp/a.m4a', title: '');
    expect(note.title, 'New Recording');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/data/notes_repository_test.dart`
Expected: FAIL — `NotesRepository` has no `notesBox`/`categoriesBox` params, no `updateNote`/`getCustomCategories`.

- [ ] **Step 3: Write minimal implementation**

Replace the contents of `lib/features/dashboard/data/repositories/notes_repository.dart`:

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/data/notes_repository_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/data/repositories/notes_repository.dart test/features/dashboard/data/notes_repository_test.dart
git commit -m "feat: migrate NotesRepository to Hive with category support"
```

---

## Task 5: Initialize Hive and override box providers in main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Update main.dart**

Replace the contents of `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'app/router.dart';
import 'core/secure_storage/token_storage.dart';
import 'core/services/whatsapp_bridge_service.dart';
import 'features/dashboard/data/repositories/notes_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  final notesBox = await Hive.openBox('notes');
  final categoriesBox = await Hive.openBox('categories');

  final container = ProviderContainer(
    overrides: [
      notesBoxProvider.overrideWithValue(notesBox),
      categoriesBoxProvider.overrideWithValue(categoriesBox),
    ],
  );

  String initialRoute;
  try {
    final tokenStorage = container.read(tokenStorageProvider);
    final token = await tokenStorage.readAccessToken();
    initialRoute = token != null ? AppRouter.dashboard : AppRouter.signIn;
  } catch (_) {
    initialRoute = AppRouter.signIn;
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: DalemApp(initialRoute: initialRoute),
    ),
  );

  Future.microtask(() {
    container.read(whatsAppBridgeProvider).initialize();
  });
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/main.dart`
Expected: No errors (warnings about other files are fine if unrelated).

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: init Hive and wire box providers"
```

---

## Task 6: Reusable note edit bottom sheet

**Files:**
- Create: `lib/features/dashboard/presentation/widgets/note_edit_sheet.dart`

- [ ] **Step 1: Create the widget**

Create `lib/features/dashboard/presentation/widgets/note_edit_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/category_constants.dart';

class NoteEditResult {
  final String title;
  final String? category;
  const NoteEditResult({required this.title, required this.category});
}

/// Shows the name + category sheet. Returns a [NoteEditResult] on save, or null
/// if the user dismisses/cancels.
Future<NoteEditResult?> showNoteEditSheet(
  BuildContext context, {
  String initialTitle = '',
  String? initialCategory,
  List<String> customCategories = const [],
  String saveLabel = 'Save',
}) {
  return showModalBottomSheet<NoteEditResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _NoteEditSheet(
      initialTitle: initialTitle,
      initialCategory: initialCategory,
      customCategories: customCategories,
      saveLabel: saveLabel,
    ),
  );
}

class _NoteEditSheet extends StatefulWidget {
  final String initialTitle;
  final String? initialCategory;
  final List<String> customCategories;
  final String saveLabel;

  const _NoteEditSheet({
    required this.initialTitle,
    required this.initialCategory,
    required this.customCategories,
    required this.saveLabel,
  });

  @override
  State<_NoteEditSheet> createState() => _NoteEditSheetState();
}

class _NoteEditSheetState extends State<_NoteEditSheet> {
  late final TextEditingController _titleController;
  late List<String> _categories;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _categories = mergeCategories(widget.customCategories);
    _selectedCategory = widget.initialCategory;
    if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
      _categories = [..._categories, _selectedCategory!];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addCustomCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Category name'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() {
        if (!_categories.contains(name)) _categories = [..._categories, name];
        _selectedCategory = name;
      });
    }
  }

  void _save() {
    Navigator.of(context).pop(
      NoteEditResult(
        title: _titleController.text.trim(),
        category: _selectedCategory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Note name',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            autofocus: true,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(hintText: 'e.g. Team standup'),
          ),
          const SizedBox(height: 20),
          Text(
            'Category',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in _categories)
                ChoiceChip(
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  onSelected: (sel) {
                    setState(() => _selectedCategory = sel ? cat : null);
                  },
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
                onPressed: _addCustomCategory,
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppButton(text: widget.saveLabel, onPressed: _save),
          const SizedBox(height: 8),
          AppButton(
            text: 'Cancel',
            isOutlined: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/dashboard/presentation/widgets/note_edit_sheet.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/dashboard/presentation/widgets/note_edit_sheet.dart
git commit -m "feat: add reusable note name and category bottom sheet"
```

---

## Task 7: Recorder review flow — show sheet before upload

**Files:**
- Modify: `lib/features/dashboard/presentation/screens/recorder_screen.dart`

- [ ] **Step 1: Add the RecorderReview state**

In `recorder_screen.dart`, after the `RecorderUploading` class (around line 24), add:

```dart
class RecorderReview extends RecorderState {
  const RecorderReview();
}
```

- [ ] **Step 2: Add imports**

At the top of `recorder_screen.dart`, alongside the existing imports, add:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/note_edit_sheet.dart';
```

(Note: `flutter_riverpod` is already imported — do not duplicate. Only add the `note_edit_sheet.dart` import if missing.)

- [ ] **Step 3: Replace the stop branch in `_handleStartStop`**

Replace the `else` block of `_handleStartStop` (the branch that runs when stopping, currently lines ~72-87) with:

```dart
    } else {
      _timer?.cancel();
      _transcriptionSub?.cancel();
      setState(() {
        _state = const RecorderReview();
      });

      final audioPath = await recorderService.stopRecording();
      final notesRepository = ref.read(notesRepositoryProvider);

      if (!mounted) return;
      final result = await showNoteEditSheet(
        context,
        initialTitle: '',
        customCategories: notesRepository.getCustomCategories(),
        saveLabel: 'Save note',
      );

      if (result == null) {
        await notesRepository.deleteLocalAudio(audioPath);
        if (mounted) Navigator.of(context).pop();
        return;
      }

      setState(() {
        _state = const RecorderUploading();
      });

      await notesRepository.createRecordedNote(
        audioPath,
        title: result.title,
        category: result.category,
      );
      await notesRepository.deleteLocalAudio(audioPath);

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
```

- [ ] **Step 4: Handle the new state in `build`**

In the `body:` switch (around line 148), the existing arms are `RecorderIdle`, `RecorderRecording`, `RecorderUploading`. Add a `RecorderReview` arm that reuses the recording body's dark waiting look — replace the switch with:

```dart
      body: switch (_state) {
        RecorderIdle() => _buildIdleBody(),
        RecorderRecording() => _buildRecordingBody(),
        RecorderReview() => _buildUploadingBody(),
        RecorderUploading() => _buildUploadingBody(),
      },
```

Also update the `backgroundColor` and `foregroundColor` ternaries in the `Scaffold`/`AppBar` only if needed — they key off `RecorderRecording`, which is correct as-is; leave them unchanged.

- [ ] **Step 5: Run analyzer and existing recorder test**

Run: `flutter analyze lib/features/dashboard/presentation/screens/recorder_screen.dart`
Expected: No errors (switch is exhaustive).

Run: `flutter test test/core/services/recorder_service_test.dart`
Expected: PASS (5 tests, no regression).

- [ ] **Step 6: Commit**

```bash
git add lib/features/dashboard/presentation/screens/recorder_screen.dart
git commit -m "feat: prompt for note name and category before saving recording"
```

---

## Task 8: Dashboard controller — filter + updateNote

**Files:**
- Modify: `lib/features/dashboard/presentation/controllers/dashboard_controller.dart`

- [ ] **Step 1: Replace the controller**

Replace the contents of `lib/features/dashboard/presentation/controllers/dashboard_controller.dart`:

```dart
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
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/dashboard/presentation/controllers/dashboard_controller.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/dashboard/presentation/controllers/dashboard_controller.dart
git commit -m "feat: add category filter and updateNote to dashboard controller"
```

---

## Task 9: Category badge on NoteCard

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/note_card.dart`

- [ ] **Step 1: Add the category badge**

In `note_card.dart`, inside the `Row` that holds date + status badge (the inner `Row` starting around line 124), add a category chip after the status badge `Container`. Locate the closing of the status badge `Container` (the one with `child: Row(... status text ...)`) and insert, immediately after it inside the `children` list:

```dart
                          if (note.category != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                note.category!,
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
```

Wrap the date/status/category `Row` content so it doesn't overflow: change that inner `Row` to be wrapped in a `Wrap` if overflow occurs. Minimal approach: leave as `Row` but wrap the whole thing in `SingleChildScrollView` is overkill — instead, change the inner `Row(children: [...])` to `Wrap(spacing: 0, runSpacing: 4, children: [...])` keeping the existing children plus the new category block. Use `Wrap` to be safe on narrow screens.

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/dashboard/presentation/widgets/note_card.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/dashboard/presentation/widgets/note_card.dart
git commit -m "feat: show category badge on note card"
```

---

## Task 10: Dashboard — filter chips + swipe-to-edit

**Files:**
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

- [ ] **Step 1: Add imports**

At the top of `dashboard_screen.dart`, add:

```dart
import '../widgets/note_edit_sheet.dart';
import '../../data/repositories/notes_repository.dart';
```

- [ ] **Step 2: Add the edit handler method**

Inside `_DashboardScreenState`, add this method (e.g. after `_handleLogout`):

```dart
  Future<void> _handleEditNote(note) async {
    final repo = ref.read(notesRepositoryProvider);
    final result = await showNoteEditSheet(
      context,
      initialTitle: note.title,
      initialCategory: note.category,
      customCategories: repo.getCustomCategories(),
      saveLabel: 'Save changes',
    );
    if (result == null) return;
    await ref.read(dashboardControllerProvider.notifier).updateNote(
          note.id,
          title: result.title,
          category: result.category,
        );
  }
```

- [ ] **Step 3: Replace the `DashboardLoaded` arm of `_buildBody`**

In `_buildBody`, replace the `DashboardLoaded(notes: final notes) => ...` arm with one that reads the loaded state, renders a filter chip row, and wraps each card in a `Dismissible`:

```dart
      DashboardLoaded() => _buildLoaded(state as DashboardLoaded),
```

Then add a new method to `_DashboardScreenState`:

```dart
  Widget _buildLoaded(DashboardLoaded state) {
    final visible = state.visibleNotes;
    final categories = state.availableCategories;

    if (state.notes.isEmpty) {
      return const EmptyState();
    }

    return Column(
      children: [
        if (categories.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Semua'),
                    selected: state.selectedCategory == null,
                    onSelected: (_) => ref
                        .read(dashboardControllerProvider.notifier)
                        .setCategoryFilter(null),
                  ),
                ),
                for (final cat in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: state.selectedCategory == cat,
                      onSelected: (_) => ref
                          .read(dashboardControllerProvider.notifier)
                          .setCategoryFilter(cat),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await ref.read(dashboardControllerProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final note = visible[index];
                return Dismissible(
                  key: ValueKey(note.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 28),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: AppColors.primaryDark),
                  ),
                  confirmDismiss: (_) async {
                    await _handleEditNote(note);
                    return false;
                  },
                  child: NoteCard(
                    note: note,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.noteDetail,
                        arguments: note.id,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 4: Verify it compiles**

Run: `flutter analyze lib/features/dashboard/presentation/screens/dashboard_screen.dart`
Expected: No errors. (The old `DashboardLoaded(notes: final notes)` destructuring is now removed; `EmptyState` is still imported and used.)

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/screens/dashboard_screen.dart
git commit -m "feat: add category filter chips and swipe-to-edit on dashboard"
```

---

## Task 11: Full verification

- [ ] **Step 1: Analyze whole project**

Run: `flutter analyze`
Expected: No errors. Address any analyzer errors introduced by the changes.

- [ ] **Step 2: Run full test suite**

Run: `flutter test`
Expected: All tests pass (model, category, repository, recorder service).

- [ ] **Step 3: Manual smoke test (if device/emulator available)**

Run: `flutter run`
Verify:
1. Record → stop → sheet appears → enter name + pick category → Save → note appears on dashboard with category badge.
2. Record → stop → sheet → Cancel → no note saved.
3. Add a custom category in the sheet → it persists and reappears next time.
4. Swipe a card left → edit sheet opens prefilled → change name/category → Save → card updates.
5. Filter chips appear when notes have categories → tapping filters the list → "Semua" shows all.
6. Kill and relaunch app → notes still present (Hive persistence).

If no device is available, state that explicitly and rely on `flutter analyze` + `flutter test`.

- [ ] **Step 4: Final commit (if any cleanup needed)**

```bash
git add -A
git commit -m "chore: verification pass for note naming and categorization"
```

---

## Self-Review Notes

- **Spec coverage:** name-before-save (Task 7), hybrid categories (Tasks 2, 6), edit via swipe (Task 10), badge (Task 9), filter (Tasks 8, 10), Hive persistence (Tasks 3, 4, 5). All covered.
- **Type consistency:** `createRecordedNote(path, {required title, category})`, `updateNote(id, {required title, category})`, `getCustomCategories()`, `NoteEditResult{title, category}`, `mergeCategories(custom)`, `notesBoxProvider`/`categoriesBoxProvider` — used consistently across tasks.
- **Migration:** previous mock notes are gone by design (spec: no real prior data). First launch shows empty state until a note is recorded.
