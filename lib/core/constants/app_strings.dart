class AppStrings {
  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String notes = 'Notes';
  static const String record = 'Record';
  static const String noNotes = 'No notes yet';
  static const String startRecording = 'Start recording to create your first note';
  
  // Note Detail
  static const String transcript = 'Transcript';
  static const String summary = 'Summary';
  static const String aiChat = 'AI Chat';
  static const String typeMessage = 'Type a message...';
  static const String send = 'Send';
  
  // Recorder
  static const String recording = 'Recording...';
  static const String stopRecording = 'Stop Recording';
  static const String uploading = 'Uploading...';
  static const String permissionRequired = 'Microphone permission required';
  
  // Errors
  static const String errorOccurred = 'An error occurred';
  static const String tryAgain = 'Try Again';

  // Settings
  static const String settings = 'Settings';
  static const String groqApiKey = 'Groq API Key (Gratis / Free)';
  static const String groqApiKeyHint = 'gsk_...';
  static const String groqApiKeyDescription =
      '100% Gratis! Menggunakan Whisper Large v3 Turbo & Llama 3.3 dengan kecepatan sangat tinggi. Buat key gratis di console.groq.com.';
  static const String openAiApiKey = 'OpenAI API Key (Berbayar)';
  static const String openAiApiKeyHint = 'sk-...';
  static const String saveApiKey = 'Save API Key';
  static const String removeApiKey = 'Remove API Key';
  static const String apiKeySaved = 'API Key saved';
  static const String apiKeyRemoved = 'API Key removed';
  static const String apiKeyNotFound = 'No API Key configured yet';
  static const String openAiApiKeyDescription =
      'Used to transcribe your voice notes with OpenAI Whisper & GPT-4o-mini. The key is stored securely on this device.';
  static const String assemblyAiApiKey = 'AssemblyAI API Key';
  static const String assemblyAiApiKeyHint = 'Your AssemblyAI key';
  static const String assemblyAiApiKeyDescription =
      'Enables speaker identification in transcripts (Speaker A/B). Optional — the app falls back to OpenAI Whisper if not set.';
  static const String apiKeysTitle = 'API Keys';
  static const String apiKeysDescription =
      'Configure the AI services used to transcribe and summarize your notes. All keys are stored securely on this device.';
}
