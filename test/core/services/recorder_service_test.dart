import 'package:flutter_test/flutter_test.dart';
import 'package:dalem/core/services/recorder_service.dart';

void main() {
  group('RecorderService', () {
    late RecorderService service;

    setUp(() {
      service = RecorderService();
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
  });
}
