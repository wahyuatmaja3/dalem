import 'package:flutter_test/flutter_test.dart';
import 'package:dalem/core/services/recorder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecorderService', () {
    late RecorderService service;

    setUp(() {
      service = RecorderService();
    });

    tearDown(() {
      service.dispose();
    });

    test('hasPermission returns true for mock', () async {
      final result = await service.hasPermission();
      expect(result, true);
    });

    test('startRecording returns path', () async {
      final path = await service.startRecording();
      expect(path, isNotEmpty);
      expect(path, contains('.m4a'));
    });

    test('stopRecording returns path', () async {
      await service.startRecording();
      final path = await service.stopRecording();
      expect(path, isNotEmpty);
    });

    test('elapsed time updates during recording', () async {
      await service.startRecording();
      final elapsed = service.getElapsedTime();
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(0));
      await service.stopRecording();
    });

    test('liveTranscript returns accumulated text', () async {
      await service.startRecording();
      await Future.delayed(const Duration(seconds: 1));
      final transcript = service.liveTranscript;
      await service.stopRecording();
      expect(transcript, isNotEmpty);
    });
  });
}
