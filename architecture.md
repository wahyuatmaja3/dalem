# LLM-OPTIMIZED FRONTEND PRODUCT REQUIREMENT DOCUMENT (PRD)
## PROJECT CODE: Dalem (Flutter Mobile App)

---

## [METADATA]
* **Target AI Builders:** Claude 3.5 Sonnet, Gemini 2.0 / 5.4, Cursor AI.
* **Context Scope:** Client-Side Cross-Platform Application managing localized states, media streams, background interceptors, and secure storage tokens.
* **Tech Stack Constraints:** Flutter (v3.24+), Dart, BLoC / Riverpod State Management, Http Client, Flutter Secure Storage, Record Package.

---

## 1. APPs COMPONENT & DIRECTORY LAYER

```
lib/
├── core/
│   ├── api/              # Custom HTTP Client Wrapper with BaseURL & Interceptors
│   ├── secure_storage/   # JWT Token CRUD wrappers (flutter_secure_storage)
│   └── constants/        # Route names, UI color styles
└── features/
    ├── auth/             # Login & Registration screens and states
    ├── dashboard/        # Note directories, lists, and creation buttons
    └── note_detail/      # Core Tab View [Transcript | Summary | AI Chat]
```

---

## 2. STATE CONFIGURATION & STATE TRANSITIONS (BLOC / RIVERPOD)
*Instruction for AI:* Every core execution must track precise linear states. Do not allow overlapping mutations.

```dart
// Example state blueprint for AI generation
abstract class NoteDetailState {}
class NoteDetailInitial extends NoteDetailState {}
class NoteDetailLoading extends NoteDetailState {}
class NoteDetailLoaded extends NoteDetailState {
  final NoteModel note;
  final List<ChatModel> chatHistory;
  NoteDetailLoaded({required this.note, required this.chatHistory});
}
class NoteDetailError extends NoteDetailState {
  final String errorMessage;
  NoteDetailError({required this.errorMessage});
}
```

---

## 3. CORE FRONTEND FEATURE MECHANICS

### FEATURE 1: Audio Recorder & Multipart Upload Sync
* **Package:** `record` for capturing mic inputs.
* **Behavior:** * Verify mic permission -> start recording -> output a safe local path (`.m4a`).
    * On user trigger "Stop", change state to `AudioUploading`.
    * Instantiate an `http.MultipartRequest` targeting `BACKEND_URL/api/v1/notes/upload`.
    * Attach Bearer Token from secure storage, stream file payload, and handle response hooks.

### FEATURE 2: WhatsApp Call Native Listener Integration (Android Platform Bridge)
* **Mechanism:** Flutter `MethodChannel` combined with an Android `AccessibilityService`.
* **Dart Side Contract:**
    ```dart
    static const platform = MethodChannel('com.dalem.voicenotes/whatsapp');
    
    void initWhatsAppListener() {
      platform.setMethodCallHandler((call) async {
        if (call.method == "onWhatsAppCallFinished") {
          final String localAudioPath = call.arguments;
          // Trigger UploadBloc event to push file to Custom Backend
          uploadBloc.add(UploadWhatsAppAudio(path: localAudioPath));
        }
      });
    }
    ```
* **Kotlin Side Blueprint (Android Native Component):**
    * Implement `AccessibilityService` to listen for window state change events on target package `com.whatsapp`.
    * Upon detecting an active active voice call interface, spin a Foreground Service with a native `AudioRecord` thread targeting `AudioSource.VOICE_COMMUNICATION`.
    * Upon hang up detection, close the file handler, trigger a local application wakeup via `MethodChannel`, and return the temporary file disk pointer.

### FEATURE 3: UI Layout & Interactivity Contract
* **NoteDetail Wrapper View:** Must use a Flutter `DefaultTabController` splitting screen real estate into exactly 3 ViewPort frames:
    1.  **Transcript Tab:** Selectable text view wrapping string segments cleanly.
    2.  **Summary Tab:** Rendered dynamic view using `flutter_markdown` parsing backend-delivered structures.
    3.  **AI Chat Tab:** Custom `ListView.builder` managing state bubbles (`sender_type == 'user'` aligned right, `'ai'` aligned left), anchored underneath by an active `TextField` input controller.

---

## 4. ERROR HANDLING & SECURITY PROTOCOLS
* **Interceptor Rule:** Every API call must automatically load tokens from `FlutterSecureStorage`. If a response payload encounters HTTP Status `401 Unauthorized`, trigger global notification hooks and pop application routing stack safely back to the Sign-In Entrypage.
* **Cache Safety:** Avoid persistent raw audio storage in the local mobile disk after a verified `201/200` network submission callback to protect device memory constraints.