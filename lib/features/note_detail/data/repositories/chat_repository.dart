import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../core/services/offline_chat_service.dart';
import '../models/chat_message_model.dart';

final chatBoxProvider = Provider<Box?>((ref) => null);

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    offlineChatService: ref.read(offlineChatServiceProvider),
    chatBox: ref.watch(chatBoxProvider),
  );
});

class ChatRepository {
  final OfflineChatService offlineChatService;
  final Box? _chatBox;

  final Map<String, String> _contexts = {};
  final Map<String, List<ChatMessageModel>> _chatHistory = {};

  ChatRepository({
    required this.offlineChatService,
    Box? chatBox,
  }) : _chatBox = chatBox;

  /// Stores the transcript used as grounding context for [noteId].
  void setContext(String noteId, String transcript) {
    _contexts[noteId] = transcript;
  }

  Future<List<ChatMessageModel>> fetchHistory(String noteId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (_chatHistory[noteId] == null && _chatBox != null) {
      final raw = _chatBox.get(noteId);
      if (raw is List) {
        _chatHistory[noteId] = raw
            .map((e) => ChatMessageModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    }
    return _chatHistory[noteId] ?? [];
  }

  Future<ChatMessageModel> sendMessage(String noteId, String message) async {
    final transcript = _contexts[noteId] ?? '';
    final history = _chatHistory[noteId] ?? [];

    final aiText = await offlineChatService.answerQuestion(
      transcript: transcript,
      question: message,
      history: history,
    );

    final aiMessage = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderType: SenderType.ai,
      message: aiText,
      createdAt: DateTime.now(),
    );

    final userMessage = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_user',
      senderType: SenderType.user,
      message: message,
      createdAt: DateTime.now(),
    );

    final current = _chatHistory.putIfAbsent(noteId, () => []);
    current.addAll([userMessage, aiMessage]);
    if (_chatBox != null) {
      await _chatBox.put(
        noteId,
        current.map((m) => m.toJson()).toList(),
      );
    }

    return aiMessage;
  }
}
