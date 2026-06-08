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
