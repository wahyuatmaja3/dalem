import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

class ChatRepository {
  final Map<String, List<ChatMessageModel>> _chatHistory = {};

  final List<String> _mockAIResponses = [
    'That is an interesting question. Based on the transcript, I can provide some insights.',
    'Let me help you with that. The key points from the discussion were...',
    'I understand your question. Here is what I found in the notes.',
    'Good question! Looking at the summary, it seems that...',
    'Based on the conversation, I would say that the main takeaway is...',
  ];

  Future<List<ChatMessageModel>> fetchHistory(String noteId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _chatHistory[noteId] ?? [];
  }

  Future<ChatMessageModel> sendMessage(String noteId, String message) async {
    await Future.delayed(const Duration(seconds: 1));

    final aiResponse = _mockAIResponses[
        DateTime.now().millisecondsSinceEpoch % _mockAIResponses.length];

    final aiMessage = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderType: SenderType.ai,
      message: aiResponse,
      createdAt: DateTime.now(),
    );

    if (!_chatHistory.containsKey(noteId)) {
      _chatHistory[noteId] = [];
    }

    _chatHistory[noteId]!.add(
      ChatMessageModel(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_user',
        senderType: SenderType.user,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    _chatHistory[noteId]!.add(aiMessage);

    return aiMessage;
  }
}
