import 'package:dalem/core/services/offline_chat_service.dart';
import 'package:dalem/core/services/offline_summary_service.dart';
import 'package:dalem/core/services/offline_transcription_service.dart';
import 'package:dalem/features/note_detail/data/models/chat_message_model.dart';

class FakeOfflineChatService extends OfflineChatService {
  final Future<String> Function(String transcript, String question)? handler;

  FakeOfflineChatService({this.handler})
      : super(summaryService: OfflineSummaryService());

  @override
  Future<String> answerQuestion({
    required String transcript,
    required String question,
    List<ChatMessageModel> history = const [],
  }) async {
    if (handler != null) return handler!(transcript, question);
    return 'Mock offline AI response';
  }
}

class FakeOfflineTranscriptionService implements OfflineTranscriptionService {
  final OfflineTranscriptionResult? mockResult;

  FakeOfflineTranscriptionService({this.mockResult});

  @override
  Future<bool> isModelDownloaded() async => true;

  @override
  Future<OfflineTranscriptionResult> transcribe({
    required String filePath,
    String language = 'id',
  }) async {
    return mockResult ??
        const OfflineTranscriptionResult(
          text: 'Mock offline transcript',
          segments: [
            OfflineTranscriptionSegment(
              startSeconds: 0,
              endSeconds: 5,
              text: 'Mock offline transcript',
            ),
          ],
        );
  }
}
