# Dalem - Agent Instructions

## Project Overview
Flutter mobile app (v3.24+) for voice note capture, transcription, and AI chat. Targets Android/iOS with WhatsApp call recording integration via platform channels.

## Architecture
- **State Management:** BLoC or Riverpod (see `architecture.md` for state transition contracts)
- **Directory Structure:** `lib/core/` (api, secure_storage, constants) + `lib/features/` (auth, dashboard, note_detail)
- **Key Dependencies:** `record`, `http`, `flutter_secure_storage`, `flutter_markdown` (not yet in pubspec.yaml)

## Commands
- **Run:** `flutter run`
- **Test:** `flutter test`
- **Analyze:** `flutter analyze`
- **Build Android:** `flutter build apk`
- **Build iOS:** `flutter build ios`

## Critical Constraints
1. **Linear State Machines:** No overlapping state mutations. Follow exact state classes in `architecture.md:30-46`
2. **Auth Interceptor:** Every API call loads JWT from secure storage. HTTP 401 → auto-logout and redirect to sign-in
3. **Platform Channel Contract:** `MethodChannel('com.dalem.voicenotes/whatsapp')` for Android AccessibilityService integration
4. **Audio Upload Flow:** Record → stop → `AudioUploading` state → `MultipartRequest` to `/api/v1/notes/upload` with Bearer token
5. **Tab Structure:** NoteDetail uses `DefaultTabController` with 3 tabs: Transcript (selectable text), Summary (flutter_markdown), AI Chat (ListView with sender alignment)
6. **No Audio Caching:** Delete local audio files after successful upload (201/200) to preserve device storage

## Android Native Integration
- `MainActivity.kt` is basic FlutterActivity stub
- WhatsApp call recording requires:
  - AccessibilityService in AndroidManifest.xml
  - Foreground Service with AudioRecord targeting VOICE_COMMUNICATION source
  - MethodChannel callback with local file path on call end

## Current State
Fresh Flutter scaffold (default counter app in `lib/main.dart`). Core features not yet implemented. Architecture defined in `architecture.md`.

<!-- antislop:start -->
## antislop
For UI, copy, people, mobile layout, or code comments work, read `antislop.md` (core) and then the skill for the task:
- UI / visual: `skills/antislop-ui/SKILL.md`
- Copy & text: `skills/antislop-copywriting/SKILL.md`
- People: `skills/antislop-human/SKILL.md`
- Mobile / responsive: `skills/antislop-layoutmobile/SKILL.md`
- Code comments: `skills/antislop-code/SKILL.md`
Before starting, follow the core's "Two Usage Modes" section in strict order: explicit session instruction first, then global preference, then ask. A session instruction always wins. For a resolved mode, say `antislop active: <mode> (session override).` or `antislop active: <mode> (global preference).` once before presenting findings or making edits, using the actual mode and source. Acknowledging the user's request without naming the source does not replace this notice.
Only an explicit choice of antislop during or after selects a session mode. A request to review, audit, or avoid file edits does not select a mode; read the global preference in that case. Another skill's mode does not select antislop's mode.
If the mode is unresolved, ask during/after and end the response; wait for the answer before any UI review, planning, or concept, even for read-only requests. For read-only tasks, put the active-mode notice only at the start of the final answer, never in progress messages. For editing tasks, announce before the first edit and omit it from the final answer.
To update antislop later: download `antislop.md` again, or run `npx antislop-ai --update` if it was installed as skill folders.
<!-- antislop:end -->
