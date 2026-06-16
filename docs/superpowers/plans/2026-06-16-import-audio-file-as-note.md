# Import Audio File as Note Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to import an existing audio file (mp3/m4a/wav/aac) from device storage and turn it into a note, reusing the existing title/category + upload flow.

**Architecture:** Add a secondary "Import file" button to the recorder screen's idle state. On tap, open a `file_picker` dialog filtered to audio extensions, then run the same `showNoteEditSheet` → `createRecordedNote` path that recording already uses. Extract the shared "save audio as note" logic into one helper so recording and import differ only in whether the source file is deleted afterward.

**Tech Stack:** Flutter, Riverpod, `file_picker` package. No backend/API changes.

---

### Task 1: Add `file_picker` dependency

**Files:**
- Modify: `pubspec.yaml:30-62` (dependencies section)

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies:`, after the `hive_flutter: ^1.1.0` line (around line 62), add:

```yaml
  # Audio file import
  file_picker: ^8.1.2
```

- [ ] **Step 2: Fetch packages**

Run: `flutter pub get`
Expected: Resolves successfully, `file_picker` appears in the dependency tree. No version conflicts.

- [ ] **Step 3: Verify analyzer is still clean**

Run: `flutter analyze`
Expected: No new errors (same baseline as before).

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "build: add file_picker dependency for audio import"
```

---

### Task 2: Extract shared "save audio as note" helper in recorder screen

This refactor has no behavior change — it isolates the post-recording save logic so import can reuse it. The recorder screen has no widget tests, so verification is via `flutter analyze` + a manual read of the diff.

**Files:**
- Modify: `lib/features/dashboard/presentation/screens/recorder_screen.dart:46-116` (`_handleStartStop`)

- [ ] **Step 1: Add the `_saveAudioAsNote` helper method**

In `_RecorderScreenState` (in `recorder_screen.dart`), add this method directly after `_handleStartStop` (after the closing brace at line 116):

```dart
  Future<void> _saveAudioAsNote(
    String audioPath, {
    required bool deleteSourceAfter,
  }) async {
    final notesRepository = ref.read(notesRepositoryProvider);

    if (!mounted) return;
    final result = await showNoteEditSheet(
      context,
      initialTitle: '',
      customCategories: notesRepository.getCustomCategories(),
      saveLabel: 'Save note',
    );

    if (result == null) {
      if (deleteSourceAfter) {
        await notesRepository.deleteLocalAudio(audioPath);
      }
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
    if (deleteSourceAfter) {
      await notesRepository.deleteLocalAudio(audioPath);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
```

- [ ] **Step 2: Replace the inline save logic in `_handleStartStop` with a call to the helper**

In `_handleStartStop`, replace the `else` branch body (lines 77-115, from `_timer?.cancel();` down to the closing of the else block) so it becomes:

```dart
    } else {
      _timer?.cancel();
      _transcriptionSub?.cancel();
      setState(() {
        _state = const RecorderReview();
      });

      final audioPath = await recorderService.stopRecording();
      await _saveAudioAsNote(audioPath, deleteSourceAfter: true);
    }
```

- [ ] **Step 3: Verify analyzer is clean**

Run: `flutter analyze`
Expected: No errors. (`notesRepository` is now read inside the helper; confirm no unused-variable warnings remain in `_handleStartStop`.)

- [ ] **Step 4: Commit**

```bash
git add lib/features/dashboard/presentation/screens/recorder_screen.dart
git commit -m "refactor: extract _saveAudioAsNote helper in recorder screen"
```

---

### Task 3: Add import handler and button to recorder idle screen

**Files:**
- Modify: `lib/features/dashboard/presentation/screens/recorder_screen.dart` (imports, add `_handleImport`, modify `_buildIdleBody`)

- [ ] **Step 1: Add the `file_picker` import**

At the top of `recorder_screen.dart`, after the existing `import 'dart:math';` line (line 4), add:

```dart
import 'package:file_picker/file_picker.dart';
```

- [ ] **Step 2: Add the `_handleImport` method**

In `_RecorderScreenState`, add this method directly after `_saveAudioAsNote`:

```dart
  Future<void> _handleImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'wav', 'aac'],
    );

    final path = result?.files.single.path;
    if (path == null) return;

    await _saveAudioAsNote(path, deleteSourceAfter: false);
  }
```

- [ ] **Step 3: Add the import button to `_buildIdleBody`**

In `_buildIdleBody()`, the `Column`'s `children` list ends with the `_RecordButton(...)` widget (around lines 223-226). Add a spacer and a text button right after that `_RecordButton`, before the closing `],` of the children list:

```dart
          _RecordButton(
            onPressed: _handleStartStop,
            isRecording: false,
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _handleImport,
            icon: const Icon(Icons.upload_file_rounded, size: 20),
            label: const Text('Import file MP3'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
```

- [ ] **Step 4: Verify analyzer is clean**

Run: `flutter analyze`
Expected: No errors. `FilePicker`, `FileType`, and `AppColors` all resolve.

- [ ] **Step 5: Build to confirm the app compiles**

Run: `flutter build apk --debug` (or `flutter run -d <device>` if a device is attached)
Expected: Build succeeds. (`file_picker` pulls in platform code, so a full build confirms the native side links.)

- [ ] **Step 6: Manual verification (device/emulator)**

On a running device:
1. Open the recorder screen.
2. Tap "Import file MP3" → native file picker opens, filtered to audio files.
3. Cancel → returns to idle screen, no note created.
4. Re-open, pick an audio file → title/category sheet appears.
5. Cancel the sheet → returns to dashboard, no note created, file untouched.
6. Re-import, pick a file, confirm the sheet → "Uploading" state shows, then dashboard refreshes with the new note.

Note: the file picker is platform UI and cannot be exercised by `flutter test`; this manual pass is the verification for the picker interaction.

- [ ] **Step 7: Commit**

```bash
git add lib/features/dashboard/presentation/screens/recorder_screen.dart
git commit -m "feat: import audio file from device as a note"
```

---

## Self-Review Notes

- **Spec coverage:** Entry point in recorder idle (Task 3 Step 3) ✓; formats mp3/m4a/wav/aac (Task 3 Step 2) ✓; reuse title/category + upload (Task 2 helper) ✓; don't delete user's source file (`deleteSourceAfter: false`, Task 3 Step 2) ✓; no repo/API changes ✓; cancel = no-op (Task 3 Step 2 null guard) ✓.
- **Type consistency:** `_saveAudioAsNote(String, {required bool deleteSourceAfter})` defined in Task 2 and called identically in Tasks 2 & 3. `showNoteEditSheet`/`NoteEditResult`/`createRecordedNote`/`getCustomCategories`/`deleteLocalAudio` all match existing signatures in the repo and widget.
- **Platform note:** Android may require no extra manifest entry for `file_picker` audio selection on modern versions; if the picker fails to open on an older Android target, that is a platform-config follow-up, not a logic bug.
