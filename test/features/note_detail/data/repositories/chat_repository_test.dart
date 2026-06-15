import 'package:flutter_test/flutter_test.dart';
import 'package:dalem/features/note_detail/data/repositories/chat_repository.dart';
import 'package:dalem/features/note_detail/data/models/chat_message_model.dart';

void main() {
  group('ChatRepository', () {
    late ChatRepository repository;

    setUp(() {
      repository = ChatRepository();
    });

    test('fetchHistory returns list of messages', () async {
      final messages = await repository.fetchHistory('note_1');
      
      expect(messages, isA<List<ChatMessageModel>>());
      expect(messages.isEmpty, true);
    });

    test('sendMessage returns AI response', () async {
      final response = await repository.sendMessage('note_1', 'Hello');
      
      expect(response, isA<ChatMessageModel>());
      expect(response.senderType, SenderType.ai);
      expect(response.message, isNotEmpty);
    });
  });
}
