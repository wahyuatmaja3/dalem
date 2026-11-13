import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:dalem/features/note_detail/data/repositories/chat_repository.dart';
import 'package:dalem/features/note_detail/data/models/chat_message_model.dart';
import '../../../../helpers/fake_offline_services.dart';

void main() {
  group('ChatRepository', () {
    late ChatRepository repository;

    setUp(() {
      repository = ChatRepository(offlineChatService: FakeOfflineChatService());
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

    test('sendMessage stores user and AI message in history', () async {
      await repository.sendMessage('note_1', 'Hello');
      final history = await repository.fetchHistory('note_1');
      expect(history.length, 2);
      expect(history.first.senderType, SenderType.user);
      expect(history.last.senderType, SenderType.ai);
    });

    test('persists history to Hive box when box is provided', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('hive_chat_test');
      Hive.init(tempDir.path);
      final box = await Hive.openBox('test_chat');
      final repoWithBox = ChatRepository(
        offlineChatService: FakeOfflineChatService(),
        chatBox: box,
      );

      await repoWithBox.sendMessage('note_hive', 'Ping');
      expect(box.get('note_hive'), isNotNull);

      final reloadedRepo = ChatRepository(
        offlineChatService: FakeOfflineChatService(),
        chatBox: box,
      );
      final history = await reloadedRepo.fetchHistory('note_hive');
      expect(history.length, 2);
      expect(history.first.message, 'Ping');

      await box.deleteFromDisk();
      await tempDir.delete(recursive: true);
    });
  });
}
