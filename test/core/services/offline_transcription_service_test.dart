import 'package:flutter_test/flutter_test.dart';
import 'package:dalem/core/services/offline_transcription_service.dart';
import '../../helpers/fake_offline_services.dart';

void main() {
  group('OfflineTranscriptionService', () {
    test('WhisperOfflineTranscriptionService throws StateError when file is missing', () async {
      final service = WhisperOfflineTranscriptionService();
      expect(
        () => service.transcribe(filePath: '/non_existent_audio_path.wav'),
        throwsA(isA<StateError>()),
      );
    });

    test('FakeOfflineTranscriptionService returns expected transcription', () async {
      final fake = FakeOfflineTranscriptionService();
      final result = await fake.transcribe(filePath: 'dummy.wav');

      expect(result.text, 'Mock offline transcript');
      expect(result.segments.length, 1);
      expect(result.segments.first.startSeconds, 0);
      expect(result.segments.first.endSeconds, 5);
      expect(result.segments.first.text, 'Mock offline transcript');
    });
  });
}
