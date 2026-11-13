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

### FEATURE 1: Audio Recorder & BYOK AI Transcription Sync
* **Recording:** `record` captures microphone inputs into a local `.m4a` file in the app temporary directory.
* **Transcription Engine (BYOK Architecture):**
    * **Free Tier Option (Recommended):** Groq Cloud (`whisper-large-v3-turbo`) via `https://api.groq.com/openai/v1/audio/transcriptions`. 100% free with a Groq API key from console.groq.com.
    * **OpenAI Option:** OpenAI Whisper (`whisper-1`) via `https://api.openai.com/v1/audio/transcriptions`.
    * **Speaker Diarization Option:** AssemblyAI (`https://api.assemblyai.com/v2`) for Speaker A/B diarization with automatic fallback to Whisper if unconfigured or failed.
* **Summarization & AI Chat Engine:**
    * **Free Tier Option:** Groq `llama-3.3-70b-versatile` via `https://api.groq.com/openai/v1/chat/completions`.
    * **OpenAI Option:** `gpt-4o-mini` via `https://api.openai.com/v1/chat/completions`.
* **Audio Safety Net:** If transcription fails or no API key is yet configured, the audio file is preserved on device and its path stored in `NoteModel.audioPath`. The user can retry transcription anytime from Note Detail once their key is added. Local audio is deleted only after successful transcription.
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

## 4. LOCAL PERSISTENCE & DATA STORAGE
* **Notes Storage:** Hive box `notes` storing `NoteModel` objects (title, timestamp, transcript, segments, summary, audioPath, category).
* **Categories Storage:** Hive box `categories` storing custom categories.
* **Chat History Persistence:** Hive box `chat_history` storing serialized `ChatMessageModel` entries per `noteId`, preserved across app restarts.
* **Key Security:** `FlutterSecureStorage` securely encrypts and stores user API keys (`groq_api_key`, `openai_api_key`, `assemblyai_api_key`).