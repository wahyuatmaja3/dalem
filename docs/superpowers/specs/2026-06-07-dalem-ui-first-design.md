# Dalem UI-First Flutter App Design

**Date:** 2026-06-07  
**Project:** Dalem  
**Scope:** Android-only, UI-first mobile app implementation based on `architecture.md`

## 1. Goals

Build the first version of the Dalem Flutter app as an Android-only product with a clean professional interface. This version prioritizes complete user flows and production-shaped architecture over real backend integration. The app must include authentication screens, a dashboard of notes, a note detail screen with Transcript/Summary/AI Chat tabs, an audio recording flow, secure token handling, interceptor-driven auth behavior, and scaffolding for the WhatsApp native listener bridge.

The first version is intentionally UI-first. Backend requests, upload processing, and Android WhatsApp capture are represented by mocks or placeholders behind stable interfaces so the app can be upgraded later without replacing screen logic.

## 2. Product Constraints

- Platform target: Android only
- Visual direction: clean professional
- State management: Riverpod
- Architecture style: modular `core + features`
- Navigation: named routes
- Implementation phase: UI-first with production-shaped mocks
- PRD requirement: maintain explicit linear state transitions and avoid overlapping mutations

## 3. Architecture

The app structure extends the PRD into a feature-oriented Flutter layout:

```text
lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart
│   │   ├── api_result.dart
│   │   └── auth_interceptor.dart
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_routes.dart
│   │   └── app_strings.dart
│   ├── secure_storage/
│   │   └── token_storage.dart
│   ├── services/
│   │   ├── recorder_service.dart
│   │   └── whatsapp_bridge_service.dart
│   └── widgets/
│       ├── app_button.dart
│       ├── app_text_field.dart
│       └── app_error_view.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── dashboard/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── note_detail/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart
```

### Module boundaries

- `app/` contains application composition, routing, and theme setup.
- `core/` contains reusable infrastructure and shared widgets.
- `features/` contains business modules organized into `data`, `domain`, and `presentation` layers.
- The UI may depend on feature controllers/providers only. It must not read secure storage, method channels, or low-level services directly.

This keeps the UI-first build maintainable and allows real integrations to replace mocks later with minimal surface change.

## 4. Screen Flow and Navigation

The app uses a simple linear flow:

```text
Splash
 ├─ token valid  -> Dashboard
 └─ no token     -> Sign In
                    └─ Register

Dashboard
 ├─ tap note         -> Note Detail
 ├─ tap record       -> Recorder flow
 └─ logout           -> Sign In
```

### Screens

#### Splash / App Bootstrap
Checks secure storage for a stored access token. If a token exists, the app routes to the dashboard. Otherwise it routes to sign in.

#### Sign In
Contains email and password fields, sign-in CTA, loading/error feedback, and a link to register.

#### Register
Contains name, email, password, and confirm password fields plus create-account CTA. On success, routes back to sign in where the user can authenticate with their new credentials.

#### Dashboard
Displays the note list, a prominent recording entry point, and logout action. Each note card shows title, date, and status.

#### Recorder Flow
Appears as a sheet or dedicated screen. Shows permission state, recording state, elapsed time, start/stop actions, and upload progress after stopping.

#### Note Detail
Uses `DefaultTabController` with exactly three tabs:
1. Transcript
2. Summary
3. AI Chat

The transcript tab shows selectable text. The summary tab renders markdown from backend-shaped content. The AI chat tab shows left/right aligned bubbles and an input area fixed at the bottom.

### Routes

- `/`
- `/sign-in`
- `/register`
- `/dashboard`
- `/note-detail`

Named routes are sufficient for this version and keep the navigation model simple.

## 5. State Management with Riverpod

The app uses Riverpod with explicit controller state objects for major flows. The goal is to preserve the PRD’s linear state transitions and avoid overlapping mutations.

### State principles

- one user action should trigger one clear state transition sequence
- while a mutation is in progress, duplicate actions are disabled
- each error state must expose a UI-safe message
- state should not be represented by loose boolean combinations when an explicit state model is clearer

### Core screen states

#### AuthState
- `initial`
- `submitting`
- `authenticated`
- `error`

#### DashboardState
- `initial`
- `loading`
- `loaded`
- `error`

#### RecorderState
- `idle`
- `requestingPermission`
- `recording`
- `stopping`
- `uploading`
- `success`
- `error`

#### NoteDetailState
- `loading`
- `loaded(note, chatHistory)`
- `sendingChat`
- `error`

### Provider layering

#### Core providers
- `tokenStorageProvider`
- `apiClientProvider`
- `recorderServiceProvider`
- `whatsAppBridgeProvider`

#### Repository providers
- `authRepositoryProvider`
- `notesRepositoryProvider`
- `chatRepositoryProvider`

#### Controller providers
- `authControllerProvider`
- `dashboardControllerProvider`
- `recorderControllerProvider`
- `noteDetailControllerProvider`

The UI reads controller providers only. Controllers orchestrate repositories and services.

### Example flows

#### Sign in
```text
UI submit
-> authController.login()
-> authRepository.signIn()
-> tokenStorage.saveAccessToken()
-> state authenticated
-> route to dashboard
```

#### Audio record/upload
```text
UI tap start
-> recorderController.start()
-> recorderService.startRecording()
-> state recording

UI tap stop
-> recorderController.stop()
-> recorderService.stopRecording()
-> notesRepository.createRecordedNote(localPath)
-> state success
```

#### AI chat
```text
UI send message
-> noteDetailController.sendMessage(text)
-> append user message
-> set sendingChat
-> chatRepository.sendMessage(...)
-> append AI response
-> return to loaded
```

## 6. Models and Contracts

The first version uses contracts that already look like the final production integration.

### Models

#### UserModel
- `id`
- `name`
- `email`

#### AuthSessionModel
- `accessToken`
- `user`

#### NoteModel
- `id`
- `title`
- `createdAt`
- `status` (`draft`, `uploading`, `processed`, `error`)
- `transcript`
- `summaryMarkdown`

#### ChatMessageModel
- `id`
- `senderType` (`user`, `ai`)
- `message`
- `createdAt`

### Repository contracts

#### AuthRepository
- `Future<AuthSessionModel> signIn(String email, String password)`
- `Future<AuthSessionModel> register(String name, String email, String password)`
- `Future<void> signOut()`
- `Future<AuthSessionModel?> restoreSession()`

#### NotesRepository
- `Future<List<NoteModel>> fetchNotes()`
- `Future<NoteModel> fetchNoteDetail(String noteId)`
- `Future<NoteModel> createRecordedNote(String localPath)`
- `Future<void> deleteLocalAudio(String path)`

#### ChatRepository
- `Future<List<ChatMessageModel>> fetchHistory(String noteId)`
- `Future<ChatMessageModel> sendMessage(String noteId, String message)`

### Service contracts

#### TokenStorage
- `Future<void> saveAccessToken(String token)`
- `Future<String?> readAccessToken()`
- `Future<void> clear()`

#### RecorderService
- `Future<bool> hasPermission()`
- `Future<void> requestPermission()`
- `Future<String> startRecording()`
- `Future<String> stopRecording()`

#### WhatsAppBridgeService
- `Stream<String> get completedCallAudioPaths`
- `Future<void> initialize()`

## 7. Mock Behavior for the UI-First Build

Mocks should be realistic enough to exercise UI and state transitions.

- sign in and register succeed for seeded inputs
- dashboard loads seeded note cards
- note detail loads seeded transcript, markdown summary, and chat history
- recording stop triggers a short artificial upload delay before success
- chat send appends a delayed mock AI response
- WhatsApp bridge can expose a fake stream event path for local testing

Mocks must live behind repositories or services, not directly in widgets.

## 8. Error Handling and Security Rules

### Error handling
All async operations should produce consistent success/failure outcomes so controllers can map them into UI states without ad hoc parsing.

#### Auth
- disable submit while loading
- show clear inline or top-level error feedback on failure

#### Dashboard
- render empty/error state with retry affordance on failure

#### Recorder
- show permission guidance when denied
- show upload failure feedback if stop/upload fails

#### AI Chat
- keep the user message visible if send fails
- surface retry-friendly feedback for the failed round-trip

### Security behavior
Even in the mock phase, token and auth flow should mimic production:

- token access goes through `TokenStorage`
- API client/interceptor attaches bearer token automatically
- a simulated or real `401` must:
  1. clear session
  2. notify the user briefly
  3. reset navigation to sign in

### Cache safety
After successful audio submission flow, the app must call the local audio cleanup path so the implementation already respects the PRD’s disk safety requirement.

## 9. Android Bridge Scaffolding

The app is Android only, so the native integration path should be prepared now even if the real capture implementation comes later.

### Dart side
- define a `MethodChannel` named `com.dalem.voicenotes/whatsapp`
- create a `WhatsAppBridgeService` wrapper around the channel
- listen for `onWhatsAppCallFinished`
- translate incoming `localAudioPath` values into provider/controller events

### Android side
Create scaffold-level native integration only for this version:
- update `MainActivity.kt` to register the method channel entry point
- add placeholder classes for:
  - `WhatsAppAccessibilityService`
  - `WhatsAppRecordingService`
- wire Android manifest entries needed for scaffolding when appropriate, but do not implement full WhatsApp monitoring/call recording logic yet

This preserves the integration seam without letting native complexity delay the first product slice.

## 10. UI Direction

The UI should be clean professional:
- restrained color palette
- strong readability and spacing
- clear hierarchy in cards, form fields, tabs, and chat bubbles
- prominent primary actions without decorative clutter

The dashboard and note detail screens should feel polished and structured rather than experimental.

## 11. Testing Scope for This Phase

This design expects implementation to include:
- widget tests for major screens or state-driven UI branches where practical
- controller/provider tests for auth, dashboard load, recorder state transitions, and chat send flow
- manual verification of route flow, tab rendering, and mock interactions

The goal is to verify architecture and state behavior even before real backend integration exists.

## 12. Out of Scope for This Version

The following are intentionally deferred:
- real backend authentication integration
- real multipart upload to production backend
- real markdown content from server
- real WhatsApp accessibility monitoring and device audio capture
- advanced offline sync or persistence beyond token storage

These remain easy to add later because the app is designed around stable contracts.

## 13. Recommended Implementation Direction

Implement the app as a complete Android-only Flutter experience with Riverpod and production-shaped mocks. Prioritize stable module boundaries, explicit state transitions, and a polished UI. Keep every real integration behind a repository or service abstraction so the transition from mock to production is incremental rather than architectural.
