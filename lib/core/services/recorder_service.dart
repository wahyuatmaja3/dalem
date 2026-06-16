import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recorderServiceProvider = Provider<RecorderService>((ref) {
  return RecorderService();
});

class RecorderService {
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  Timer? _transcriptionTimer;
  final _transcriptionController = StreamController<String>.broadcast();

  Stream<String> get transcriptionStream => _transcriptionController.stream;

  final List<String> _mockSegments = [
    'So, ',
    'the main topic ',
    'we discussed today ',
    'was the Q3 roadmap. ',
    'We have three major initiatives ',
    'that need to be completed ',
    'by the end of September. ',
    'First, ',
    'the mobile app redesign ',
    'needs to be finalized ',
    'and shipped to production. ',
    'Second, ',
    'the API performance optimization ',
    'should reduce latency by 40%. ',
    'Third, ',
    'the analytics dashboard ',
    'needs real-time data integration. ',
    'We also talked about ',
    'hiring two more engineers ',
    'for the backend team. ',
    'The deadline for that ',
    'is end of next month. ',
    'Everyone agreed ',
    'that we need better ',
    'documentation across all services. ',
    'Finally, ',
    'we scheduled a follow-up ',
    'for next Tuesday at 10 AM.',
  ];

  String _fullTranscript = '';

  Future<bool> hasPermission() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  Future<void> requestPermission() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<String> startRecording() async {
    await Future.delayed(const Duration(milliseconds: 300));

    _recordingStartTime = DateTime.now();
    _currentRecordingPath =
        '/mock/recordings/recording_${_recordingStartTime!.millisecondsSinceEpoch}.m4a';
    _fullTranscript = '';

    _startMockTranscription();

    return _currentRecordingPath!;
  }

  void _startMockTranscription() {
    int index = 0;
    _transcriptionTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (timer) {
        if (index >= _mockSegments.length) {
          timer.cancel();
          return;
        }
        _fullTranscript += _mockSegments[index];
        _transcriptionController.add(_fullTranscript);
        index++;
      },
    );
  }

  Future<String> stopRecording() async {
    _transcriptionTimer?.cancel();
    await Future.delayed(const Duration(milliseconds: 500));

    if (_currentRecordingPath == null) {
      throw Exception('No active recording');
    }

    final path = _currentRecordingPath!;
    _currentRecordingPath = null;
    _recordingStartTime = null;

    return path;
  }

  String get liveTranscript => _fullTranscript;

  Duration getElapsedTime() {
    if (_recordingStartTime == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(_recordingStartTime!);
  }

  bool get isRecording => _currentRecordingPath != null;

  void dispose() {
    _transcriptionTimer?.cancel();
    _transcriptionController.close();
  }
}
