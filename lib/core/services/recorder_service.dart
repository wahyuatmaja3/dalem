import 'package:flutter_riverpod/flutter_riverpod.dart';

final recorderServiceProvider = Provider<RecorderService>((ref) {
  return RecorderService();
});

class RecorderService {
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

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
    _currentRecordingPath = '/mock/recordings/recording_${_recordingStartTime!.millisecondsSinceEpoch}.m4a';
    
    return _currentRecordingPath!;
  }

  Future<String> stopRecording() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_currentRecordingPath == null) {
      throw Exception('No active recording');
    }

    final path = _currentRecordingPath!;
    _currentRecordingPath = null;
    _recordingStartTime = null;
    
    return path;
  }

  Duration getElapsedTime() {
    if (_recordingStartTime == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(_recordingStartTime!);
  }

  bool get isRecording => _currentRecordingPath != null;
}
